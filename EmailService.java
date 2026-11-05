package com.attendance;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;

public class EmailService {

    private static final String API_URL =
            "https://api.resend.com/emails";

    private static final HttpClient HTTP_CLIENT =
            HttpClient.newHttpClient();

    private static String getRequiredEnv(String name) {
        String value = System.getenv(name);

        if (value == null || value.isBlank()) {
            throw new IllegalStateException(
                    "Required environment variable is missing: " + name
            );
        }

        return value;
    }

    private static String escapeJson(String value) {
        if (value == null) {
            return "";
        }

        StringBuilder result = new StringBuilder();

        for (char c : value.toCharArray()) {
            switch (c) {
                case '"':
                    result.append("\\\"");
                    break;

                case '\\':
                    result.append("\\\\");
                    break;

                case '\n':
                    result.append("\\n");
                    break;

                case '\r':
                    result.append("\\r");
                    break;

                case '\t':
                    result.append("\\t");
                    break;

                default:
                    if (c < 0x20) {
                        result.append(
                                String.format("\\u%04x", (int) c)
                        );
                    } else {
                        result.append(c);
                    }
            }
        }

        return result.toString();
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

        String apiKey = getRequiredEnv("RESEND_API_KEY");
        String fromEmail = getRequiredEnv("RESEND_FROM_EMAIL");

        String json = "{"
                + "\"from\":\"" + escapeJson(fromEmail) + "\","
                + "\"to\":[\"" + escapeJson(to) + "\"],"
                + "\"subject\":\"" + escapeJson(subject) + "\","
                + "\"html\":\"" + escapeJson(html) + "\""
                + "}";

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(API_URL))
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(
                        json, StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> response = HTTP_CLIENT.send(
                request,
                HttpResponse.BodyHandlers.ofString(
                        StandardCharsets.UTF_8)
        );

        int status = response.statusCode();

        if (status < 200 || status >= 300) {
            throw new IOException(
                    "Resend email request failed. HTTP status: "
                            + status
            );
        }
    }
}