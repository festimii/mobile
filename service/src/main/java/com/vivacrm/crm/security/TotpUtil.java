package com.vivacrm.crm.security;

import java.nio.ByteBuffer;
import java.security.SecureRandom;
import java.time.Instant;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import com.google.common.io.BaseEncoding;

public final class TotpUtil {
    private static final long TIME_STEP_SECONDS = 30L;
    private static final int OTP_DIGITS = 6;
    private static final String HMAC_ALGORITHM = "HmacSHA1";

    private TotpUtil() {
    }

    /**
     * Generates a 160-bit TOTP secret encoded in Base32 (RFC 3548), suitable for Google Authenticator.
     */
    public static String generateSecret() {
        byte[] buffer = new byte[20]; // 160 bits
        new SecureRandom().nextBytes(buffer);
        return BaseEncoding.base32().omitPadding().encode(buffer); // ✅ Base32 without '=' padding
    }

    /**
     * Verifies a 6-digit TOTP code using the shared Base32 secret.
     *
     * @param base32Secret the TOTP shared secret (Base32 encoded)
     * @param code         the 6-digit user input
     * @return true if the code is valid for the current time window
     */
    public static boolean verifyCode(String base32Secret, String code) {
        try {
            byte[] keyBytes = BaseEncoding.base32().decode(base32Secret);
            SecretKeySpec keySpec = new SecretKeySpec(keyBytes, HMAC_ALGORITHM);
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(keySpec);

            for (int i = -1; i <= 1; i++) { // Accept -30s, current, +30s
                long timeWindow = (Instant.now().getEpochSecond() / TIME_STEP_SECONDS) + i;
                byte[] data = ByteBuffer.allocate(8).putLong(timeWindow).array();
                byte[] hash = mac.doFinal(data);

                int offset = hash[hash.length - 1] & 0xF;
                int binary = ((hash[offset] & 0x7f) << 24)
                        | ((hash[offset + 1] & 0xff) << 16)
                        | ((hash[offset + 2] & 0xff) << 8)
                        | (hash[offset + 3] & 0xff);

                int otp = binary % (int) Math.pow(10, OTP_DIGITS);
                    String generated = String.format("%0" + OTP_DIGITS + "d", otp);

                if (generated.equals(code)) {
                    return true;
                }
            }

            return false;
        } catch (Exception e) {
            return false;
        }
    }

    public static String generateCurrentCode(String base32Secret) {
        try {
            byte[] keyBytes = BaseEncoding.base32().decode(base32Secret);
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
            return String.format("%0" + OTP_DIGITS + "d", otp);
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate TOTP code", e);
        }
    }

}
