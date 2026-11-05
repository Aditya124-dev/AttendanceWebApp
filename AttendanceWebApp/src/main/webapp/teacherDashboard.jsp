
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>

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
        response.sendRedirect(request.getContextPath() + "/teacherLogin.jsp");
        return;
    }

    String teacherName = (String) session.getAttribute("teacherName");
    if (teacherName == null || teacherName.trim().isEmpty()) {
        teacherName = "Teacher";
    }

    String alertMessage =
            (String) session.getAttribute("attendanceAlertMessage");

    if (alertMessage != null) {
        session.removeAttribute("attendanceAlertMessage");
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Teacher Dashboard | AttendancePro</title>

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
            gap: 15px;
            flex-wrap: wrap;
        }

        header h1 {
            margin: 0;
            font-size: 23px;
        }

        header a {
            color: white;
            text-decoration: none;
            border: 1px solid rgba(255,255,255,.6);
            padding: 10px 16px;
            border-radius: 8px;
            transition: background .2s;
        }

        header a:hover {
            background: rgba(255,255,255,.12);
        }

        main {
            max-width: 1100px;
            margin: 35px auto;
            padding: 0 20px;
        }

        .welcome,
        .card {
            background: white;
            padding: 25px;
            border-radius: 14px;
            box-shadow: 0 5px 20px rgba(20,40,80,.06);
        }

        .welcome {
            margin-bottom: 25px;
            border-left: 5px solid #4263c7;
        }

        .welcome h2,
        .card h3 {
            color: #17365d;
        }

        .welcome h2 {
            margin-top: 0;
            margin-bottom: 10px;
        }

        .welcome p {
            color: #667085;
            line-height: 1.7;
            margin-bottom: 0;
        }

        .cards {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 20px;
        }

        .card {
            border: 1px solid #e7edf6;
            border-top: 4px solid #4263c7;
            transition: transform .2s, box-shadow .2s;
        }

        .card:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(20,40,80,.09);
        }

        .card h3 {
            margin-top: 0;
            margin-bottom: 10px;
            font-size: 18px;
        }

        .card p {
            color: #667085;
            line-height: 1.7;
            font-size: 14px;
            min-height: 48px;
        }

        .card a,
        .card button {
            display: inline-block;
            margin-top: 10px;
            padding: 11px 15px;
            background: #2457a7;
            color: white;
            border: none;
            border-radius: 8px;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            font-family: inherit;
        }

        .card a:hover,
        .card button:hover {
            background: #173f80;
        }

        .card form {
            margin: 0;
        }

        .student-card {
            border-top-color: #0891b2;
        }

        .student-card a {
            background: #087e9c;
        }

        .student-card a:hover {
            background: #06647d;
        }

        .report-card {
            border-top-color: #168451;
        }

        .report-card a {
            background: #168451;
        }

        .report-card a:hover {
            background: #11663e;
        }

        .lecture-card {
            border-top-color: #8959d7;
        }

        .lecture-card a {
            background: #7044b8;
        }

        .lecture-card a:hover {
            background: #593393;
        }

        .alert-card {
            border-top-color: #d97706;
        }

        .alert-card button {
            background: #b45309;
        }

        .alert-card button:hover {
            background: #92400e;
        }

        .notice {
            background: #ecfdf3;
            border: 1px solid #abefc6;
            color: #067647;
            border-radius: 10px;
            padding: 14px 18px;
            margin-bottom: 20px;
            line-height: 1.6;
        }

        footer {
            text-align: center;
            padding: 25px;
            color: #667085;
            font-size: 12px;
        }

        @media (max-width: 650px) {
            header {
                padding: 18px 5%;
            }

            header h1 {
                font-size: 20px;
            }

            main {
                margin: 22px auto;
                padding: 0 14px;
            }

            .cards {
                grid-template-columns: 1fr;
            }

            .welcome,
            .card {
                padding: 20px;
            }

            .card p {
                min-height: 0;
            }
        }
    </style>
</head>

<body>

<header>
    <h1>AttendancePro | Teacher Portal</h1>

    <a href="<%= request.getContextPath() %>/teacherLogout">
        Logout
    </a>
</header>

<main>

    <section class="welcome">
        <h2>Welcome, <%= escapeHtml(teacherName) %>!</h2>
        <p>
            Manage students, lectures, attendance QR codes
            and attendance reports from one place.
        </p>
    </section>

    <% if (alertMessage != null && !alertMessage.isBlank()) { %>
        <div class="notice">
            <%= escapeHtml(alertMessage) %>
        </div>
    <% } %>

    <section class="cards">

        <article class="card student-card">
            <h3>Student Management</h3>
            <p>
                Register new students by entering their roll number,
                name, course, semester, email and mobile number.
            </p>
            <a href="<%= request.getContextPath() %>/addStudent.jsp">
                Add New Student
            </a>
        </article>
       <article class="card" style="border-top-color:#0d9488;">
    <h3>Mark Student Attendance</h3>

    <p>
        Manually record daily attendance for students.
        Select Present or Absent and save the attendance record.
    </p>

    <a href="<%= request.getContextPath() %>/markAttendance.jsp"
       style="background:#0d9488;">
        Mark Attendance
    </a>
</article>

        <article class="card lecture-card">
            <h3>Lecture Management</h3>
            <p>
                Manage lecture sessions for your assigned classes
                and subjects.
            </p>
            <a href="<%= request.getContextPath() %>/teacherLectures.jsp">
                Open Lectures
            </a>
        </article>

        <article class="card">
            <h3>Generate Attendance QR</h3>
            <p>
                Create a time-limited attendance QR code
                for the current scheduled lecture.
            </p>
            <form action="<%= request.getContextPath() %>/generateQr"
                  method="post">
                <button type="submit">Generate QR</button>
            </form>
        </article>

        <article class="card report-card">
            <h3>Attendance Report</h3>
            <p>
                View saved attendance records, search students,
                filter by date or status and export a CSV report.
            </p>
            <a href="<%= request.getContextPath() %>/viewReport.jsp">
                View Attendance Report
            </a>
        </article>

        <article class="card report-card">
            <h3>Attendance Summary</h3>
            <p>
                Review attendance percentages and summaries
                for students and subjects.
            </p>
            <a href="<%= request.getContextPath() %>/attendanceSummary.jsp">
                View Summary
            </a>
        </article>

        <article class="card alert-card">
            <h3>Low Attendance Email Alerts</h3>
            <p>
                Check subject-wise attendance and process email
                alerts for eligible students below the attendance threshold.
            </p>
            <form action="<%= request.getContextPath() %>/sendAttendanceAlerts"
                  method="post"
                  onsubmit="return confirm('Process low-attendance email alerts now?');">
                <button type="submit">Process Email Alerts</button>
            </form>
        </article>

    </section>

</main>

<footer>
    AttendancePro &copy; 2026 | Student Attendance Management System
</footer>

</body>
</html>
