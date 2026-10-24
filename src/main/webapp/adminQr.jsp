<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>
<%@ page import="java.io.ByteArrayOutputStream" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="com.google.zxing.BarcodeFormat" %>
<%@ page import="com.google.zxing.common.BitMatrix" %>
<%@ page import="com.google.zxing.qrcode.QRCodeWriter" %>
<%@ page import="com.google.zxing.client.j2se.MatrixToImageWriter" %>

<%!
    private String escapeHtml(String value) {
        if (value == null) return "";

        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>

<%
    String qrUrl = (String) request.getAttribute("qrUrl");
    String qrImageData = null;
    String qrError = null;

    if (qrUrl != null && !qrUrl.isBlank()) {
        try {
            QRCodeWriter writer = new QRCodeWriter();

            BitMatrix matrix = writer.encode(
                qrUrl,
                BarcodeFormat.QR_CODE,
                320,
                320
            );

            try (ByteArrayOutputStream output =
                     new ByteArrayOutputStream()) {

                MatrixToImageWriter.writeToStream(
                    matrix, "PNG", output
                );

                qrImageData = Base64.getEncoder()
                    .encodeToString(output.toByteArray());
            }

        } catch (Exception e) {
            application.log("QR image generation failed", e);
            qrError = "QR image could not be generated. Check the ZXing dependencies.";
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1">

    <title>QR Attendance | AttendancePro</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 25px 15px;
            font-family: "Segoe UI", Arial, sans-serif;
            background: #f2f5fc;
            color: #192746;
        }

        .container {
            max-width: 850px;
            margin: 0 auto;
        }

        header {
            padding: 22px 25px;
            background: #111c35;
            color: white;
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 15px;
            flex-wrap: wrap;
        }

        header h1 {
            margin: 0;
            font-size: 22px;
        }

        header p {
            color: #c5d0e9;
            font-size: 12px;
            margin: 7px 0 0;
        }

        .back {
            color: white;
            background: #4257dc;
            padding: 11px 15px;
            border-radius: 8px;
            font-size: 12px;
            text-decoration: none;
        }

        .card {
            margin-top: 24px;
            padding: 30px;
            background: white;
            border: 1px solid #e4eaf4;
            border-radius: 17px;
            box-shadow: 0 8px 25px rgba(30, 50, 90, .05);
            text-align: center;
        }

        .icon {
            width: 58px;
            height: 58px;
            margin: 0 auto 17px;
            display: grid;
            place-items: center;
            background: #e9edff;
            color: #4357dc;
            border-radius: 16px;
            font-size: 28px;
        }

        h2 {
            margin: 0 0 10px;
            font-size: 23px;
        }

        .description {
            color: #7b879b;
            font-size: 13px;
            line-height: 1.8;
            max-width: 510px;
            margin: 0 auto 23px;
        }

        .qr-frame {
            display: inline-block;
            padding: 14px;
            margin: 4px auto 18px;
            border: 1px solid #e5eaf3;
            border-radius: 15px;
            background: white;
        }

        .qr-frame img {
            display: block;
            width: 260px;
            max-width: 100%;
            height: auto;
        }

        .expiry {
            margin: 5px 0 20px;
            padding: 12px;
            background: #fff7e7;
            color: #8b5c12;
            border-radius: 9px;
            font-size: 12px;
        }

        .url-box {
            text-align: left;
            padding: 13px;
            margin: 15px 0 20px;
            border-radius: 9px;
            background: #f6f8fc;
            overflow-wrap: anywhere;
        }

        .url-label {
            color: #7b879b;
            font-size: 11px;
            margin-bottom: 7px;
        }

        .url-value {
            font-size: 12px;
            color: #3047c1;
        }

        .button {
            display: inline-block;
            padding: 13px 19px;
            border: 0;
            border-radius: 9px;
            background: #4357dc;
            color: white;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            text-decoration: none;
        }

        .button:hover {
            background: #3043be;
        }

        .secondary {
            background: #eef1f8;
            color: #36435c;
            margin-left: 7px;
        }

        .secondary:hover {
            background: #dfe5f1;
        }

        .error {
            margin: 15px 0;
            padding: 13px;
            background: #fff0f0;
            color: #a92727;
            border-radius: 8px;
            font-size: 12px;
        }

        .note {
            margin-top: 23px;
            color: #8290a6;
            font-size: 11px;
            line-height: 1.8;
        }

        footer {
            padding: 25px 10px;
            text-align: center;
            color: #8995a9;
            font-size: 11px;
        }

        @media (max-width: 480px) {
            .card {
                padding: 22px 15px;
            }

            h2 {
                font-size: 20px;
            }

            .qr-frame img {
                width: 230px;
            }

            .secondary {
                margin: 10px 0 0;
            }
        }
    </style>
</head>

<body>

<div class="container">

    <header>
        <div>
            <h1>AttendancePro</h1>
            <p>QR CODE ATTENDANCE</p>
        </div>

        <a class="back" href="index.jsp">
            Back to Dashboard
        </a>
    </header>

    <section class="card">

        <div class="icon">&#9638;</div>

        <h2>QR Attendance Session</h2>

        <p class="description">
            Generate a temporary QR code for students to scan
            with their mobile phones.
        </p>

        <% if (qrError != null) { %>

            <div class="error">
                <%= escapeHtml(qrError) %>
            </div>

        <% } else if (qrImageData != null) { %>

            <div class="qr-frame">
                <img
                    src="data:image/png;base64,<%= qrImageData %>"
                    alt="Attendance QR Code">
            </div>

            <div class="expiry">
                This QR session is configured to expire after
                <strong>10 minutes</strong>.
            </div>

            <div class="url-box">
                <div class="url-label">QR Destination URL</div>
                <div class="url-value">
                    <%= escapeHtml(qrUrl) %>
                </div>
            </div>

            <button
                type="button"
                class="button secondary"
                onclick="window.print()">
                Print QR
            </button>

        <% } else { %>

            <p class="description">
                Create a new attendance QR session. The QR code
                will become available after generation.
            </p>

        <% } %>

        <form action="<%= request.getContextPath() %>/generateQr"
              method="post"
              style="margin-top: 18px;">

            <button class="button" type="submit">
                Generate New QR Code
            </button>

        </form>

        <div class="note">
            For mobile scanning, the QR URL must use your laptop's
            local network IP address—not localhost—and both devices
            must be able to reach the Tomcat server.
        </div>

    </section>

    <footer>
        Student Attendance Management System | QR Attendance
    </footer>

</div>

</body>
</html>