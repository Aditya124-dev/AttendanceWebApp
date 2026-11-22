
package com.attendance;

import java.io.IOException;

public class EmailService {

    public static void sendEmail(
            String to,
            String subject,
            String html
    ) throws IOException, InterruptedException {

        try {
            GmailApiEmailSender.sendHtml(to, subject, html);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw e;

        } catch (Exception e) {
            throw new IOException(
                    "Gmail API email delivery failed: " + e.getMessage(),
                    e
            );
        }
    }
}
