
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
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

    private String dayName(int day) {
        switch (day) {
            case 1: return "Monday";
            case 2: return "Tuesday";
            case 3: return "Wednesday";
            case 4: return "Thursday";
            case 5: return "Friday";
            case 6: return "Saturday";
            case 7: return "Sunday";
            default: return "Day " + day;
        }
    }
%>

<%
    if (session.getAttribute("teacherId") == null
            || !"TEACHER".equals(session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/teacherLogin.jsp");
        return;
    }

    int teacherId;

    try {
        teacherId = Integer.parseInt(
            String.valueOf(session.getAttribute("teacherId"))
        );
    } catch (Exception ex) {
        response.sendRedirect(request.getContextPath() + "/teacherLogin.jsp");
        return;
    }

    String sql =
        "SELECT ct.timetable_id, ct.day_of_week, " +
        "ct.start_time, ct.end_time, ct.room, " +
        "sub.subject_code, sub.subject_name, ls.lecture_id " +
        "FROM class_timetable ct " +
        "LEFT JOIN subjects sub ON ct.subject_id = sub.subject_id " +
        "LEFT JOIN lecture_sessions ls " +
        "ON ls.timetable_id = ct.timetable_id " +
        "WHERE ct.teacher_id = ? AND ct.is_active = 1 " +
        "ORDER BY ct.day_of_week, ct.start_time";

    boolean databaseError = false;
    boolean hasRows = false;
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Lecture Management | AttendancePro</title>

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
            padding: 22px 6%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 14px;
            flex-wrap: wrap;
        }

        header h1 {
            margin: 0;
            font-size: 23px;
        }

        header a {
            color: white;
            text-decoration: none;
            border: 1px solid rgba(255,255,255,.65);
            padding: 10px 15px;
            border-radius: 8px;
        }

        header a:hover {
            background: rgba(255,255,255,.12);
        }

        main {
            max-width: 1150px;
            margin: 32px auto;
            padding: 0 20px;
        }

        .panel {
            background: white;
            padding: 24px;
            border: 1px solid #e4eaf3;
            border-radius: 13px;
            box-shadow: 0 4px 16px rgba(20,40,80,.05);
            margin-bottom: 22px;
        }

        h2 {
            color: #17365d;
            margin-top: 0;
        }

        p {
            color: #667085;
            line-height: 1.7;
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            min-width: 780px;
            border-collapse: collapse;
        }

        th, td {
            padding: 13px;
            border-bottom: 1px solid #e9edf4;
            text-align: left;
            font-size: 14px;
        }

        th {
            background: #17365d;
            color: white;
            white-space: nowrap;
        }

        tbody tr:hover {
            background: #f7f9fc;
        }

        .badge {
            display: inline-block;
            padding: 5px 9px;
            border-radius: 20px;
            background: #edf2ff;
            color: #2457a7;
            font-size: 12px;
            font-weight: 600;
            white-space: nowrap;
        }

        .message {
            padding: 18px;
            border-radius: 9px;
            line-height: 1.6;
            background: #f8fafc;
            color: #667085;
        }

        .error {
            background: #fff1f0;
            color: #b42318;
        }

        .back {
            display: inline-block;
            background: #2457a7;
            color: white;
            padding: 11px 16px;
            border-radius: 8px;
            text-decoration: none;
        }

        .back:hover {
            background: #17365d;
        }

        footer {
            text-align: center;
            color: #667085;
            padding: 25px;
            font-size: 12px;
        }

        @media (max-width: 600px) {
            header h1 {
                font-size: 19px;
            }

            main {
                padding: 0 12px;
            }

            .panel {
                padding: 17px;
            }
        }
    </style>
</head>

<body>

<header>
    <h1>AttendancePro | Lecture Management</h1>

    <a href="<%= request.getContextPath() %>/teacherDashboard.jsp">
        Back to Dashboard
    </a>
</header>

<main>
    <section class="panel">

        <h2>My Assigned Lectures</h2>

        <p>
            View your active timetable entries, assigned subjects,
            lecture timings, classrooms and existing lecture sessions.
        </p>

        <%
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(sql)) {

                ps.setInt(1, teacherId);

                try (ResultSet rs = ps.executeQuery()) {
        %>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Day</th>
                        <th>Subject Code</th>
                        <th>Subject Name</th>
                        <th>Start Time</th>
                        <th>End Time</th>
                        <th>Room</th>
                        <th>Lecture Session</th>
                    </tr>
                </thead>

                <tbody>
                    <%
                        while (rs.next()) {
                            hasRows = true;

                            int day = rs.getInt("day_of_week");
                            Object lectureId = rs.getObject("lecture_id");
                    %>

                    <tr>
                        <td><%= escapeHtml(dayName(day)) %></td>

                        <td>
                            <%= escapeHtml(rs.getString("subject_code")) %>
                        </td>

                        <td>
                            <%= escapeHtml(rs.getString("subject_name")) %>
                        </td>

                        <td>
                            <%= escapeHtml(rs.getString("start_time")) %>
                        </td>

                        <td>
                            <%= escapeHtml(rs.getString("end_time")) %>
                        </td>

                        <td>
                            <%= escapeHtml(rs.getString("room")) %>
                        </td>

                        <td>
                            <% if (lectureId != null) { %>
                                <span class="badge">
                                    Session #<%= lectureId %>
                                </span>
                            <% } else { %>
                                <span class="badge">Not created</span>
                            <% } %>
                        </td>
                    </tr>

                    <%
                        }

                        if (!hasRows) {
                    %>

                    <tr>
                        <td colspan="7">
                            <div class="message">
                                No active timetable entries were found
                                for this teacher.
                            </div>
                        </td>
                    </tr>

                    <%
                        }
                    %>
                </tbody>
            </table>
        </div>

        <%
                }
            } catch (Exception e) {
                databaseError = true;
                application.log(
                    "Error loading teacher lecture timetable",
                    e
                );
            }

            if (databaseError) {
        %>

            <div class="message error">
                Unable to load the timetable. Please check the database
                connection and server logs.
            </div>

        <%
            }
        %>

    </section>

    <a class="back"
       href="<%= request.getContextPath() %>/teacherDashboard.jsp">
        Back to Teacher Dashboard
    </a>
</main>

<footer>
    AttendancePro &copy; 2026 | Student Attendance Management System
</footer>

</body>
</html>
