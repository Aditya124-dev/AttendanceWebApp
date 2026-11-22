
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.UUID" %>
<%@ page import="com.attendance.AttendanceAlertService" %>

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
    if (session.getAttribute("teacherId") == null
            || !"TEACHER".equals(session.getAttribute("userRole"))) {

        response.sendRedirect(
            request.getContextPath() + "/teacherLogin.jsp"
        );
        return;
    }

    List<AttendanceAlertService.AlertPreview> preview =
        (List<AttendanceAlertService.AlertPreview>)
        request.getAttribute("alertPreview");

    if (preview == null) {
        response.sendRedirect(
            request.getContextPath() + "/attendanceAlertPreview"
        );
        return;
    }

    String message = (String)
        session.getAttribute("attendanceAlertMessage");

    if (message != null) {
        session.removeAttribute("attendanceAlertMessage");
    }

    String csrfToken = (String) session.getAttribute("csrfToken");

    if (csrfToken == null) {
        csrfToken = UUID.randomUUID().toString();
        session.setAttribute("csrfToken", csrfToken);
    }

    int readyCount = 0;
    int cooldownCount = 0;
    int missingEmailCount = 0;

    for (AttendanceAlertService.AlertPreview item : preview) {
        if ("READY".equals(item.getStatus())) {
            readyCount++;
        } else if ("COOLDOWN".equals(item.getStatus())) {
            cooldownCount++;
        } else if ("MISSING_EMAIL".equals(item.getStatus())) {
            missingEmailCount++;
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Attendance Alert Preview | AttendancePro</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: "Segoe UI", Arial, sans-serif;
            background: #f3f6fb;
            color: #1d2939;
        }

        header {
            background: #17365d;
            color: white;
            padding: 20px 6%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
        }

        header h1 {
            margin: 0;
            font-size: 22px;
        }

        header a {
            color: white;
            text-decoration: none;
            border: 1px solid rgba(255,255,255,.6);
            padding: 9px 15px;
            border-radius: 8px;
        }

        main {
            max-width: 1250px;
            margin: 30px auto;
            padding: 0 18px;
        }

        .intro, .panel {
            background: white;
            border-radius: 14px;
            padding: 24px;
            box-shadow: 0 5px 20px rgba(20,40,80,.06);
            margin-bottom: 22px;
        }

        h2, h3 {
            color: #17365d;
        }

        .intro p {
            color: #667085;
            line-height: 1.6;
        }

        .summary {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 15px;
            margin-bottom: 22px;
        }

        .summary-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            border: 1px solid #e7edf6;
        }

        .summary-card span {
            display: block;
            color: #667085;
            font-size: 13px;
            margin-bottom: 8px;
        }

        .summary-card strong {
            font-size: 27px;
            color: #17365d;
        }

        .ready strong { color: #168451; }
        .cooldown strong { color: #b45309; }
        .missing strong { color: #b42318; }

        .notice {
            background: #eff8ff;
            border: 1px solid #b2ddff;
            color: #175cd3;
            border-radius: 9px;
            padding: 14px 16px;
            margin-bottom: 20px;
        }

        .success {
            background: #ecfdf3;
            border-color: #abefc6;
            color: #067647;
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 850px;
        }

        th, td {
            padding: 14px 12px;
            text-align: left;
            border-bottom: 1px solid #eaecf0;
            font-size: 13px;
        }

        th {
            background: #f8fafc;
            color: #475467;
            font-weight: 700;
        }

        .status {
            display: inline-block;
            padding: 6px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
        }

        .status-ready {
            color: #067647;
            background: #dcfae6;
        }

        .status-cooldown {
            color: #b54708;
            background: #fef0c7;
        }

        .status-missing {
            color: #b42318;
            background: #fee4e2;
        }

        .test-form {
            display: flex;
            gap: 7px;
            min-width: 260px;
        }

        .test-form input {
            width: 175px;
            min-width: 0;
            padding: 9px;
            border: 1px solid #d0d5dd;
            border-radius: 7px;
            font-size: 12px;
        }

        button {
            background: #2457a7;
            color: white;
            border: none;
            border-radius: 7px;
            padding: 9px 12px;
            font-weight: 600;
            cursor: pointer;
        }

        button:hover {
            background: #173f80;
        }

        .empty {
            text-align: center;
            padding: 35px;
            color: #667085;
        }

        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #2457a7;
            text-decoration: none;
            font-weight: 600;
        }

        footer {
            text-align: center;
            padding: 25px;
            color: #667085;
            font-size: 12px;
        }

        @media(max-width: 750px) {
            .summary {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            header {
                padding: 18px 5%;
            }
        }

        @media(max-width: 420px) {
            .summary {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body>

<header>
    <h1>AttendancePro | Alert Management</h1>
    <a href="<%= request.getContextPath() %>/teacherDashboard.jsp">
        Back to Dashboard
    </a>
</header>

<main>

    <a class="back-link"
       href="<%= request.getContextPath() %>/teacherDashboard.jsp">
        &larr; Teacher Dashboard
    </a>

    <section class="intro">
        <h2>Low Attendance Alert Preview</h2>

        <p>
            Review students whose overall attendance is below
            the required 75% threshold before processing email alerts.
        </p>

        <p>
            This preview does not send emails or create alert history records.
        </p>
    </section>

    <% if (message != null && !message.isBlank()) { %>
        <div class="notice success">
            <%= escapeHtml(message) %>
        </div>
    <% } %>

    <section class="summary">

        <div class="summary-card">
            <span>Total Low Attendance Students</span>
            <strong><%= preview.size() %></strong>
        </div>

        <div class="summary-card ready">
            <span>Eligible for Bulk Email</span>
            <strong><%= readyCount %></strong>
        </div>

        <div class="summary-card cooldown">
            <span>Cooldown Active</span>
            <strong><%= cooldownCount %></strong>
        </div>

        <div class="summary-card missing">
            <span>Email Missing</span>
            <strong><%= missingEmailCount %></strong>
        </div>

    </section>

    <section class="panel">

        <h3>Student Attendance Details</h3>

        <div class="table-wrap">

            <table>
                <thead>
                    <tr>
                        <th>Student ID</th>
                        <th>Student Name</th>
                        <th>Student Email</th>
                        <th>Total Classes</th>
                        <th>Present</th>
                        <th>Attendance</th>
                        <th>Alert Status</th>
                        <th>Test Email</th>
                    </tr>
                </thead>

                <tbody>

                <% if (preview.isEmpty()) { %>

                    <tr>
                        <td colspan="8" class="empty">
                            No students currently have attendance below 75%.
                        </td>
                    </tr>

                <% } else { %>

                    <% for (AttendanceAlertService.AlertPreview item : preview) { %>

                        <tr>
                            <td><%= item.getStudentId() %></td>

                            <td>
                                <%= escapeHtml(item.getStudentName()) %>
                            </td>

                            <td>
                                <%= escapeHtml(item.getEmail()) %>
                            </td>

                            <td><%= item.getTotalClasses() %></td>

                            <td><%= item.getPresentClasses() %></td>

                            <td>
                                <strong>
                                    <%= item.getPercentage().toPlainString() %>%
                                </strong>
                            </td>

                            <td>
                                <% if ("READY".equals(item.getStatus())) { %>
                                    <span class="status status-ready">
                                        READY
                                    </span>
                                <% } else if ("COOLDOWN".equals(item.getStatus())) { %>
                                    <span class="status status-cooldown">
                                        COOLDOWN
                                    </span>
                                <% } else { %>
                                    <span class="status status-missing">
                                        MISSING EMAIL
                                    </span>
                                <% } %>
                            </td>

                            <td>
                                <form class="test-form"
                                      action="<%= request.getContextPath() %>/sendAttendanceTest"
                                      method="post"
                                      onsubmit="return confirm('Send a test email to the email address entered here?');">

                                    <input type="hidden"
                                           name="studentId"
                                           value="<%= item.getStudentId() %>">

                                    <input type="hidden"
                                           name="csrfToken"
                                           value="<%= escapeHtml(csrfToken) %>">

                                    <input type="email"
                                           name="testEmail"
                                           placeholder="Your test email"
                                           required
                                           maxlength="254">

                                    <button type="submit">
                                        Test
                                    </button>

                                </form>
                            </td>
                        </tr>

                    <% } %>

                <% } %>

                </tbody>
            </table>

        </div>

    </section>

</main>

<footer>
    AttendancePro &copy; 2026 | Student Attendance Management System
</footer>

</body>
</html>
