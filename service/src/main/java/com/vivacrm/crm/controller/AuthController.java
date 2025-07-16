package com.vivacrm.crm.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.http.ResponseCookie;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.*;

import com.vivacrm.crm.user.User;
import com.vivacrm.crm.user.UserRepository;
import com.vivacrm.crm.user.UserService;
import com.vivacrm.crm.user.DeviceTokenService;

import java.time.Duration;
import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UserService userService;
    private final UserRepository userRepository;
    private final DeviceTokenService deviceTokenService;

    public AuthController(AuthenticationManager authenticationManager, UserService userService, UserRepository userRepository, DeviceTokenService deviceTokenService) {
        this.authenticationManager = authenticationManager;
        this.userService = userService;
        this.userRepository = userRepository;
        this.deviceTokenService = deviceTokenService;
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

        try {
            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(username, password));

            User user = userRepository.findByUsername(username).orElseThrow();

            // ✅ Check TOTP if enabled
            if (user.isTotpEnabled()) {
                // ✅ Check existing valid device token
                if (deviceToken != null && deviceTokenService.isValid(user, deviceToken)) {
                    ResponseCookie cookie = ResponseCookie.from("DEVICE_TOKEN", deviceToken)
                            .httpOnly(true)
                            .path("/")
                            .maxAge(Duration.ofDays(30))
                            .build();
                    return ResponseEntity.ok()
                            .header(HttpHeaders.SET_COOKIE, cookie.toString())
                            .body(Map.of("authenticated", true));
                }

                // ✅ Enforce OTP if deviceToken is not valid
                if (otp == null) {
                    return ResponseEntity.status(403).body("OTP required");
                }

                boolean isValid = userService.verifyTotp(user, otp);
                if (!isValid) {
                    return ResponseEntity.status(403).body("Invalid OTP");
                }

                if (rememberDevice) {
                    String newToken = deviceTokenService.createToken(user);
                    ResponseCookie cookie = ResponseCookie.from("DEVICE_TOKEN", newToken)
                            .httpOnly(true)
                            .path("/")
                            .maxAge(Duration.ofDays(30))
                            .build();
                    return ResponseEntity.ok()
                            .header(HttpHeaders.SET_COOKIE, cookie.toString())
                            .body(Map.of("authenticated", true));
                }

                // If OTP passed, but user didn’t choose to remember device
                return ResponseEntity.ok(Map.of("authenticated", true));
            }

            // ✅ User has no TOTP enabled
            return ResponseEntity.ok(Map.of("authenticated", true));

        } catch (AuthenticationException e) {
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
