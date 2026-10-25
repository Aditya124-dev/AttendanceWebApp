<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="com.attendance.DBConnection" %>

<%
    int totalStudents = 0;
    int totalRecords = 0;
    int presentToday = 0;
    int absentToday = 0;
    String dbError = null;

    try (Connection con = DBConnection.getConnection()) {

        String[] queries = {
            "SELECT COUNT(*) FROM students",
            "SELECT COUNT(*) FROM attendance",
            "SELECT COUNT(*) FROM attendance WHERE status='Present' AND attendance_date=CURDATE()",
            "SELECT COUNT(*) FROM attendance WHERE status='Absent' AND attendance_date=CURDATE()"
        };

        int[] values = new int[queries.length];

        for (int i = 0; i < queries.length; i++) {
            try (PreparedStatement ps = con.prepareStatement(queries[i]);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    values[i] = rs.getInt(1);
                }
            }
        }

        totalStudents = values[0];
        totalRecords = values[1];
        presentToday = values[2];
        absentToday = values[3];

    } catch (Exception e) {
        dbError = "Database connection unavailable.";
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>AttendancePro | Dashboard</title>

    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: "Segoe UI", Arial, sans-serif;
            background: #f4f7fb;
            color: #17233d;
        }

        a {
            text-decoration: none;
        }

        .layout {
            display: flex;
            min-height: 100vh;
        }

        /* SIDEBAR */
        .sidebar {
            width: 245px;
            background: #111c35;
            color: white;
            padding: 30px 18px;
            flex-shrink: 0;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 0 10px 32px;
            border-bottom: 1px solid #2a3650;
        }

        .brand-icon {
            width: 44px;
            height: 44px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 13px;
            background: #5268f5;
            font-size: 23px;
            font-weight: bold;
        }

        .brand h2 {
            font-size: 19px;
            letter-spacing: .2px;
        }

        .brand p {
            font-size: 11px;
            margin-top: 4px;
            color: #a8b5d0;
        }

        .menu-label {
            margin: 30px 12px 12px;
            color: #8d9ab6;
            font-size: 10px;
            font-weight: bold;
            letter-spacing: 1.5px;
        }

        .nav-link {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 14px 13px;
            margin: 6px 0;
            border-radius: 9px;
            color: #cad3e6;
            font-size: 13px;
            transition: .2s;
        }

        .nav-link:hover,
        .nav-link.active {
            background: #29385e;
            color: white;
        }

        .nav-link.active {
            border-left: 3px solid #8191ff;
        }

        .nav-icon {
            width: 23px;
            text-align: center;
            font-size: 17px;
        }

        .sidebar-bottom {
            margin-top: 55px;
            padding: 17px 12px;
            border: 1px solid #34415e;
            border-radius: 12px;
            color: #cbd5e1;
            font-size: 12px;
            line-height: 1.7;
        }

        .online-dot {
            display: inline-block;
            width: 8px;
            height: 8px;
            margin-right: 6px;
            border-radius: 50%;
            background: #37d6a0;
        }

        /* MAIN CONTENT */
        .main {
            flex: 1;
            min-width: 0;
            padding: 28px 36px;
        }

        .topbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 15px;
            padding-bottom: 24px;
            border-bottom: 1px solid #e5eaf2;
        }

        .topbar h2 {
            font-size: 23px;
            font-weight: 700;
        }

        .topbar p {
            color: #8290a6;
            margin-top: 5px;
            font-size: 13px;
        }

        .admin-chip {
            background: white;
            border: 1px solid #e4e9f2;
            padding: 10px 15px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 12px;
            font-weight: 600;
        }

        .avatar {
            width: 34px;
            height: 34px;
            border-radius: 50%;
            background: #e5eaff;
            color: #4659df;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 15px;
        }

        /* WELCOME BANNER */
        .welcome {
            margin-top: 27px;
            padding: 32px 34px;
            border-radius: 18px;
            background: linear-gradient(120deg, #4054d9, #7168ec);
            color: white;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            box-shadow: 0 12px 30px rgba(73, 86, 210, .18);
        }

        .welcome-label {
            color: #dfe3ff;
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 1.2px;
            text-transform: uppercase;
        }

        .welcome h1 {
            font-size: 28px;
            margin: 12px 0 10px;
            line-height: 1.3;
        }

        .welcome p {
            color: #e2e7ff;
            font-size: 13px;
            line-height: 1.7;
            max-width: 480px;
        }

        .welcome-mark {
            font-size: 74px;
            opacity: .88;
            padding: 0 18px;
        }

        /* STATS */
        .section-heading {
            margin: 33px 0 17px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
        }

        .section-heading h2 {
            font-size: 18px;
        }

        .section-heading span {
            font-size: 12px;
            color: #8a97ad;
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 17px;
        }

        .stat-card {
            background: #ffffff;
            border: 1px solid #e9edf5;
            border-radius: 15px;
            padding: 21px 19px;
            box-shadow: 0 4px 14px rgba(27, 44, 78, .025);
            transition: transform .2s, box-shadow .2s;
        }

        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 24px rgba(27, 44, 78, .08);
        }

        .stat-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 7px;
        }

        .stat-title {
            color: #8190a6;
            font-size: 12px;
            line-height: 1.5;
        }

        .stat-icon {
            width: 42px;
            height: 42px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            flex-shrink: 0;
        }

        .blue {
            background: #e8edff;
            color: #4b5ce3;
        }

        .purple {
            background: #f0eaff;
            color: #8959d7;
        }

        .green {
            background: #e0f8ee;
            color: #15966a;
        }

        .orange {
            background: #fff0df;
            color: #d88328;
        }

        .stat-number {
            font-size: 32px;
            font-weight: 750;
            letter-spacing: -.8px;
            margin-top: 20px;
            color: #1a2742;
        }

        .stat-note {
            font-size: 11px;
            color: #98a3b5;
            margin-top: 7px;
        }

        /* QUICK ACTIONS */
        .actions {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 18px;
            margin-top: 20px;
        }

        .action-card {
            display: flex;
            align-items: flex-start;
            gap: 16px;
            padding: 23px;
            background: white;
            border: 1px solid #e8edf5;
            border-radius: 15px;
            transition: .2s;
        }

        .action-card:hover {
            border-color: #cbd3ff;
            box-shadow: 0 9px 25px rgba(30, 50, 100, .06);
            transform: translateY(-2px);
        }

        .action-icon {
            width: 49px;
            height: 49px;
            flex-shrink: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            border-radius: 14px;
            font-size: 23px;
        }

        .action-content {
            flex: 1;
            min-width: 0;
        }

        .action-content h3 {
            font-size: 15px;
            margin: 3px 0 8px;
        }

        .action-content p {
            color: #8290a6;
            font-size: 12px;
            line-height: 1.7;
            margin-bottom: 15px;
        }

        .action-link {
            color: #4c5edc;
            font-size: 12px;
            font-weight: 700;
        }

        .action-link:hover {
            color: #2738b9;
        }

        .error-message {
            margin-top: 20px;
            padding: 14px;
            border-radius: 10px;
            background: #fff0f0;
            color: #a52d2d;
            font-size: 13px;
        }

        footer {
            margin-top: 35px;
            padding: 20px 0 5px;
            text-align: center;
            border-top: 1px solid #e5eaf2;
            color: #96a1b3;
            font-size: 11px;
        }

        /* RESPONSIVE DESIGN */
        @media (max-width: 1150px) {
            .stats {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            .main {
                padding: 24px;
            }
        }

        @media (max-width: 760px) {
            .layout {
                display: block;
            }

            .sidebar {
                width: 100%;
                padding: 18px;
            }

            .brand {
                padding-bottom: 18px;
            }

            .menu-label,
            .sidebar-bottom {
                display: none;
            }

            .sidebar nav {
                display: flex;
                flex-wrap: wrap;
                gap: 5px;
                margin-top: 15px;
            }

            .nav-link {
                padding: 10px;
                margin: 0;
                font-size: 11px;
            }

            .main {
                padding: 20px 16px;
            }

            .welcome {
                padding: 24px;
            }

            .welcome h1 {
                font-size: 23px;
            }

            .welcome-mark {
                display: none;
            }

            .actions {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 430px) {
            .topbar {
                align-items: flex-start;
            }

            .topbar h2 {
                font-size: 20px;
            }

            .admin-chip {
                padding: 7px;
            }

            .admin-text {
                display: none;
            }

            .stats {
                grid-template-columns: 1fr;
            }

            .stat-card {
                padding: 18px;
            }

            .welcome {
                padding: 21px;
            }

            .welcome h1 {
                font-size: 21px;
            }
        }
    </style>
</head>

<body>

<div class="layout">

<!-- SIDEBAR -->
<aside class="sidebar">

    <div class="brand">
        <div class="brand-icon">A</div>
        <div>
            <h2>AttendancePro</h2>
            <p>STUDENT MANAGEMENT</p>
        </div>
    </div>

    <p class="menu-label">MAIN MENU</p>

    <nav>
        <a class="nav-link" href="<%= request.getContextPath() %>/studentLogin.jsp">
            <span class="nav-icon">&#127891;</span> Student Portal
        </a>

        <a class="nav-link active" href="<%= request.getContextPath() %>/index.jsp">
            <span class="nav-icon">&#9632;</span> Dashboard
        </a>

        <a class="nav-link" href="<%= request.getContextPath() %>/addStudent.jsp">
            <span class="nav-icon">+</span> Add Student
        </a>

        <a class="nav-link" href="<%= request.getContextPath() %>/markAttendance.jsp">
            <span class="nav-icon">&#10003;</span> Mark Attendance
        </a>

        <a class="nav-link" href="<%= request.getContextPath() %>/adminQr.jsp">
            <span class="nav-icon">&#9638;</span> QR Attendance
        </a>

        <a class="nav-link" href="<%= request.getContextPath() %>/attendanceAnalytics.jsp">
            <span class="nav-icon">&#9636;</span> Analytics
        </a>

        <a class="nav-link" href="<%= request.getContextPath() %>/viewReport.jsp">
            <span class="nav-icon">&#9776;</span> Student Report
        </a>

        <a class="nav-link" href="<%= request.getContextPath() %>/attendanceSummary.jsp">
            <span class="nav-icon">&#128202;</span> Attendance Summary
        </a>
    </nav>

    <div class="sidebar-bottom">
        <span class="online-dot"></span> Application Dashboard
        <br>
        Manage student records and attendance from one place.
    </div>

</aside>


   
    <!-- MAIN DASHBOARD -->
    <main class="main">

        <div class="topbar">
            <div>
                <h2>Dashboard Overview</h2>
                <p>Welcome back! Here is your attendance overview.</p>
            </div>

            <div class="admin-chip">
                <div class="avatar">&#9786;</div>
                <span class="admin-text">Administrator</span>
            </div>
        </div>

        <% if (dbError != null) { %>
            <div class="error-message">
                Database connection unavailable. Please check your database connection.
            </div>
        <% } %>

        <!-- WELCOME BANNER -->
        <section class="welcome">
            <div>
                <div class="welcome-label">Student Attendance System</div>
                <h1>Manage your campus,<br>one day at a time.</h1>
                <p>
                    Keep student records organized, track daily attendance
                    and review attendance reports through a single dashboard.
                </p>
            </div>

            <div class="welcome-mark">&#10003;</div>
        </section>

        <!-- STATISTICS -->
        <div class="section-heading">
            <h2>Attendance Statistics</h2>
            <span>Live database totals</span>
        </div>

        <section class="stats">

            <div class="stat-card">
                <div class="stat-top">
                    <div class="stat-title">Total Students</div>
                    <div class="stat-icon blue">&#128101;</div>
                </div>
                <div class="stat-number"><%= totalStudents %></div>
                <div class="stat-note">Registered student records</div>
            </div>

            <div class="stat-card">
                <div class="stat-top">
                    <div class="stat-title">Attendance Records</div>
                    <div class="stat-icon purple">&#128196;</div>
                </div>
                <div class="stat-number"><%= totalRecords %></div>
                <div class="stat-note">Total saved entries</div>
            </div>

            <div class="stat-card">
                <div class="stat-top">
                    <div class="stat-title">Present Today</div>
                    <div class="stat-icon green">&#10003;</div>
                </div>
                <div class="stat-number"><%= presentToday %></div>
                <div class="stat-note">Marked present today</div>
            </div>

            <div class="stat-card">
                <div class="stat-top">
                    <div class="stat-title">Absent Today</div>
                    <div class="stat-icon orange">&#10005;</div>
                </div>
                <div class="stat-number"><%= absentToday %></div>
                <div class="stat-note">Marked absent today</div>
            </div>

        </section>

        <!-- QUICK ACTIONS -->
        <div class="section-heading">
            <h2>Quick Actions</h2>
            <span>Choose a task to continue</span>
        </div>

        <section class="actions">

            <div class="action-card">
                <div class="action-icon blue">+</div>
                <div class="action-content">
                    <h3>Register New Student</h3>
                    <p>Add a student's roll number, name, course and semester to the database.</p>
                    <a class="action-link" href="addStudent.jsp">ADD STUDENT &rarr;</a>
                </div>
            </div>

            <div class="action-card">
                <div class="action-icon green">&#10003;</div>
                <div class="action-content">
                    <h3>Mark Attendance</h3>
                    <p>Record attendance for an existing student by date and status.</p>
                    <a class="action-link" href="markAttendance.jsp">MARK ATTENDANCE &rarr;</a>
                </div>
            </div>

            <div class="action-card">
                <div class="action-icon purple">&#9776;</div>
                <div class="action-content">
                    <h3>View Attendance Report</h3>
                    <p>Review saved attendance entries with student details and dates.</p>
                    <a class="action-link" href="viewReport.jsp">VIEW REPORT &rarr;</a>
                </div>
            </div>

            <div class="action-card">
                <div class="action-icon orange">&#9636;</div>
                <div class="action-content">
                    <h3>Attendance Summary</h3>
                    <p>Check present days, absent days and each student's attendance percentage.</p>
                    <a class="action-link" href="attendanceSummary.jsp">VIEW SUMMARY &rarr;</a>
                </div>
            </div>

        </section>

        <footer>
            Student Attendance Management System &bull; Academic Project
        </footer>

    </main>

</div>

</body>
</html>