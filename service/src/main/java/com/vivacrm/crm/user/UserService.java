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

    public User register(String username, String password) {
        User user = new User();
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(password));
        user.setTotpSecret(TotpUtil.generateSecret());
        user.setTotpEnabled(true);
        return userRepository.save(user);
    }

    public boolean verifyTotp(User user, String code) {
        return TotpUtil.verifyCode(user.getTotpSecret(), code);
    }
}
