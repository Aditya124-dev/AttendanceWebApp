<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.Date" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.YearMonth" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.attendance.DBConnection" %>

<%!
    private String escHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }

    private String csvCell(String value) {
        if (value == null) value = "";

        if (value.matches("^[=+@-].*")) {
            value = "'" + value;
        }

        return "\"" + value.replace("\"", "\"\"") + "\"";
    }
%>

<%
    int totalStudents = 0;
    int totalRecords = 0;
    int presentToday = 0;
    int absentToday = 0;

    int rangePresent = 0;
    int rangeAbsent = 0;
    int rangeRecords = 0;

    int[] weeklyPresent = new int[7];
    int[] weeklyAbsent = new int[7];
    String[] weeklyLabels = new String[7];

    int[] monthlyPresent = new int[6];
    int[] monthlyAbsent = new int[6];
    String[] monthlyLabels = new String[6];

    ArrayList<String> subjectCodes = new ArrayList<String>();
    ArrayList<String> subjectNames = new ArrayList<String>();
    ArrayList<Integer> subjectLectures = new ArrayList<Integer>();
    ArrayList<Integer> subjectPresent = new ArrayList<Integer>();
    ArrayList<Integer> subjectAbsent = new ArrayList<Integer>();
    ArrayList<Integer> subjectPercentages = new ArrayList<Integer>();

    String errorMessage = null;

    LocalDate today = LocalDate.now();
    LocalDate defaultStart = today.minusDays(29);

    LocalDate startDate = defaultStart;
    LocalDate endDate = today;

    DateTimeFormatter dateFormatter =
        DateTimeFormatter.ofPattern("dd MMM");

    DateTimeFormatter monthFormatter =
        DateTimeFormatter.ofPattern("MMM yyyy");

    String startParam = request.getParameter("startDate");
    String endParam = request.getParameter("endDate");

    try {
        if (startParam != null && !startParam.trim().isEmpty()) {
            startDate = LocalDate.parse(startParam);
        }

        if (endParam != null && !endParam.trim().isEmpty()) {
            endDate = LocalDate.parse(endParam);
        }

        if (endDate.isBefore(startDate)) {
            LocalDate temp = startDate;
            startDate = endDate;
            endDate = temp;
        }

    } catch (Exception dateError) {
        startDate = defaultStart;
        endDate = today;
    }

    String exportType = request.getParameter("export");

    int todayTotal = 0;
    int presentPercent = 0;
    int rangePercent = 0;

    int maxWeeklyTotal = 1;
    int maxMonthlyTotal = 1;

    int totalClosedLectures = 0;

    String highestSubject = "N/A";
    String lowestSubject = "N/A";

    int highestPercent = -1;
    int lowestPercent = 101;

    try (Connection con = DBConnection.getConnection()) {

        // 1. Overall statistics

        try (PreparedStatement ps =
                con.prepareStatement("SELECT COUNT(*) FROM students");
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) totalStudents = rs.getInt(1);
        }

        try (PreparedStatement ps =
                con.prepareStatement("SELECT COUNT(*) FROM attendance");
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) totalRecords = rs.getInt(1);
        }

        // 2. Today's attendance

        String todaySql =
            "SELECT " +
            "COALESCE(SUM(CASE WHEN status='Present' THEN 1 ELSE 0 END),0), " +
            "COALESCE(SUM(CASE WHEN status='Absent' THEN 1 ELSE 0 END),0) " +
            "FROM attendance WHERE attendance_date=?";

        try (PreparedStatement ps = con.prepareStatement(todaySql)) {

            ps.setDate(1, Date.valueOf(today));

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    presentToday = rs.getInt(1);
                    absentToday = rs.getInt(2);
                }
            }
        }

        todayTotal = presentToday + absentToday;

        presentPercent = todayTotal == 0
            ? 0
            : (int)Math.round(presentToday * 100.0 / todayTotal);

        // 3. Selected date range statistics

        String rangeSql =
            "SELECT " +
            "COUNT(*), " +
            "COALESCE(SUM(CASE WHEN status='Present' THEN 1 ELSE 0 END),0), " +
            "COALESCE(SUM(CASE WHEN status='Absent' THEN 1 ELSE 0 END),0) " +
            "FROM attendance WHERE attendance_date BETWEEN ? AND ?";

        try (PreparedStatement ps = con.prepareStatement(rangeSql)) {

            ps.setDate(1, Date.valueOf(startDate));
            ps.setDate(2, Date.valueOf(endDate));

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    rangeRecords = rs.getInt(1);
                    rangePresent = rs.getInt(2);
                    rangeAbsent = rs.getInt(3);
                }
            }
        }

        int rangeTotal = rangePresent + rangeAbsent;

        rangePercent = rangeTotal == 0
            ? 0
            : (int)Math.round(rangePresent * 100.0 / rangeTotal);

        // 4. Weekly trend: last seven days

        String dailySql =
            "SELECT " +
            "COALESCE(SUM(CASE WHEN status='Present' THEN 1 ELSE 0 END),0), " +
            "COALESCE(SUM(CASE WHEN status='Absent' THEN 1 ELSE 0 END),0) " +
            "FROM attendance WHERE attendance_date=?";

        for (int i = 0; i < 7; i++) {

            LocalDate day = today.minusDays(6 - i);
            weeklyLabels[i] = day.format(dateFormatter);

            try (PreparedStatement ps = con.prepareStatement(dailySql)) {

                ps.setDate(1, Date.valueOf(day));

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        weeklyPresent[i] = rs.getInt(1);
                        weeklyAbsent[i] = rs.getInt(2);
                    }
                }
            }

            int dailyTotal = weeklyPresent[i] + weeklyAbsent[i];

            if (dailyTotal > maxWeeklyTotal) {
                maxWeeklyTotal = dailyTotal;
            }
        }

        // 5. Monthly trend: last six calendar months

        LocalDate firstMonth =
            today.withDayOfMonth(1).minusMonths(5);

        Map<Integer, Integer> monthlyPresentMap =
            new HashMap<Integer, Integer>();

        Map<Integer, Integer> monthlyAbsentMap =
            new HashMap<Integer, Integer>();

        String monthlySql =
            "SELECT YEAR(attendance_date), MONTH(attendance_date), " +
            "COALESCE(SUM(CASE WHEN status='Present' THEN 1 ELSE 0 END),0), " +
            "COALESCE(SUM(CASE WHEN status='Absent' THEN 1 ELSE 0 END),0) " +
            "FROM attendance " +
            "WHERE attendance_date BETWEEN ? AND ? " +
            "GROUP BY YEAR(attendance_date), MONTH(attendance_date)";

        try (PreparedStatement ps = con.prepareStatement(monthlySql)) {

            ps.setDate(1, Date.valueOf(firstMonth));
            ps.setDate(2, Date.valueOf(today));

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    int key = rs.getInt(1) * 100 + rs.getInt(2);

                    monthlyPresentMap.put(key, rs.getInt(3));
                    monthlyAbsentMap.put(key, rs.getInt(4));
                }
            }
        }

        for (int i = 0; i < 6; i++) {

            YearMonth ym = YearMonth.from(firstMonth.plusMonths(i));

            int key = ym.getYear() * 100 + ym.getMonthValue();

            monthlyLabels[i] =
                ym.atDay(1).format(monthFormatter);

            monthlyPresent[i] =
                monthlyPresentMap.containsKey(key)
                ? monthlyPresentMap.get(key) : 0;

            monthlyAbsent[i] =
                monthlyAbsentMap.containsKey(key)
                ? monthlyAbsentMap.get(key) : 0;

            int monthlyTotal =
                monthlyPresent[i] + monthlyAbsent[i];

            if (monthlyTotal > maxMonthlyTotal) {
                maxMonthlyTotal = monthlyTotal;
            }
        }

        // 6. Subject-wise analytics
        // Only Closed lectures are counted.
        // All active subjects are included, even if they have no lectures.

        String subjectSql =
            "SELECT " +
            "sub.subject_code, " +
            "sub.subject_name, " +

            "COUNT(DISTINCT ls.lecture_id) AS closed_lectures, " +

            "COUNT(DISTINCT CASE " +
            "WHEN a.status='Present' THEN a.attendance_id END) AS present_records, " +

            "COUNT(DISTINCT CASE " +
            "WHEN a.status='Absent' THEN a.attendance_id END) AS absent_records " +

            "FROM subjects sub " +

            "LEFT JOIN class_timetable ct " +
            "ON ct.subject_id=sub.subject_id " +
            "AND ct.is_active=1 " +

            "LEFT JOIN lecture_sessions ls " +
            "ON ls.timetable_id=ct.timetable_id " +
            "AND ls.session_status='Closed' " +
            "AND ls.lecture_date BETWEEN ? AND ? " +

            "LEFT JOIN attendance a " +
            "ON a.lecture_id=ls.lecture_id " +
            "AND a.attendance_date BETWEEN ? AND ? " +

            "WHERE sub.is_active=1 " +

            "GROUP BY sub.subject_id, sub.subject_code, sub.subject_name " +
            "ORDER BY sub.subject_code";

        try (PreparedStatement ps = con.prepareStatement(subjectSql)) {

            ps.setDate(1, Date.valueOf(startDate));
            ps.setDate(2, Date.valueOf(endDate));
            ps.setDate(3, Date.valueOf(startDate));
            ps.setDate(4, Date.valueOf(endDate));

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    String code = rs.getString("subject_code");
                    String name = rs.getString("subject_name");

                    int lectures = rs.getInt("closed_lectures");
                    int present = rs.getInt("present_records");
                    int absent = rs.getInt("absent_records");

                    int marked = present + absent;

                    int percentage = marked == 0
                        ? -1
                        : (int)Math.round(present * 100.0 / marked);

                    subjectCodes.add(code);
                    subjectNames.add(name);
                    subjectLectures.add(lectures);
                    subjectPresent.add(present);
                    subjectAbsent.add(absent);
                    subjectPercentages.add(percentage);

                    totalClosedLectures += lectures;

                    if (marked > 0) {

                        if (percentage > highestPercent) {
                            highestPercent = percentage;
                            highestSubject = code;
                        }

                        if (percentage < lowestPercent) {
                            lowestPercent = percentage;
                            lowestSubject = code;
                        }
                    }
                }
            }
        }

    } catch (Exception e) {

        application.log("Attendance analytics failed", e);

        errorMessage =
            "Analytics could not load. Please check the database connection.";
    }

    // 7. CSV export

    if ("subjects".equals(exportType)) {

        response.setContentType("text/csv;charset=UTF-8");

        response.setHeader(
            "Content-Disposition",
            "attachment; filename=Attendance_Subject_Analytics.csv"
        );

        out.clearBuffer();

        out.print('\uFEFF');

        out.println(
            "Subject Code,Subject Name,Closed Lectures,Present Records,Absent Records,Attendance Percentage"
        );

        if (errorMessage == null) {

            for (int i = 0; i < subjectCodes.size(); i++) {

                int percentage = subjectPercentages.get(i);

                out.println(
                    csvCell(subjectCodes.get(i)) + "," +
                    csvCell(subjectNames.get(i)) + "," +
                    subjectLectures.get(i) + "," +
                    subjectPresent.get(i) + "," +
                    subjectAbsent.get(i) + "," +
                    (percentage < 0 ? "N/A" : percentage + "%")
                );
            }
        }

        return;
    }

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

<title>AttendancePro | Advanced Analytics</title>

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

.back,
.export-btn,
.filter-btn {
    padding: 11px 16px;
    background: #4358e4;
    border: 0;
    border-radius: 8px;
    color: white;
    text-decoration: none;
    font-size: 13px;
    cursor: pointer;
}

main {
    max-width: 1250px;
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
    grid-template-columns: repeat(3, minmax(0, 1fr));
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

.stat small {
    display: block;
    margin-top: 7px;
    color: #8995a8;
    font-size: 11px;
}

.filter-card,
.chart-card,
.insight-card,
.subject-card {
    min-width: 0;
    padding: 23px;
    background: white;
    border: 1px solid #e6ebf4;
    border-radius: 14px;
    box-shadow: 0 5px 18px rgba(30, 50, 90, .04);
    margin-bottom: 20px;
}

.filter-card h3,
.chart-card h3,
.insight-card h3,
.subject-card h3 {
    margin: 0 0 7px;
    font-size: 16px;
}

.filter-card > p,
.chart-card > p,
.insight-card > p,
.subject-card > p {
    margin: 0 0 20px;
    color: #8290a6;
    font-size: 12px;
    line-height: 1.5;
}

.filter-form {
    display: flex;
    align-items: end;
    gap: 13px;
    flex-wrap: wrap;
}

.filter-field {
    display: flex;
    flex-direction: column;
    gap: 7px;
}

.filter-field label {
    color: #66738a;
    font-size: 12px;
}

.filter-field input {
    padding: 10px;
    border: 1px solid #dce3ef;
    border-radius: 8px;
    color: #243451;
    font-family: inherit;
}

.filter-btn {
    background: #4358e4;
}

.reset-btn {
    color: #66738a;
    font-size: 12px;
    text-decoration: none;
    padding: 11px;
}

.charts {
    display: grid;
    grid-template-columns: 1.5fr 1fr;
    gap: 20px;
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

.monthly-card {
    margin-top: 20px;
}

.insights {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 14px;
}

.insight-item {
    padding: 17px;
    background: #f7f9fd;
    border: 1px solid #e9edf5;
    border-radius: 11px;
}

.insight-item span {
    display: block;
    color: #8290a6;
    font-size: 11px;
    margin-bottom: 9px;
}

.insight-item strong {
    font-size: 17px;
    color: #243451;
}

.insight-item small {
    display: block;
    margin-top: 7px;
    color: #8290a6;
    font-size: 11px;
}

.table-wrap {
    overflow-x: auto;
}

table {
    width: 100%;
    border-collapse: collapse;
    min-width: 720px;
}

th,
td {
    padding: 13px 12px;
    text-align: left;
    border-bottom: 1px solid #edf0f6;
    font-size: 12px;
}

th {
    color: #77849a;
    background: #f8faff;
    font-weight: 650;
}

td {
    color: #34425d;
}

.percent {
    font-weight: 750;
}

.progress {
    width: 105px;
    height: 7px;
    border-radius: 10px;
    background: #e9edf5;
    overflow: hidden;
    margin-top: 6px;
}

.progress-fill {
    height: 100%;
    border-radius: 10px;
    background: #19a875;
}

.na {
    color: #9aa5b5;
}

.subject-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
    margin-bottom: 18px;
}

.subject-header h3 {
    margin: 0;
}

.export-btn {
    background: #172d50;
}

.notice {
    margin-top: 14px;
    padding: 13px;
    border-radius: 9px;
    background: #f4f7fc;
    color: #63728b;
    font-size: 12px;
    line-height: 1.6;
}

.error {
    padding: 15px;
    border-radius: 9px;
    background: #fff0f0;
    color: #a92727;
}

.empty {
    padding: 24px;
    text-align: center;
    color: #8995a8;
    font-size: 13px;
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

    .insights {
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

    .chart-card,
    .subject-card,
    .filter-card,
    .insight-card {
        padding: 15px;
    }

    .bar-chart {
        gap: 3px;
    }

    .bar-pair {
        gap: 2px;
    }

    .filter-field,
    .filter-field input {
        width: 100%;
    }
}

</style>

</head>

<body>

<header>

    <div>
        <h1>AttendancePro</h1>
        <p>ADVANCED STUDENT ATTENDANCE ANALYTICS</p>
    </div>

    <a class="back" href="index.jsp">Back to Dashboard</a>

</header>

<main>

    <section class="intro">

        <h2>Analytics Overview</h2>

        <p>
            Complete attendance insights, trends and subject performance.
        </p>

    </section>

    <% if (errorMessage != null) { %>

        <div class="error"><%= escHtml(errorMessage) %></div>

    <% } else { %>

    <!-- OVERALL STATISTICS -->

    <section class="stats">

        <div class="stat">
            <p>Total Students</p>
            <div class="number"><%= totalStudents %></div>
            <small>All registered students</small>
        </div>

        <div class="stat">
            <p>All Attendance Records</p>
            <div class="number"><%= totalRecords %></div>
            <small>Saved attendance entries</small>
        </div>

        <div class="stat">
            <p>Present Today</p>
            <div class="number"><%= presentToday %></div>
            <small>Today's present records</small>
        </div>

        <div class="stat">
            <p>Absent Today</p>
            <div class="number"><%= absentToday %></div>
            <small>Today's absent records</small>
        </div>

        <div class="stat">
            <p>Selected Range Records</p>
            <div class="number"><%= rangeRecords %></div>
            <small>Records in selected date range</small>
        </div>

        <div class="stat">
            <p>Selected Range Attendance</p>
            <div class="number">
                <%= rangeRecords == 0 ? "N/A" : rangePercent + "%" %>
            </div>
            <small>Based on marked Present/Absent records</small>
        </div>

    </section>

    <!-- DATE FILTER -->

    <section class="filter-card">

        <h3>Attendance Date Filter</h3>

        <p>
            Select a date range to view attendance and subject analytics.
        </p>

        <form method="get" action="attendanceAnalytics.jsp"
              class="filter-form">

            <div class="filter-field">

                <label for="startDate">Start Date</label>

                <input type="date"
                       id="startDate"
                       name="startDate"
                       value="<%= startDate %>"
                       required>

            </div>

            <div class="filter-field">

                <label for="endDate">End Date</label>

                <input type="date"
                       id="endDate"
                       name="endDate"
                       value="<%= endDate %>"
                       required>

            </div>

            <button class="filter-btn" type="submit">
                Apply Filter
            </button>

            <a class="reset-btn"
               href="attendanceAnalytics.jsp">
                Reset
            </a>

        </form>

    </section>

    <!-- WEEKLY AND TODAY CHARTS -->

    <section class="charts">

        <div class="chart-card">

            <h3>Weekly Attendance Trend</h3>

            <p>
                Present and absent records for the last seven days.
            </p>

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
                             title="Present: <%= weeklyPresent[i] %>">
                        </div>

                        <div class="bar absent-bar"
                             style="height:<%= aHeight %>px"
                             title="Absent: <%= weeklyAbsent[i] %>">
                        </div>

                    </div>

                    <div class="day-label">
                        <%= weeklyLabels[i] %>
                    </div>

                </div>

                <% } %>

            </div>

            <div class="legend">

                <div class="legend-item">
                    <span class="legend-dot"
                          style="background:#19a875"></span>
                    Present
                </div>

                <div class="legend-item">
                    <span class="legend-dot"
                          style="background:#ed7777"></span>
                    Absent
                </div>

            </div>

        </div>

        <div class="chart-card">

            <h3>Today's Attendance</h3>

            <p>
                Distribution of today's marked attendance records.
            </p>

            <div class="donut-area">

                <div class="donut"
                     style="background:<%= donutStyle %>">

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

                    <p class="empty">
                        No attendance marked today.
                    </p>

                <% } %>

            </div>

        </div>

    </section>

    <!-- MONTHLY TREND -->

    <section class="chart-card monthly-card">

        <h3>Six-Month Attendance Trend</h3>

        <p>
            Monthly comparison of Present and Absent records.
        </p>

        <div class="bar-chart">

            <% for (int i = 0; i < 6; i++) {

                int pHeight = monthlyPresent[i] == 0
                    ? 0
                    : Math.max(5, (int)Math.round(
                        monthlyPresent[i] * 215.0 / maxMonthlyTotal));

                int aHeight = monthlyAbsent[i] == 0
                    ? 0
                    : Math.max(5, (int)Math.round(
                        monthlyAbsent[i] * 215.0 / maxMonthlyTotal));
            %>

            <div class="bar-group">

                <div class="bar-pair">

                    <div class="bar present-bar"
                         style="height:<%= pHeight %>px"
                         title="Present: <%= monthlyPresent[i] %>">
                    </div>

                    <div class="bar absent-bar"
                         style="height:<%= aHeight %>px"
                         title="Absent: <%= monthlyAbsent[i] %>">
                    </div>

                </div>

                <div class="day-label">
                    <%= monthlyLabels[i] %>
                </div>

            </div>

            <% } %>

        </div>

        <div class="legend">

            <div class="legend-item">
                <span class="legend-dot"
                      style="background:#19a875"></span>
                Present
            </div>

            <div class="legend-item">
                <span class="legend-dot"
                      style="background:#ed7777"></span>
                Absent
            </div>

        </div>

    </section>

    <!-- SMART INSIGHTS -->

    <section class="insight-card">

        <h3>Smart Attendance Insights</h3>

        <p>
            Automatically generated observations from saved records.
        </p>

        <div class="insights">

            <div class="insight-item">

                <span>Attendance in selected range</span>

                <strong>
                    <%= rangeRecords == 0 ? "N/A" : rangePercent + "%" %>
                </strong>

                <small>
                    <%= rangePresent %> Present /
                    <%= rangeAbsent %> Absent
                </small>

            </div>

            <div class="insight-item">

                <span>Highest subject attendance</span>

                <strong><%= escHtml(highestSubject) %></strong>

                <small>
                    <%= highestPercent < 0
                        ? "No marked attendance data"
                        : highestPercent + "% attendance" %>
                </small>

            </div>

            <div class="insight-item">

                <span>Lowest subject attendance</span>

                <strong><%= escHtml(lowestSubject) %></strong>

                <small>
                    <%= lowestPercent > 100
                        ? "No marked attendance data"
                        : lowestPercent + "% attendance" %>
                </small>

            </div>

        </div>

        <div class="notice">

            <% if (rangeRecords == 0) { %>

                No attendance records are available in the selected date
                range. Attendance insights will appear after records are saved.

            <% } else if (rangePercent >= 75) { %>

                Attendance in the selected range is at least 75% based on
                recorded Present and Absent entries.

            <% } else { %>

                Attendance in the selected range is below 75% based on
                recorded Present and Absent entries.

            <% } %>

            <br>

            Total Closed Lectures in selected range:
            <strong><%= totalClosedLectures %></strong>

        </div>

    </section>

    <!-- SUBJECT-WISE ANALYTICS -->

    <section class="subject-card">

        <div class="subject-header">

            <div>
                <h3>Subject-wise Attendance Analytics</h3>

                <p>
                    Subject performance using Closed lecture sessions
                    in the selected date range.
                </p>
            </div>

            <a class="export-btn"
               href="attendanceAnalytics.jsp?export=subjects&amp;startDate=<%= startDate %>&amp;endDate=<%= endDate %>">
                Export CSV
            </a>

        </div>

        <% if (subjectCodes.size() == 0) { %>

            <div class="empty">
                No active subjects found.
            </div>

        <% } else { %>

        <div class="table-wrap">

            <table>

                <thead>

                    <tr>
                        <th>Subject Code</th>
                        <th>Subject Name</th>
                        <th>Closed Lectures</th>
                        <th>Present</th>
                        <th>Absent</th>
                        <th>Attendance</th>
                    </tr>

                </thead>

                <tbody>

                    <% for (int i = 0; i < subjectCodes.size(); i++) {

                        int percentage = subjectPercentages.get(i);
                    %>

                    <tr>

                        <td>
                            <strong>
                                <%= escHtml(subjectCodes.get(i)) %>
                            </strong>
                        </td>

                        <td>
                            <%= escHtml(subjectNames.get(i)) %>
                        </td>

                        <td>
                            <%= subjectLectures.get(i) %>
                        </td>

                        <td>
                            <%= subjectPresent.get(i) %>
                        </td>

                        <td>
                            <%= subjectAbsent.get(i) %>
                        </td>

                        <td>

                            <% if (percentage < 0) { %>

                                <span class="na">N/A</span>

                            <% } else { %>

                                <span class="percent">
                                    <%= percentage %>%
                                </span>

                                <div class="progress">

                                    <div class="progress-fill"
                                         style="width:<%= percentage %>%">
                                    </div>

                                </div>

                            <% } %>

                        </td>

                    </tr>

                    <% } %>

                </tbody>

            </table>

        </div>

        <div class="notice">

            N/A means there are no Present/Absent records for that subject
            in the selected date range. Open, Scheduled and Cancelled
            sessions are not counted as Closed lectures.

        </div>

        <% } %>

    </section>

    <% } %>

</main>

<footer>

    Student Attendance Management System |
    AttendancePro Advanced Analytics

</footer>

</body>
</html>