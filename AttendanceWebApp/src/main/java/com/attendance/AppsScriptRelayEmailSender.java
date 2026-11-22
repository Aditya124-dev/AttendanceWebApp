
package com.attendance;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.regex.Pattern;

public final class AppsScriptRelayEmailSender {

    private static final HttpClient CLIENT =
            HttpClient.newBuilder()
                    .followRedirects(HttpClient.Redirect.NORMAL)
                    .connectTimeout(Duration.ofSeconds(30))
                    .build();

    private AppsScriptRelayEmailSender() {
    }

    public static void sendHtml(
            String recipient,
            String subject,
            String html
    ) throws IOException, InterruptedException {

        if (recipient == null || recipient.isBlank()
                || subject == null || subject.isBlank()
                || html == null || html.isBlank()) {
            throw new IllegalArgumentException(
                    "Recipient, subject and HTML are required."
            );
        }

        String url = requiredEnv("ATTENDANCE_MAIL_RELAY_URL");
        String token = requiredEnv("ATTENDANCE_MAIL_RELAY_TOKEN");

        String json = "{"
                + "\"token\":\"" + escapeJson(token) + "\","
                + "\"to\":\"" + escapeJson(recipient.trim()) + "\","
                + "\"subject\":\"" + escapeJson(subject) + "\","
                + "\"html\":\"" + escapeJson(html) + "\""
                + "}";

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(90))
                .header("Content-Type", "application/json; charset=UTF-8")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        HttpResponse<String> response = CLIENT.send(
                request,
                HttpResponse.BodyHandlers.ofString()
        );

        String responseBody = response.body() == null
                ? ""
                : response.body();

        boolean success = Pattern.compile(
                "\"success\"\\s*:\\s*true"
        ).matcher(responseBody).find();

        if (response.statusCode() != 200 || !success) {
            throw new IOException(
                    "AttendancePro email relay failed. HTTP "
                    + response.statusCode()
                    + ". Response: "
                    + responseBody
            );
        }
    }

    public static void sendText(
            String recipient,
            String subject,
            String text
    ) throws IOException, InterruptedException {

        if (text == null || text.isBlank()) {
            throw new IllegalArgumentException(
                    "Email text is required."
            );
        }

        String html = "<html><body><pre style=\"font-family:Arial;"
                + "white-space:pre-wrap;\">"
                + escapeHtml(text)
                + "</pre></body></html>";

        sendHtml(recipient, subject, html);
    }

    private static String requiredEnv(String name) {
        String value = System.getenv(name);

        if (value == null || value.isBlank()) {
            throw new IllegalStateException(
                    "Missing environment variable: " + name
            );
        }

        return value.trim();
    }

    private static String escapeJson(String value) {
        StringBuilder result = new StringBuilder();

        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);

            switch (c) {
                case '"': result.append("\\\""); break;
                case '\\': result.append("\\\\"); break;
                case '\b': result.append("\\b"); break;
                case '\f': result.append("\\f"); break;
                case '\n': result.append("\\n"); break;
                case '\r': result.append("\\r"); break;
                case '\t': result.append("\\t"); break;
                default:
                    if (c < 0x20) {
                        result.append(String.format("\\u%04x", (int) c));
                    } else {
                        result.append(c);
                    }
            }
        }

        return result.toString();
    }

    private static String escapeHtml(String value) {
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
}
