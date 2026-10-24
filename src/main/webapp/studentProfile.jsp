<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="com.attendance.DBConnection" %>

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
    response.setHeader("Cache-Control",
            "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session == null
            || session.getAttribute("studentId") == null) {

        response.sendRedirect(
                request.getContextPath() + "/studentLogin.jsp");
        return;
    }

    int studentId =
            (Integer) session.getAttribute("studentId");

    String studentName = "";
    String rollNo = "";
    String course = "";
    int semester = 0;

    int totalDays = 0;
    int presentDays = 0;
    int absentDays = 0;

    double percentage = 0.0;

    List<String[]> history = new ArrayList<>();
    String errorMessage = null;

    try (Connection con = DBConnection.getConnection()) {

        String profileSql =
                "SELECT s.roll_no, s.name, s.course, s.semester, "
                + "COUNT(a.attendance_id) AS total_days, "
                + "COALESCE(SUM(CASE WHEN a.status='Present' "
                + "THEN 1 ELSE 0 END), 0) AS present_days, "
                + "COALESCE(SUM(CASE WHEN a.status='Absent' "
                + "THEN 1 ELSE 0 END), 0) AS absent_days "
                + "FROM students s "
                + "LEFT JOIN attendance a "
                + "ON s.student_id = a.student_id "
                + "WHERE s.student_id = ? "
                + "GROUP BY s.student_id, s.roll_no, "
                + "s.name, s.course, s.semester";

        try (PreparedStatement ps =
                     con.prepareStatement(profileSql)) {

            ps.setInt(1, studentId);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    rollNo = rs.getString("roll_no");
                    studentName = rs.getString("name");
                    course = rs.getString("course");
                    semester = rs.getInt("semester");

                    totalDays = rs.getInt("total_days");
                    presentDays = rs.getInt("present_days");
                    absentDays = rs.getInt("absent_days");
                } else {
                    session.invalidate();

                    response.sendRedirect(
                            request.getContextPath()
                            + "/studentLogin.jsp");
                    return;
                }
            }
        }

        if (totalDays > 0) {
            percentage =
                    presentDays * 100.0 / totalDays;
        }

        String historySql =
                "SELECT attendance_date, status "
                + "FROM attendance "
                + "WHERE student_id = ? "
                + "ORDER BY attendance_date DESC, attendance_id DESC";

        try (PreparedStatement ps =
                     con.prepareStatement(historySql)) {

            ps.setInt(1, studentId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    history.add(new String[] {
                        String.valueOf(
                            rs.getDate("attendance_date")),
                        rs.getString("status")
                    });
                }
            }
        }

    } catch (Exception e) {

        application.log(
                "Unable to load student profile", e);

        errorMessage =
                "Unable to load your profile. Please try again.";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1">

    <title>My Student Profile</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            background: #f3f6fc;
            color: #1d2940;
            font-family: "Segoe UI", Arial, sans-serif;
        }

        header {
            background: #172554;
            color: white;
            padding: 22px 7%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
        }

        header h1 {
            font-size: 21px;
            margin: 0;
        }

        header p {
            color: #cbd5f4;
            font-size: 12px;
            margin: 7px 0 0;
        }

        .logout button {
            background: #ffffff;
            color: #24365b;
            border: 0;
            border-radius: 8px;
            padding: 11px 15px;
            font-weight: bold;
            cursor: pointer;
        }

        main {
            max-width: 1050px;
            margin: 30px auto;
            padding: 0 20px;
        }

        .welcome {
            border-radius: 17px;
            background: linear-gradient(120deg, #4054d9, #7564e9);
            color: white;
            padding: 28px;
            margin-bottom: 23px;
        }

        .welcome p {
            color: #e1e6ff;
            font-size: 13px;
            line-height: 1.6;
        }

        .welcome h2 {
            margin: 8px 0;
            font-size: 27px;
        }

        .profile-card,
        .panel {
            background: white;
            padding: 23px;
            border: 1px solid #e7ecf4;
            border-radius: 14px;
            margin-bottom: 22px;
        }

        .section-title {
            font-size: 17px;
            margin: 0 0 20px;
        }

        .profile-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 20px;
        }

        .field-label {
            font-size: 12px;
            color: #8290a6;
            margin-bottom: 7px;
        }

        .field-value {
            font-size: 15px;
            font-weight: bold;
            overflow-wrap: anywhere;
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 15px;
            margin-bottom: 23px;
        }

        .stat {
            background: white;
            border: 1px solid #e7ecf4;
            border-radius: 13px;
            padding: 20px;
        }

        .stat-label {
            color: #8190a6;
            font-size: 12px;
            line-height: 1.5;
        }

        .stat-number {
            margin-top: 10px;
            font-size: 27px;
            font-weight: bold;
            color: #28385f;
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            min-width: 350px;
            border-collapse: collapse;
        }

        th, td {
            padding: 14px 12px;
            text-align: left;
            border-bottom: 1px solid #edf0f6;
            font-size: 13px;
        }

        th {
            background: #f5f7fc;
            color: #68768e;
            font-size: 11px;
            text-transform: uppercase;
        }

        .badge {
            display: inline-block;
            padding: 6px 10px;
            border-radius: 20px;
            font-weight: bold;
            font-size: 11px;
        }

        .present {
            background: #e3f8ec;
            color: #177b4c;
        }

        .absent {
            background: #ffebeb;
            color: #b63131;
        }

        .error {
            background: #fff0f0;
            color: #a92727;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 9px;
        }

        .empty {
            text-align: center;
            color: #748198;
            padding: 20px;
        }

        footer {
            text-align: center;
            padding: 20px;
            color: #8b97aa;
            font-size: 11px;
        }

        @media (max-width: 700px) {
            .stats {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            .welcome h2 {
                font-size: 23px;
            }
        }

        @media (max-width: 420px) {
            .profile-grid {
                grid-template-columns: 1fr;
            }

            main {
                padding: 0 12px;
            }

            .profile-card, .panel {
                padding: 16px;
            }
        }
    </style>
</head>

<body>

<header>
    <div>
        <h1>Student Portal</h1>
        <p>PERSONAL DASHBOARD</p>
    </div>

    <form class="logout"
          action="<%= request.getContextPath() %>/studentLogout"
          method="post">

        <button type="submit">Log Out</button>
    </form>
</header>

<main>

    <% if (errorMessage != null) { %>

        <div class="error"><%= escapeHtml(errorMessage) %></div>

    <% } else { %>

        <section class="welcome">
            <p>WELCOME TO YOUR STUDENT PORTAL</p>
            <h2>Hello, <%= escapeHtml(studentName) %>!</h2>
            <p>
                View your student details and track your attendance
                records in one place.
            </p>
        </section>

        <section class="profile-card">
            <h3 class="section-title">My Profile</h3>

            <div class="profile-grid">
                <div>
                    <div class="field-label">Student Name</div>
                    <div class="field-value">
                        <%= escapeHtml(studentName) %>
                    </div>
                </div>

                <div>
                    <div class="field-label">Roll Number</div>
                    <div class="field-value">
                        <%= escapeHtml(rollNo) %>
                    </div>
                </div>

                <div>
                    <div class="field-label">Course</div>
                    <div class="field-value">
                        <%= escapeHtml(course) %>
                    </div>
                </div>

                <div>
                    <div class="field-label">Semester</div>
                    <div class="field-value">
                        <%= semester %>
                    </div>
                </div>
            </div>
        </section>

        <h3 class="section-title">My Attendance Overview</h3>

        <section class="stats">

            <div class="stat">
                <div class="stat-label">Total Records</div>
                <div class="stat-number"><%= totalDays %></div>
            </div>

            <div class="stat">
                <div class="stat-label">Present Days</div>
                <div class="stat-number"><%= presentDays %></div>
            </div>

            <div class="stat">
                <div class="stat-label">Absent Days</div>
                <div class="stat-number"><%= absentDays %></div>
            </div>

            <div class="stat">
                <div class="stat-label">Attendance Percentage</div>
                <div class="stat-number">
                    <%= String.format("%.1f%%", percentage) %>
                </div>
            </div>

        </section>

        <section class="panel">
            <h3 class="section-title">My Attendance History</h3>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Attendance Date</th>
                            <th>Status</th>
                        </tr>
                    </thead>

                    <tbody>
                    <%
                        if (history.isEmpty()) {
                    %>
                        <tr>
                            <td colspan="2" class="empty">
                                No attendance records found.
                            </td>
                        </tr>
                    <%
                        } else {
                            for (String[] record : history) {
                                String status = record[1];
                                String cssClass =
                                    "Present".equals(status)
                                    ? "present" : "absent";
                    %>
                        <tr>
                            <td><%= escapeHtml(record[0]) %></td>
                            <td>
                                <span class="badge <%= cssClass %>">
                                    <%= escapeHtml(status) %>
                                </span>
                            </td>
                        </tr>
                    <%
                            }
                        }
                    %>
                    </tbody>
                </table>
            </div>
        </section>

    <% } %>

</main>

<footer>
    Student Attendance Management System
</footer>

</body>
</html>