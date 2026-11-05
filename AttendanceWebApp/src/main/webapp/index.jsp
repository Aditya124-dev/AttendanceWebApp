<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>

<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.Timestamp" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="com.attendance.DBConnection" %>

<%!
    // Escape database values before displaying them in HTML.
    private String escapeHtml(String value) {
        if (value == null) {
            return "";
        }

        return value
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;");
    }
%>

<%
    int totalStudents = 0;
    int totalRecords = 0;
    int presentToday = 0;
    int absentToday = 0;

    int totalAlerts = 0;
    int pendingAlerts = 0;
    int failedAlerts = 0;

    String dbError = null;
    String alertError = null;

    List<String[]> recentAlerts = new ArrayList<>();

    /*
     * Load existing dashboard statistics.
     * These queries do not modify any database records.
     */
    try (Connection con = DBConnection.getConnection()) {

        String[] queries = {
            "SELECT COUNT(*) FROM students",
            "SELECT COUNT(*) FROM attendance",
            "SELECT COUNT(*) FROM attendance "
                + "WHERE status = 'Present' "
                + "AND attendance_date = CURDATE()",
            "SELECT COUNT(*) FROM attendance "
                + "WHERE status = 'Absent' "
                + "AND attendance_date = CURDATE()"
        };

        int[] values = new int[queries.length];

        for (int i = 0; i < queries.length; i++) {

            try (
                PreparedStatement ps =
                    con.prepareStatement(queries[i]);

                ResultSet rs = ps.executeQuery()
            ) {
                if (rs.next()) {
                    values[i] = rs.getInt(1);
                }
            }
        }

        totalStudents = values[0];
        totalRecords = values[1];
        presentToday = values[2];
        absentToday = values[3];

        /*
         * Load alert statistics separately.
         * An alert-query problem should not hide the
         * existing dashboard statistics.
         */
        try (
            PreparedStatement alertCountPs =
                con.prepareStatement(
                    "SELECT COUNT(*), "
                    + "COALESCE(SUM("
                    + "CASE WHEN delivery_status = 'Pending' "
                    + "THEN 1 ELSE 0 END), 0), "
                    + "COALESCE(SUM("
                    + "CASE WHEN delivery_status = 'Failed' "
                    + "THEN 1 ELSE 0 END), 0) "
                    + "FROM attendance_alert_logs"
                );

            ResultSet alertCountRs =
                alertCountPs.executeQuery()
        ) {
            if (alertCountRs.next()) {
                totalAlerts = alertCountRs.getInt(1);
                pendingAlerts = alertCountRs.getInt(2);
                failedAlerts = alertCountRs.getInt(3);
            }
        }

        /*
         * Load the latest 8 alerts.
         */
        String alertSql =
            "SELECT "
            + "s.roll_no, "
            + "s.name AS student_name, "
            + "sub.subject_code, "
            + "a.alert_type, "
            + "a.channel, "
            + "a.attendance_percentage, "
            + "a.delivery_status, "
            + "a.created_at "
            + "FROM attendance_alert_logs a "
            + "LEFT JOIN students s "
            + "ON a.student_id = s.student_id "
            + "LEFT JOIN subjects sub "
            + "ON a.subject_id = sub.subject_id "
            + "ORDER BY a.created_at DESC, a.alert_id DESC "
            + "LIMIT 8";

        try (
            PreparedStatement alertPs =
                con.prepareStatement(alertSql);

            ResultSet alertRs =
                alertPs.executeQuery()
        ) {
            while (alertRs.next()) {

                Timestamp createdAt =
                    alertRs.getTimestamp("created_at");

                recentAlerts.add(new String[] {
                    alertRs.getString("roll_no"),
                    alertRs.getString("student_name"),
                    alertRs.getString("subject_code"),
                    alertRs.getString("alert_type"),
                    alertRs.getString("channel"),
                    alertRs.getString("attendance_percentage"),
                    alertRs.getString("delivery_status"),
                    createdAt == null
                        ? ""
                        : createdAt.toString()
                });
            }
        }

    } catch (Exception e) {

        application.log("Dashboard database error", e);
        dbError = "Database connection unavailable.";

    }
%>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

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

        /* SECTION HEADINGS */

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

        /* STATISTICS */

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

        .red {
            background: #ffe7e7;
            color: #d04444;
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

        /* ALERT SECTION */

        .alert-summary {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 17px;
            margin-bottom: 20px;
        }

        .alert-stat {
            background: white;
            border: 1px solid #e8edf5;
            border-radius: 14px;
            padding: 20px;
        }

        .alert-stat p {
            color: #8290a6;
            font-size: 12px;
        }

        .alert-stat h3 {
            font-size: 29px;
            margin-top: 10px;
        }

        .alert-stat.total h3 {
            color: #4b5ce3;
        }

        .alert-stat.pending h3 {
            color: #d88328;
        }

        .alert-stat.failed h3 {
            color: #d04444;
        }

        .alert-panel {
            background: white;
            border: 1px solid #e8edf5;
            border-radius: 15px;
            overflow: hidden;
        }

        .alert-panel-heading {
            padding: 20px 22px;
            border-bottom: 1px solid #edf0f5;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
        }

        .alert-panel-heading h3 {
            font-size: 15px;
        }

        .alert-panel-heading p {
            margin-top: 5px;
            color: #8290a6;
            font-size: 12px;
        }

        .alert-count {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 32px;
            padding: 7px 10px;
            border-radius: 20px;
            background: #e8edff;
            color: #4b5ce3;
            font-size: 12px;
            font-weight: 700;
        }

        .table-wrap {
            width: 100%;
            overflow-x: auto;
        }

        .alert-table {
            width: 100%;
            border-collapse: collapse;
            min-width: 850px;
        }

        .alert-table th {
            background: #f8faff;
            color: #71809a;
            text-align: left;
            font-size: 11px;
            font-weight: 700;
            padding: 14px 16px;
            white-space: nowrap;
        }

        .alert-table td {
            padding: 15px 16px;
            border-top: 1px solid #edf0f5;
            font-size: 12px;
            color: #33415c;
            vertical-align: middle;
        }

        .alert-table tbody tr:hover {
            background: #fafbff;
        }

        .student-name {
            font-weight: 650;
            color: #1a2742;
        }

        .sub-text {
            display: block;
            margin-top: 4px;
            color: #8290a6;
            font-size: 11px;
        }

        .status-badge {
            display: inline-block;
            padding: 6px 10px;
            border-radius: 20px;
            font-size: 10px;
            font-weight: 700;
            white-space: nowrap;
        }

        .status-pending {
            background: #fff0df;
            color: #b96b17;
        }

        .status-sent {
            background: #e0f8ee;
            color: #13835d;
        }

        .status-failed {
            background: #ffe7e7;
            color: #c23535;
        }

        .empty-alerts {
            text-align: center;
            padding: 36px 18px;
            color: #8290a6;
            font-size: 13px;
            line-height: 1.8;
        }

        .empty-alerts .empty-icon {
            font-size: 32px;
            margin-bottom: 10px;
        }

        .alert-error {
            padding: 16px;
            color: #a52d2d;
            background: #fff0f0;
            font-size: 12px;
            line-height: 1.7;
        }

        /* DATABASE ERROR */

        .error-message {
            margin-top: 20px;
            padding: 14px;
            border-radius: 10px;
            background: #fff0f0;
            color: #a52d2d;
            font-size: 13px;
        }

        /* FOOTER */

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

            .alert-summary {
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

            .section-heading span {
                font-size: 10px;
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

            <a class="nav-link"
               href="<%= request.getContextPath() %>/studentLogin.jsp">
                <span class="nav-icon">&#127891;</span>
                Student Portal
            </a>

            <a class="nav-link"
               href="<%= request.getContextPath() %>/teacherLogin.jsp">
                <span class="nav-icon">&#128100;</span>
                Teacher Login
            </a>

            <a class="nav-link active"
               href="<%= request.getContextPath() %>/index.jsp">
                <span class="nav-icon">&#9632;</span>
                Dashboard
            </a>

            <a class="nav-link"
               href="<%= request.getContextPath() %>/adminQr.jsp">
                <span class="nav-icon">&#9638;</span>
                QR Attendance
            </a>

            <a class="nav-link"
               href="<%= request.getContextPath() %>/attendanceAnalytics.jsp">
                <span class="nav-icon">&#9636;</span>
                Analytics
            </a>

           
            <a class="nav-link" href="#alerts">
                <span class="nav-icon">&#128276;</span>
                Alerts
            </a>

        </nav>

        <div class="sidebar-bottom">
            <span class="online-dot"></span>
            Application Dashboard
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
                Database connection unavailable.
                Please check your database connection.
            </div>

        <% } %>

        <!-- WELCOME BANNER -->

        <section class="welcome">

            <div>
                <div class="welcome-label">
                    Student Attendance System
                </div>

                <h1>
                    Manage your campus,<br>
                    one day at a time.
                </h1>

                <p>
                    Keep student records organized, track daily attendance
                    and review attendance reports through a single dashboard.
                </p>
            </div>

            <div class="welcome-mark">&#10003;</div>

        </section>

        <!-- ATTENDANCE STATISTICS -->

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

                <div class="stat-note">
                    Registered student records
                </div>

            </div>

            <div class="stat-card">

                <div class="stat-top">
                    <div class="stat-title">Attendance Records</div>
                    <div class="stat-icon purple">&#128196;</div>
                </div>

                <div class="stat-number"><%= totalRecords %></div>

                <div class="stat-note">
                    Total saved entries
                </div>

            </div>

            <div class="stat-card">

                <div class="stat-top">
                    <div class="stat-title">Present Today</div>
                    <div class="stat-icon green">&#10003;</div>
                </div>

                <div class="stat-number"><%= presentToday %></div>

                <div class="stat-note">
                    Marked present today
                </div>

            </div>

            <div class="stat-card">

                <div class="stat-top">
                    <div class="stat-title">Absent Today</div>
                    <div class="stat-icon orange">&#10005;</div>
                </div>

                <div class="stat-number"><%= absentToday %></div>

                <div class="stat-note">
                    Marked absent today
                </div>

            </div>

        </section>

        <!-- QUICK ACTIONS -->

        <div class="section-heading">
            <h2>Quick Actions</h2>
            <span>Choose a task to continue</span>
        </div>



        <!-- ALERTS SECTION -->

        <div class="section-heading" id="alerts">
            <h2>Attendance Alerts</h2>
            <span>Recent alert activity</span>
        </div>

        <% if (dbError == null) { %>

            <!-- ALERT STATISTICS -->

            <section class="alert-summary">

                <div class="alert-stat total">
                    <p>Total Alerts</p>
                    <h3><%= totalAlerts %></h3>
                </div>

                <div class="alert-stat pending">
                    <p>Pending Alerts</p>
                    <h3><%= pendingAlerts %></h3>
                </div>

                <div class="alert-stat failed">
                    <p>Failed Alerts</p>
                    <h3><%= failedAlerts %></h3>
                </div>

            </section>

            <!-- RECENT ALERTS TABLE -->

            <section class="alert-panel">

                <div class="alert-panel-heading">

                    <div>
                        <h3>Recent Alerts</h3>
                        <p>
                            Latest 8 records from the alert log
                        </p>
                    </div>

                    <span class="alert-count">
                        <%= recentAlerts.size() %>
                    </span>

                </div>

                <% if (recentAlerts.isEmpty()) { %>

                    <div class="empty-alerts">

                        <div class="empty-icon">
                            &#128276;
                        </div>

                        <strong>No alerts available yet.</strong>

                        <br>

                        Alert records will appear here when they
                        are saved in the database.

                    </div>

                <% } else { %>

                    <div class="table-wrap">

                        <table class="alert-table">

                            <thead>
                                <tr>
                                    <th>STUDENT</th>
                                    <th>SUBJECT</th>
                                    <th>ALERT TYPE</th>
                                    <th>CHANNEL</th>
                                    <th>ATTENDANCE</th>
                                    <th>STATUS</th>
                                    <th>CREATED AT</th>
                                </tr>
                            </thead>

                            <tbody>

                                <% for (String[] alert : recentAlerts) { %>

                                    <tr>

                                        <td>
                                            <span class="student-name">
                                                <%= escapeHtml(alert[1] == null
                                                    ? "Unknown student"
                                                    : alert[1]) %>
                                            </span>

                                            <span class="sub-text">
                                                Roll:
                                                <%= escapeHtml(alert[0] == null
                                                    ? "N/A"
                                                    : alert[0]) %>
                                            </span>
                                        </td>

                                        <td>
                                            <%= escapeHtml(alert[2] == null
                                                ? "N/A"
                                                : alert[2]) %>
                                        </td>

                                        <td>
                                            <%= escapeHtml(alert[3]) %>
                                        </td>

                                        <td>
                                            <%= escapeHtml(alert[4]) %>
                                        </td>

                                        <td>
                                            <%= escapeHtml(alert[5]) %>%
                                        </td>

                                        <td>

                                            <%
                                                String status = alert[6] == null
                                                    ? "Unknown"
                                                    : alert[6];

                                                String statusClass =
                                                    "Pending".equalsIgnoreCase(status)
                                                        ? "status-pending"
                                                        : "Sent".equalsIgnoreCase(status)
                                                            ? "status-sent"
                                                            : "Failed".equalsIgnoreCase(status)
                                                                ? "status-failed"
                                                                : "";
                                            %>

                                            <span class="status-badge <%= statusClass %>">
                                                <%= escapeHtml(status) %>
                                            </span>

                                        </td>

                                        <td>
                                            <%= escapeHtml(alert[7]) %>
                                        </td>

                                    </tr>

                                <% } %>

                            </tbody>

                        </table>

                    </div>

                <% } %>

            </section>

        <% } %>

        <!-- FOOTER -->

        <footer>
            Student Attendance Management System
            &bull; Academic Project
        </footer>

    </main>

</div>

</body>
</html>