 <%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.Date" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="com.attendance.DBConnection" %>

<%
    int totalStudents = 0;
    int totalRecords = 0;
    int presentToday = 0;
    int absentToday = 0;

    int[] weeklyPresent = new int[7];
    int[] weeklyAbsent = new int[7];
    String[] labels = new String[7];

    String errorMessage = null;
    LocalDate today = LocalDate.now();

    try (Connection con = DBConnection.getConnection()) {

        String[] countQueries = {
            "SELECT COUNT(*) FROM students",
            "SELECT COUNT(*) FROM attendance",
            "SELECT COUNT(*) FROM attendance WHERE attendance_date=? AND status='Present'",
            "SELECT COUNT(*) FROM attendance WHERE attendance_date=? AND status='Absent'"
        };

        try (PreparedStatement ps = con.prepareStatement(countQueries[0]);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) totalStudents = rs.getInt(1);
        }

        try (PreparedStatement ps = con.prepareStatement(countQueries[1]);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) totalRecords = rs.getInt(1);
        }

        try (PreparedStatement ps = con.prepareStatement(countQueries[2])) {
            ps.setDate(1, Date.valueOf(today));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) presentToday = rs.getInt(1);
            }
        }

        try (PreparedStatement ps = con.prepareStatement(countQueries[3])) {
            ps.setDate(1, Date.valueOf(today));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) absentToday = rs.getInt(1);
            }
        }

        DateTimeFormatter formatter =
            DateTimeFormatter.ofPattern("dd MMM");

        String dailySql =
            "SELECT " +
            "COALESCE(SUM(CASE WHEN status='Present' THEN 1 ELSE 0 END),0), " +
            "COALESCE(SUM(CASE WHEN status='Absent' THEN 1 ELSE 0 END),0) " +
            "FROM attendance WHERE attendance_date=?";

        for (int i = 0; i < 7; i++) {
            LocalDate day = today.minusDays(6 - i);
            labels[i] = day.format(formatter);

            try (PreparedStatement ps = con.prepareStatement(dailySql)) {
                ps.setDate(1, Date.valueOf(day));

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        weeklyPresent[i] = rs.getInt(1);
                        weeklyAbsent[i] = rs.getInt(2);
                    }
                }
            }
        }

    } catch (Exception e) {
        application.log("Attendance analytics failed", e);
        errorMessage = "Analytics could not load. Please check the database connection.";
    }

    int maxWeeklyTotal = 1;

    for (int i = 0; i < 7; i++) {
        int dailyTotal = weeklyPresent[i] + weeklyAbsent[i];
        if (dailyTotal > maxWeeklyTotal) {
            maxWeeklyTotal = dailyTotal;
        }
    }

    int todayTotal = presentToday + absentToday;

    int presentPercent = todayTotal == 0
        ? 0
        : (int) Math.round(presentToday * 100.0 / todayTotal);

    String donutStyle = todayTotal == 0
        ? "#e8edf5"
        : "conic-gradient(#19a875 0% " + presentPercent
          + "%, #ed7777 " + presentPercent + "% 100%)";
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>AttendancePro | Analytics</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: "Segoe UI", Arial, sans-serif;
            background: #f3f6fc;
            color: #182746;
        }

        header {
            padding: 24px 5%;
            background: #111c35;
            color: white;
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

        header p {
            margin: 6px 0 0;
            font-size: 12px;
            color: #bdc9e2;
        }

        .back {
            padding: 11px 16px;
            background: #4358e4;
            border-radius: 8px;
            color: white;
            text-decoration: none;
            font-size: 13px;
        }

        main {
            max-width: 1200px;
            padding: 0 22px;
            margin: 30px auto;
        }

        .intro {
            margin-bottom: 24px;
        }

        .intro h2 {
            margin: 0 0 7px;
            font-size: 26px;
        }

        .intro p {
            font-size: 13px;
            color: #7b879b;
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }

        .stat {
            padding: 21px;
            background: white;
            border: 1px solid #e6ebf4;
            border-radius: 14px;
            box-shadow: 0 5px 18px rgba(30, 50, 90, .04);
        }

        .stat p {
            margin: 0;
            color: #7b879b;
            font-size: 12px;
        }

        .number {
            margin-top: 13px;
            font-size: 30px;
            font-weight: 750;
        }

        .charts {
            display: grid;
            grid-template-columns: 1.6fr 1fr;
            gap: 20px;
        }

        .chart-card {
            min-width: 0;
            padding: 23px;
            background: white;
            border: 1px solid #e6ebf4;
            border-radius: 14px;
            box-shadow: 0 5px 18px rgba(30, 50, 90, .04);
        }

        .chart-card h3 {
            margin: 0 0 7px;
            font-size: 16px;
        }

        .chart-card > p {
            margin: 0 0 22px;
            color: #8290a6;
            font-size: 12px;
            line-height: 1.5;
        }

        .bar-chart {
            height: 245px;
            display: flex;
            align-items: stretch;
            gap: 8px;
            padding-top: 6px;
            border-bottom: 1px solid #e5eaf2;
        }

        .bar-group {
            flex: 1;
            min-width: 0;
            display: flex;
            flex-direction: column;
            justify-content: flex-end;
            align-items: center;
        }

        .bar-pair {
            width: 100%;
            height: 215px;
            display: flex;
            align-items: flex-end;
            justify-content: center;
            gap: 4px;
        }

        .bar {
            width: 32%;
            max-width: 23px;
            min-width: 5px;
            border-radius: 5px 5px 0 0;
            transition: opacity .2s;
        }

        .bar:hover {
            opacity: .7;
        }

        .present-bar {
            background: #19a875;
        }

        .absent-bar {
            background: #ed7777;
        }

        .day-label {
            padding: 10px 0;
            color: #8290a6;
            font-size: 10px;
            white-space: nowrap;
        }

        .legend {
            display: flex;
            justify-content: center;
            gap: 18px;
            margin-top: 19px;
            flex-wrap: wrap;
            color: #66738a;
            font-size: 12px;
        }

        .legend-item {
            display: flex;
            gap: 7px;
            align-items: center;
        }

        .legend-dot {
            width: 9px;
            height: 9px;
            border-radius: 3px;
            display: inline-block;
        }

        .donut-area {
            height: 245px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }

        .donut {
            width: 180px;
            height: 180px;
            border-radius: 50%;
            display: grid;
            place-items: center;
        }

        .donut-hole {
            width: 122px;
            height: 122px;
            border-radius: 50%;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            background: white;
        }

        .donut-hole strong {
            font-size: 27px;
            color: #172554;
        }

        .donut-hole span {
            margin-top: 5px;
            font-size: 11px;
            color: #8290a6;
        }

        .today-details {
            margin-top: 20px;
            display: flex;
            gap: 16px;
            justify-content: center;
            flex-wrap: wrap;
            font-size: 12px;
            color: #66738a;
        }

        .today-details strong {
            color: #243451;
        }

        .error {
            padding: 15px;
            border-radius: 9px;
            background: #fff0f0;
            color: #a92727;
        }

        footer {
            padding: 25px;
            text-align: center;
            font-size: 11px;
            color: #8290a6;
        }

        @media (max-width: 850px) {
            .stats {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            .charts {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 480px) {
            main {
                padding: 0 13px;
            }

            .stats {
                gap: 10px;
            }

            .stat {
                padding: 15px;
            }

            .number {
                font-size: 25px;
            }

            .chart-card {
                padding: 15px;
            }

            .bar-chart {
                gap: 3px;
            }

            .bar-pair {
                gap: 2px;
            }
        }
    </style>
</head>

<body>

<header>
    <div>
        <h1>AttendancePro</h1>
        <p>STUDENT ATTENDANCE ANALYTICS</p>
    </div>

    <a class="back" href="index.jsp">Back to Dashboard</a>
</header>

<main>

    <section class="intro">
        <h2>Analytics Overview</h2>
        <p>Visual insights based on your saved attendance records.</p>
    </section>

    <% if (errorMessage != null) { %>

        <div class="error"><%= errorMessage %></div>

    <% } else { %>

    <section class="stats">

        <div class="stat">
            <p>Total Students</p>
            <div class="number"><%= totalStudents %></div>
        </div>

        <div class="stat">
            <p>All Attendance Records</p>
            <div class="number"><%= totalRecords %></div>
        </div>

        <div class="stat">
            <p>Present Today</p>
            <div class="number"><%= presentToday %></div>
        </div>

        <div class="stat">
            <p>Absent Today</p>
            <div class="number"><%= absentToday %></div>
        </div>

    </section>

    <section class="charts">

        <div class="chart-card">
            <h3>Weekly Attendance Trend</h3>
            <p>Present and absent records for the last seven days.</p>

            <div class="bar-chart">

                <% for (int i = 0; i < 7; i++) {
                    int pHeight = weeklyPresent[i] == 0
                        ? 0
                        : Math.max(5, (int)Math.round(
                            weeklyPresent[i] * 215.0 / maxWeeklyTotal));

                    int aHeight = weeklyAbsent[i] == 0
                        ? 0
                        : Math.max(5, (int)Math.round(
                            weeklyAbsent[i] * 215.0 / maxWeeklyTotal));
                %>

                <div class="bar-group">

                    <div class="bar-pair">
                        <div class="bar present-bar"
                             style="height:<%= pHeight %>px"
                             title="Present: <%= weeklyPresent[i] %>"></div>

                        <div class="bar absent-bar"
                             style="height:<%= aHeight %>px"
                             title="Absent: <%= weeklyAbsent[i] %>"></div>
                    </div>

                    <div class="day-label"><%= labels[i] %></div>

                </div>

                <% } %>

            </div>

            <div class="legend">
                <div class="legend-item">
                    <span class="legend-dot" style="background:#19a875"></span>
                    Present
                </div>

                <div class="legend-item">
                    <span class="legend-dot" style="background:#ed7777"></span>
                    Absent
                </div>
            </div>
        </div>

        <div class="chart-card">
            <h3>Today's Attendance</h3>
            <p>Distribution of today's marked attendance records.</p>

            <div class="donut-area">

                <div class="donut" style="background:<%= donutStyle %>;">
                    <div class="donut-hole">
                        <strong><%= todayTotal %></strong>
                        <span>Total records</span>
                    </div>
                </div>

                <div class="today-details">
                    <span>
                        Present:
                        <strong><%= presentToday %></strong>
                    </span>

                    <span>
                        Absent:
                        <strong><%= absentToday %></strong>
                    </span>
                </div>

                <% if (todayTotal == 0) { %>
                    <p style="text-align:center;color:#8290a6;font-size:12px;margin-top:18px;">
                        No attendance marked today.
                    </p>
                <% } %>

            </div>
        </div>

    </section>

    <% } %>

</main>

<footer>
    Student Attendance Management System | Analytics Dashboard
</footer>

</body>
</html>