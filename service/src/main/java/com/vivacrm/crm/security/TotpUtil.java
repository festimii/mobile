package com.vivacrm.crm.security;

import java.nio.ByteBuffer;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public final class TotpUtil {
    private static final long TIME_STEP_SECONDS = 30L;
    private static final int OTP_DIGITS = 6;
    private static final String HMAC_ALGORITHM = "HmacSHA1";

    private TotpUtil() {
    }

    public static String generateSecret() {
        byte[] buffer = new byte[20];
        new SecureRandom().nextBytes(buffer);
        return Base64.getEncoder().encodeToString(buffer);
    }

    public static boolean verifyCode(String secret, String code) {
        try {
            byte[] keyBytes = Base64.getDecoder().decode(secret);
            SecretKeySpec keySpec = new SecretKeySpec(keyBytes, HMAC_ALGORITHM);
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(keySpec);
            long timeWindow = Instant.now().getEpochSecond() / TIME_STEP_SECONDS;
            byte[] data = ByteBuffer.allocate(8).putLong(timeWindow).array();
            byte[] hash = mac.doFinal(data);
            int offset = hash[hash.length - 1] & 0xF;
            int binary = ((hash[offset] & 0x7f) << 24)
                    | ((hash[offset + 1] & 0xff) << 16)
                    | ((hash[offset + 2] & 0xff) << 8)
                    | (hash[offset + 3] & 0xff);
            int otp = binary % (int) Math.pow(10, OTP_DIGITS);
            String generated = String.format("%0" + OTP_DIGITS + "d", otp);
            return generated.equals(code);
        } catch (Exception e) {
            return false;
        }
    }
}
