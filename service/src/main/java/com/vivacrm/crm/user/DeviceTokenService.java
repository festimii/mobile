package com.vivacrm.crm.user;

import java.time.LocalDateTime;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class DeviceTokenService {
    private final DeviceTokenRepository repo;

    public DeviceTokenService(DeviceTokenRepository repo) {
        this.repo = repo;
    }

    public String createToken(User user) {
        repo.deleteAllByUser(user); // 1 token per user
        String token = UUID.randomUUID().toString();
        DeviceToken dt = new DeviceToken();
        dt.setToken(token);
        dt.setUser(user);
        repo.save(dt);
        return token;
    }

    public boolean isValid(User user, String token) {
        return repo.findByTokenAndUser(token, user)
                .map(dt -> !dt.getCreatedAt().isBefore(LocalDateTime.now().minusDays(30)))
                .orElse(false);
    }
}
