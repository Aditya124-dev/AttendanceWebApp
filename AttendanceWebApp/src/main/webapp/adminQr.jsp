
<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%@ page import="java.io.ByteArrayOutputStream" %>
<%@ page import="java.util.Base64" %>
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
    String qrError = (String) request.getAttribute("qrError");
    String classPin = (String) request.getAttribute("classPin");
    String subjectName = (String) request.getAttribute("subjectName");
    String subjectCode = (String) request.getAttribute("subjectCode");
    String lectureEndTime =
            (String) request.getAttribute("lectureEndTime");
    String qrExpiryTime =
            (String) request.getAttribute("qrExpiryTime");

    String qrImageData = null;

    if (qrUrl != null && !qrUrl.isBlank()) {
        try {
            BitMatrix matrix = new QRCodeWriter().encode(
                    qrUrl, BarcodeFormat.QR_CODE, 320, 320);

            try (ByteArrayOutputStream output =
                    new ByteArrayOutputStream()) {

                MatrixToImageWriter.writeToStream(
                        matrix, "PNG", output);

                qrImageData = Base64.getEncoder()
                        .encodeToString(output.toByteArray());
            }

        } catch (Exception e) {
            application.log("QR image generation failed", e);
            qrError = "QR image could not be generated.";
        }
    }

    String renderUrl =
            "https://attendancewebapp-5nym.onrender.com/";
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
            padding: 24px 14px;
            font-family: Arial, sans-serif;
            background: #f2f5fc;
            color: #192746;
        }

        .container {
            max-width: 800px;
            margin: auto;
        }

        header, .card {
            padding: 24px;
            border-radius: 14px;
        }

        header {
            background: #111c35;
            color: white;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
        }

        header h1 {
            margin: 0;
            font-size: 22px;
        }

        header p {
            color: #c5d0e9;
            font-size: 12px;
        }

        .card {
            margin-top: 22px;
            background: white;
            border: 1px solid #e4eaf4;
            text-align: center;
        }

        .button {
            display: inline-block;
            padding: 12px 18px;
            margin: 8px 4px;
            border: 0;
            border-radius: 8px;
            background: #4357dc;
            color: white;
            font-size: 14px;
            font-weight: bold;
            text-decoration: none;
            cursor: pointer;
        }

        .qr-frame {
            display: inline-block;
            padding: 12px;
            border: 1px solid #e5eaf3;
            border-radius: 12px;
        }

        .qr-frame img {
            display: block;
            width: 260px;
            max-width: 100%;
            height: auto;
        }

        .pin-box {
            margin: 22px auto;
            padding: 22px;
            max-width: 400px;
            background: #edf2ff;
            border: 1px solid #d6e0ff;
            border-radius: 14px;
        }

        .pin {
            font-size: 38px;
            font-weight: bold;
            letter-spacing: 8px;
            color: #263fc2;
            margin: 15px 0;
        }

        .url-box {
            margin: 18px 0;
            padding: 12px;
            background: #f6f8fc;
            border-radius: 8px;
            overflow-wrap: anywhere;
            font-size: 12px;
            text-align: left;
        }

        .error {
            margin: 15px 0;
            padding: 14px;
            background: #fff0f0;
            color: #a92727;
            border-radius: 8px;
        }

        .note {
            margin: 16px 0;
            padding: 12px;
            background: #fff7e7;
            color: #8b5c12;
            border-radius: 8px;
            font-size: 13px;
        }

        footer {
            padding: 20px;
            text-align: center;
            color: #8995a9;
            font-size: 12px;
        }

        @media print {
            header .button, form, .print-button,
            footer, .test-link {
                display: none;
            }

            body {
                background: white;
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

        <a class="button"
           href="<%= request.getContextPath() %>/index.jsp">
            Back to Dashboard
        </a>
    </header>

    <section class="card">

        <h2>Lecture Attendance</h2>

        <% if (qrError != null) { %>
            <div class="error">
                <%= escapeHtml(qrError) %>
            </div>
        <% } %>

        <div class="url-box test-link">
            <strong>Live Website Connectivity Test</strong>
            <p>
                <a href="<%= renderUrl %>"
                   target="_blank"
                   rel="noopener noreferrer">
                    Open AttendancePro on Render
                </a>
            </p>
            <small>
                Is link ko mobile par open karke live website
                connectivity check kar sakte ho.
            </small>
        </div>

        <% if (qrImageData != null) { %>

            <h3>
                <%= escapeHtml(subjectCode) %> —
                <%= escapeHtml(subjectName) %>
            </h3>

            <div class="qr-frame">
                <img
                    src="data:image/png;base64,<%= qrImageData %>"
                    alt="Attendance QR Code">
            </div>

            <div class="pin-box">

                <p>Share this PIN with students in the classroom.</p>

                <div class="pin">
                    <%= escapeHtml(classPin) %>
                </div>

                <p>
                    <strong>PIN expires at:</strong>
                    <%= escapeHtml(lectureEndTime) %>
                </p>

                <p>
                    QR expires at:
                    <%= escapeHtml(qrExpiryTime) %>
                </p>

                <button class="button print-button"
                        type="button"
                        onclick="window.print()">
                    Print QR &amp; PIN
                </button>

            </div>

            <div class="url-box">
                <strong>QR Destination URL</strong>
                <p><%= escapeHtml(qrUrl) %></p>
            </div>

        <% } else { %>

            <p>
                Generate the QR during your scheduled lecture.
                The lecture PIN will appear after successful generation.
            </p>

        <% } %>

        <form
            action="<%= request.getContextPath() %>/generateQr"
            method="post">

            <button class="button" type="submit">
                Generate Lecture QR &amp; PIN
            </button>

        </form>

        <p class="note">
            QR generation is available only during a scheduled lecture
            assigned to the logged-in teacher.
        </p>

    </section>

    <footer>
        Student Attendance Management System | QR Attendance
    </footer>

</div>

</body>
</html>
