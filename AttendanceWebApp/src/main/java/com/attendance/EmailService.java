
package com.attendance;

import java.io.IOException;
import java.util.Properties;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

public class EmailService {

    private static String getRequiredEnv(String name) {
        String value = System.getenv(name);

        if (value == null || value.isBlank()) {
            throw new IllegalStateException(
                "Missing environment variable: " + name
            );
        }

        return value.trim();
    }

    public static void sendEmail(
            String to,
            String subject,
            String html
    ) throws IOException, InterruptedException {

        if (to == null || to.isBlank()
                || subject == null || subject.isBlank()
                || html == null || html.isBlank()) {
            throw new IllegalArgumentException(
                "Recipient, subject and email body are required."
            );
        }

        String username = getRequiredEnv("MAIL_USERNAME");
        String appPassword = getRequiredEnv("MAIL_APP_PASSWORD");

        Properties properties = new Properties();

        properties.put("mail.smtp.host", "smtp.gmail.com");
        properties.put("mail.smtp.port", "587");
        properties.put("mail.smtp.auth", "true");
        properties.put("mail.smtp.starttls.enable", "true");
        properties.put("mail.smtp.starttls.required", "true");
        properties.put("mail.smtp.connectiontimeout", "15000");
        properties.put("mail.smtp.timeout", "15000");
        properties.put("mail.smtp.writetimeout", "15000");

        Session session = Session.getInstance(
            properties,
            new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(
                        username,
                        appPassword
                    );
                }
            }
        );

        try {
            MimeMessage message = new MimeMessage(session);

            message.setFrom(new InternetAddress(username));
            message.setRecipients(
                Message.RecipientType.TO,
                InternetAddress.parse(to.trim())
            );

            message.setSubject(subject, "UTF-8");
            message.setContent(html, "text/html; charset=UTF-8");

            Transport.send(message);

        } catch (MessagingException e) {
            throw new IOException(
                "Gmail SMTP email delivery failed: " + e.getMessage(),
                e
            );
        }
    }
}
