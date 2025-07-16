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

import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UserService userService;
    private final UserRepository userRepository;

    public AuthController(AuthenticationManager authenticationManager, UserService userService, UserRepository userRepository) {
        this.authenticationManager = authenticationManager;
        this.userService = userService;
        this.userRepository = userRepository;
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

        try {
            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(username, password));

            User user = userRepository.findByUsername(username).orElseThrow();

            if (user.isTotpEnabled()) {
                if (otp == null) {
                    System.out.printf("OTP missing for user: %s%n", username);
                    return ResponseEntity.status(403).body("OTP required");
                }

                boolean isValid = userService.verifyTotp(user, otp);

                // 🔍 Log TOTP debug info
                System.out.printf("User: %s%n", username);
                System.out.printf("Stored TOTP Secret: %s%n", user.getTotpSecret());
                System.out.printf("Client OTP: %s%n", otp);

                // OPTIONAL: print the expected code (only for debug; remove in production)
                String expectedOtp = userService.generateCurrentTotpCode(user.getTotpSecret());
                System.out.printf("Expected OTP: %s%n", expectedOtp);

                if (!isValid) {
                    return ResponseEntity.status(403).body("Invalid OTP");
                }
            }

            return ResponseEntity.ok("Authenticated");
        } catch (AuthenticationException e) {
            System.out.printf("Authentication failed for user: %s%n", username);
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
}

