package com.vivacrm.crm.user;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.vivacrm.crm.security.TotpUtil;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Registers a new user with username, email, password, and TOTP.
     *
     * @param username the unique username
     * @param email the unique email address
     * @param password the raw password
     * @return the saved User entity
     */
    public User register(String username, String email, String password) {
        User user = new User();
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        // OTP is disabled by default. Users can enable it later via profile
        user.setTotpSecret(null);
        user.setTotpEnabled(false);
        return userRepository.save(user);
    }

    /**
     * Verifies the TOTP code for a user.
     *
     * @param user the user to verify
     * @param code the TOTP code
     * @return true if valid; false otherwise
     */
    public boolean verifyTotp(User user, String code) {
        return TotpUtil.verifyCode(user.getTotpSecret(), code);
    }

    public String generateCurrentTotpCode(String base32Secret) {
        return TotpUtil.generateCurrentCode(base32Secret);
    }

    /** Enable TOTP for the given user and return the generated secret. */
    public String enableTotp(User user) {
        String secret = TotpUtil.generateSecret();
        user.setTotpSecret(secret);
        user.setTotpEnabled(true);
        userRepository.save(user);
        return secret;
    }

    /** Disable TOTP for the given user. */
    public void disableTotp(User user) {
        user.setTotpEnabled(false);
        user.setTotpSecret(null);
        userRepository.save(user);
    }
}

    