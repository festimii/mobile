package com.vivacrm.crm.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.*;

import com.vivacrm.crm.user.User;
import com.vivacrm.crm.user.UserRepository;
import com.vivacrm.crm.user.UserService;
import com.vivacrm.crm.user.DeviceTokenService;

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
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");
        String otp = body.get("otp");
        String deviceToken = body.get("deviceToken");
        boolean rememberDevice = Boolean.parseBoolean(body.getOrDefault("rememberDevice", "false"));

        try {
            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(username, password));

            User user = userRepository.findByUsername(username).orElseThrow();

            if (user.isTotpEnabled()) {
                if (deviceToken != null && deviceTokenService.isValid(user, deviceToken)) {
                    return ResponseEntity.ok(Map.of("authenticated", true));
                }

                if (otp == null) {
                    return ResponseEntity.status(403).body("OTP required");
                }

                boolean isValid = userService.verifyTotp(user, otp);
                if (!isValid) {
                    return ResponseEntity.status(403).body("Invalid OTP");
                }

                if (rememberDevice) {
                    String newToken = deviceTokenService.createToken(user);
                    return ResponseEntity.ok(Map.of(
                            "authenticated", true,
                            "deviceToken", newToken));
                }
            }

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
