
package com.attendance;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Base64;
import java.util.Properties;

import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.gmail.Gmail;
import com.google.api.services.gmail.model.Message;
import com.google.auth.oauth2.UserCredentials;
import com.google.auth.http.HttpCredentialsAdapter;

import jakarta.mail.Session;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

public final class GmailApiEmailSender {

    private static final String APPLICATION_NAME = "AttendancePro";

    private GmailApiEmailSender() {
    }

    private static String getSenderEmail() {

        String email = System.getenv("GMAIL_SENDER_EMAIL");

        if (email == null || email.isBlank()) {
            email = System.getenv("MAIL_USERNAME");
        }

        if (email == null || email.isBlank()) {
            throw new IllegalStateException(
                    "Missing GMAIL_SENDER_EMAIL configuration."
            );
        }

        return email.trim();
    }

    private static InputStream getTokenStream() throws IOException {

        String tokenJson = System.getenv("GMAIL_TOKEN_JSON");

        if (tokenJson != null && !tokenJson.isBlank()) {
            return new ByteArrayInputStream(
                    tokenJson.getBytes(StandardCharsets.UTF_8)
            );
        }

        String tokenPath = System.getenv("GMAIL_TOKEN_PATH");

        if (tokenPath == null || tokenPath.isBlank()) {
            throw new IllegalStateException(
                    "GMAIL_TOKEN_JSON or GMAIL_TOKEN_PATH is required."
            );
        }

        return Files.newInputStream(Path.of(tokenPath.trim()));
    }

    private static Gmail createGmailService() throws Exception {

        UserCredentials credentials;

        try (InputStream input = getTokenStream()) {
            credentials = UserCredentials.fromStream(input);
        }

        return new Gmail.Builder(
                GoogleNetHttpTransport.newTrustedTransport(),
                GsonFactory.getDefaultInstance(),
                new HttpCredentialsAdapter(credentials)
        )
                .setApplicationName(APPLICATION_NAME)
                .build();
    }

    public static void send(
            String recipient,
            String subject,
            String content,
            String contentType
    ) throws Exception {

        if (recipient == null || recipient.isBlank()
                || subject == null || subject.isBlank()
                || content == null || content.isBlank()) {

            throw new IllegalArgumentException(
                    "Recipient, subject and content are required."
            );
        }

        String sender = getSenderEmail();

        Session session = Session.getInstance(new Properties());

        MimeMessage mimeMessage = new MimeMessage(session);

        mimeMessage.setFrom(new InternetAddress(sender));

        mimeMessage.setRecipients(
                jakarta.mail.Message.RecipientType.TO,
                InternetAddress.parse(recipient.trim())
        );

        mimeMessage.setSubject(subject, "UTF-8");

        mimeMessage.setContent(
                content,
                contentType + "; charset=UTF-8"
        );

        mimeMessage.saveChanges();

        java.io.ByteArrayOutputStream output =
                new java.io.ByteArrayOutputStream();

        mimeMessage.writeTo(output);

        String encodedMessage = Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(output.toByteArray());

        Message gmailMessage = new Message();
        gmailMessage.setRaw(encodedMessage);

        createGmailService()
                .users()
                .messages()
                .send("me", gmailMessage)
                .execute();
    }

    public static void sendHtml(
            String recipient,
            String subject,
            String html
    ) throws Exception {

        send(recipient, subject, html, "text/html");
    }

    public static void sendText(
            String recipient,
            String subject,
            String text
    ) throws Exception {

        send(recipient, subject, text, "text/plain");
    }
}
