package com.vivacrm.crm.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vivacrm.crm.security.JwtService;
import com.vivacrm.crm.user.DeviceTokenService;
import com.vivacrm.crm.user.User;
import com.vivacrm.crm.user.UserRepository;
import com.vivacrm.crm.user.UserService;

import java.time.Duration;
import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    private final AuthenticationManager authenticationManager;
    private final UserService userService;
    private final UserRepository userRepository;
    private final DeviceTokenService deviceTokenService;
    private final JwtService jwtService;

    public AuthController(AuthenticationManager authenticationManager, UserService userService, UserRepository userRepository, DeviceTokenService deviceTokenService, JwtService jwtService) {
        this.authenticationManager = authenticationManager;
        this.userService = userService;
        this.userRepository = userRepository;
        this.deviceTokenService = deviceTokenService;
        this.jwtService = jwtService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String email = body.get("email");
        String password = body.get("password");

        if (username == null || email == null || password == null) {
            return ResponseEntity.badRequest().body("Missing required fields");
        }

        User user = userService.register(username, email, password);
        return ResponseEntity.ok(Map.of("totpEnabled", user.isTotpEnabled()));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(
            @RequestBody Map<String, String> body,
            @CookieValue(value = "DEVICE_TOKEN", required = false) String deviceTokenCookie) {

        String username = body.get("username");
        String password = body.get("password");
        String otp = body.get("otp");
        String deviceToken = body.get("deviceToken");

        if (deviceToken == null && deviceTokenCookie != null) {
            deviceToken = deviceTokenCookie;
        }
        boolean rememberDevice = Boolean.parseBoolean(body.getOrDefault("rememberDevice", "false"));

        // Log inputs
        log.info("Login attempt for user {}", username);
        log.debug("Password length: {}", password != null ? password.length() : null);
        log.debug("OTP provided: {}", otp != null);
        log.debug("Body deviceToken: {}, Cookie deviceToken: {}, Effective: {}", body.get("deviceToken"), deviceTokenCookie, deviceToken);
        log.debug("Remember device: {}", rememberDevice);

        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(username, password));

            User user = userRepository.findByUsername(username).orElseThrow();
            String jwtToken = jwtService.generateToken(username);

            if (user.isTotpEnabled()) {
                log.info("TOTP is enabled for user {}", username);

                // ✅ If client sent a deviceToken and it's valid, skip OTP
                if (deviceToken != null && deviceTokenService.isValid(user, deviceToken)) {
                    log.debug("Valid device token provided; skipping OTP verification");

                    ResponseCookie cookie = ResponseCookie.from("DEVICE_TOKEN", deviceToken)
                            .httpOnly(true)
                            .path("/")
                            .maxAge(Duration.ofDays(30))
                            .build();

                    return ResponseEntity.ok()
                            .header(HttpHeaders.SET_COOKIE, cookie.toString())
                            .body(Map.of(
                                    "authenticated", true,
                                    "deviceToken", deviceToken,
                                    "token", jwtToken
                            ));
                }

                // ❌ OTP is required if no valid deviceToken
                if (otp == null) {
                    log.warn("OTP required but not provided for user {}", username);
                    return ResponseEntity.status(403).body("OTP required");
                }

                // ✅ OTP was provided, verify it
                boolean isValid = userService.verifyTotp(user, otp);
                log.debug("OTP verification result: {}", isValid);

                if (!isValid) {
                    return ResponseEntity.status(403).body("Invalid OTP");
                }

                // ✅ OTP valid — generate deviceToken if rememberDevice is true
                if (rememberDevice) {
                    String newToken = deviceTokenService.createToken(user);
                    log.debug("Generated new device token for user {}", username);

                    ResponseCookie cookie = ResponseCookie.from("DEVICE_TOKEN", newToken)
                            .httpOnly(true)
                            .path("/")
                            .maxAge(Duration.ofDays(30))
                            .build();

                    return ResponseEntity.ok()
                            .header(HttpHeaders.SET_COOKIE, cookie.toString())
                            .body(Map.of(
                                    "authenticated", true,
                                    "deviceToken", newToken,
                                    "token", jwtToken
                            ));
                }

                // ✅ OTP accepted but no token stored
                log.debug("OTP accepted but device not remembered");
                return ResponseEntity.ok(Map.of(
                        "authenticated", true,
                        "token", jwtToken
                ));
            }


            log.info("TOTP not enabled; login successful for user {}", username);
            return ResponseEntity.ok(Map.of(
                    "authenticated", true,
                    "token", jwtToken
            ));

        } catch (AuthenticationException e) {
            log.warn("Authentication failed for user {}: {}", username, e.getMessage());
            return ResponseEntity.status(401).build();
        }
    }


    @GetMapping("/totp-status")
    public ResponseEntity<?> totpStatus(@RequestParam String username) {
        return userRepository.findByUsername(username)
                .map(u -> ResponseEntity.ok(Map.of("enabled", u.isTotpEnabled())))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/enable-totp")
    public ResponseEntity<?> enableTotp(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        User user = userRepository.findByUsername(username).orElse(null);
        if (user == null) {
            return ResponseEntity.badRequest().body("User not found");
        }
        String secret = userService.enableTotp(user);
        return ResponseEntity.ok(Map.of("totpSecret", secret));
    }

    @PostMapping("/disable-totp")
    public ResponseEntity<?> disableTotp(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        User user = userRepository.findByUsername(username).orElse(null);
        if (user == null) {
            return ResponseEntity.badRequest().body("User not found");
        }
        userService.disableTotp(user);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/user/{username}")
    public ResponseEntity<?> getUser(@PathVariable String username) {
        User user = userRepository.findByUsername(username).orElse(null);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(Map.of(
                "username", user.getUsername(),
                "totpEnabled", user.isTotpEnabled()
        ));
    }
}
