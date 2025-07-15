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
        user.setTotpSecret(TotpUtil.generateSecret());
        user.setTotpEnabled(true);
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
}

    