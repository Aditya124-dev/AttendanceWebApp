package com.attendance;

import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

public final class PasswordUtil {

    private static final int ITERATIONS = 210000;
    private static final int KEY_LENGTH = 256;

    private PasswordUtil() {
    }

    public static String generateSalt() {
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);
        return Base64.getEncoder().encodeToString(salt);
    }

    public static String hashPassword(
            String password, String salt)
            throws GeneralSecurityException {

        byte[] saltBytes = Base64.getDecoder().decode(salt);

        PBEKeySpec spec = new PBEKeySpec(
                password.toCharArray(),
                saltBytes,
                ITERATIONS,
                KEY_LENGTH
        );

        try {
            byte[] hash = SecretKeyFactory
                    .getInstance("PBKDF2WithHmacSHA256")
                    .generateSecret(spec)
                    .getEncoded();

            return Base64.getEncoder()
                    .encodeToString(hash);

        } finally {
            spec.clearPassword();
        }
    }

    public static boolean verifyPassword(
            String password,
            String salt,
            String storedHash)
            throws GeneralSecurityException {

        String calculatedHash =
                hashPassword(password, salt);

        byte[] actual = Base64.getDecoder()
                .decode(calculatedHash);

        byte[] expected = Base64.getDecoder()
                .decode(storedHash);

        return MessageDigest.isEqual(actual, expected);
    }
}