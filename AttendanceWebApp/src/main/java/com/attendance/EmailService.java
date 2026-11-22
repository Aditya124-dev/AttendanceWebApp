
package com.attendance;

import java.io.IOException;

public class EmailService {

    private EmailService() {
    }

    public static void sendEmail(
            String to,
            String subject,
            String html
    ) throws IOException {

        try {
            AppsScriptRelayEmailSender.sendHtml(
                    to,
                    subject,
                    html
            );

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();

            throw new IOException(
                    "AttendancePro email relay was interrupted.",
                    e
            );

        } catch (IOException e) {
            throw e;

        } catch (Exception e) {
            throw new IOException(
                    "AttendancePro email relay failed.",
                    e
            );
        }
    }
}
