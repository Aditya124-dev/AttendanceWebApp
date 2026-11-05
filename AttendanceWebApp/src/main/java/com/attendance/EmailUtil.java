
package com.attendance;

import java.util.Properties;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

public final class EmailUtil {

    private EmailUtil() {
    }

    public static void sendOtp(String recipientEmail, String otp)
            throws Exception {

        String senderEmail = System.getenv("MAIL_USERNAME");
        String appPassword = System.getenv("MAIL_APP_PASSWORD");

        if (senderEmail == null || senderEmail.isBlank()
                || appPassword == null || appPassword.isBlank()) {

            throw new IllegalStateException(
                    "Email configuration is missing.");
        }

        Properties properties = new Properties();

        properties.put("mail.smtp.host", "smtp.gmail.com");
        properties.put("mail.smtp.port", "587");
        properties.put("mail.smtp.auth", "true");
        properties.put("mail.smtp.starttls.enable", "true");
        properties.put("mail.smtp.starttls.required", "true");

        properties.put("mail.smtp.connectiontimeout", "10000");
        properties.put("mail.smtp.timeout", "10000");
        properties.put("mail.smtp.writetimeout", "10000");

        Session session = Session.getInstance(
                properties,
                new Authenticator() {
                    @Override
                    protected PasswordAuthentication getPasswordAuthentication() {
                        return new PasswordAuthentication(
                                senderEmail, appPassword);
                    }
                }
        );

        Message message = new MimeMessage(session);

        message.setFrom(new InternetAddress(senderEmail));

        message.setRecipients(
                Message.RecipientType.TO,
                InternetAddress.parse(recipientEmail)
        );

        message.setSubject(
                "AttendanceWebApp - Password Reset OTP");

        message.setText(
                "Hello,\n\n"
                + "Your password reset OTP is: " + otp + "\n\n"
                + "This OTP is valid for 5 minutes.\n"
                + "Do not share this OTP with anyone.\n\n"
                + "If you did not request this, ignore this email.\n\n"
                + "Student Attendance Management System"
        );

        Transport.send(message);
    }
}
