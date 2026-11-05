
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.attendance.DBConnection" %>

<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }

    private String pct(double value) {
        return String.format(Locale.US, "%.1f", value);
    }
%>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Object teacherObject = session.getAttribute("teacherId");

    if (teacherObject == null ||
        !"TEACHER".equals(session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/teacherLogin.jsp");
        return;
    }

    int teacherId = Integer.parseInt(teacherObject.toString());
    String teacherName = String.valueOf(
        session.getAttribute("teacherName") == null
        ? "Teacher"
        : session.getAttribute("teacherName")
    );

    List<Map<String, Object>> studentRows = new ArrayList<>();
    Map<String, Map<String, Object>> subjectMap = new LinkedHashMap<>();
    Set<Integer> studentIds = new LinkedHashSet<>();

    int totalPossible = 0;
    int totalPresent = 0;
    int lowAttendanceCount = 0;
    int totalClosedLectures = 0;

    boolean databaseError = false;

    String sql =
        "SELECT " +
        "sub.subject_id, sub.subject_code, sub.subject_name, " +
        "st.student_id, st.roll_no, st.name, " +
        "COUNT(DISTINCT CASE " +
        "WHEN ls.session_status = 'Closed' THEN ls.lecture_id END) AS total_lectures, " +
        "COUNT(DISTINCT CASE " +
        "WHEN ls.session_status = 'Closed' AND a.status = 'Present' " +
        "THEN ls.lecture_id END) AS present_count " +
        "FROM class_timetable ct " +
        "JOIN subjects sub ON sub.subject_id = ct.subject_id " +
        "JOIN students st ON " +
        "LOWER(REPLACE(REPLACE(REPLACE(TRIM(st.course), '.', ''), ' ', ''), '-', '')) " +
        "IN ('btech', 'cse') " +
        "AND CAST(st.semester AS UNSIGNED) = sub.semester " +
        "LEFT JOIN lecture_sessions ls " +
        "ON ls.timetable_id = ct.timetable_id " +
        "LEFT JOIN attendance a " +
        "ON a.lecture_id = ls.lecture_id " +
        "AND a.student_id = st.student_id " +
        "WHERE ct.teacher_id = ? " +
        "AND ct.is_active = 1 " +
        "AND sub.is_active = 1 " +
        "GROUP BY sub.subject_id, sub.subject_code, sub.subject_name, " +
        "st.student_id, st.roll_no, st.name " +
        "ORDER BY sub.subject_code, st.name";

    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setInt(1, teacherId);

        try (ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                int subjectId = rs.getInt("subject_id");
                int studentId = rs.getInt("student_id");
                int lectures = rs.getInt("total_lectures");
                int present = rs.getInt("present_count");

                String subjectCode = rs.getString("subject_code");
                String subjectName = rs.getString("subject_name");

                int absent = Math.max(0, lectures - present);

                double percentage = lectures == 0
                    ? 0.0
                    : present * 100.0 / lectures;

                int shortage = lectures == 0
                    ? 0
                    : Math.max(0, (int)Math.ceil(3.0 * lectures - 4.0 * present));

                Map<String, Object> row = new LinkedHashMap<>();

                row.put("subjectCode", subjectCode);
                row.put("subjectName", subjectName);
                row.put("rollNo", rs.getString("roll_no"));
                row.put("studentName", rs.getString("name"));
                row.put("lectures", lectures);
                row.put("present", present);
                row.put("absent", absent);
                row.put("percentage", percentage);
                row.put("shortage", shortage);

                studentRows.add(row);
                studentIds.add(studentId);

                totalPossible += lectures;
                totalPresent += present;

                if (lectures > 0 && percentage < 75.0) {
                    lowAttendanceCount++;
                }

                if (!subjectMap.containsKey(subjectCode)) {
                    Map<String, Object> subject = new LinkedHashMap<>();
                    subject.put("name", subjectName);
                    subject.put("lectures", lectures);
                    subjectMap.put(subjectCode, subject);
                    totalClosedLectures += lectures;
                }
            }
        }

    } catch (Exception e) {
        databaseError = true;
        application.log("Attendance Summary database error", e);
    }

    int totalStudents = studentIds.size();
    int totalSubjects = subjectMap.size();

    double overallPercentage = totalPossible == 0
        ? 0.0
        : totalPresent * 100.0 / totalPossible;
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>Smart Attendance Analytics | AttendancePro</title>

<style>
* {
    box-sizing: border-box;
}

body {
    margin: 0;
    background: #f3f6fb;
    color: #1d2939;
    font-family: "Segoe UI", Arial, sans-serif;
}

header {
    background: #17365d;
    color: white;
    padding: 20px 5%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 15px;
}

header h1 {
    font-size: 22px;
    margin: 0;
}

.header-right {
    display: flex;
    align-items: center;
    gap: 15px;
    flex-wrap: wrap;
}

header a {
    color: white;
    text-decoration: none;
    border: 1px solid rgba(255,255,255,.6);
    padding: 9px 14px;
    border-radius: 8px;
}

main {
    max-width: 1250px;
    margin: 30px auto;
    padding: 0 20px;
}

.intro {
    margin-bottom: 25px;
}

.intro h2 {
    color: #17365d;
    margin-bottom: 6px;
}

.intro p {
    color: #667085;
    line-height: 1.6;
}

.stats {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 16px;
    margin-bottom: 28px;
}

.stat-card {
    background: white;
    border: 1px solid #e4eaf3;
    border-radius: 13px;
    padding: 21px;
    box-shadow: 0 4px 15px rgba(20,40,80,.04);
}

.stat-card p {
    color: #667085;
    font-size: 14px;
    margin: 0 0 12px;
}

.stat-card h3 {
    color: #17365d;
    font-size: 28px;
    margin: 0;
}

.stat-card .green {
    color: #168451;
}

.stat-card .red {
    color: #c0392b;
}

.section-title {
    color: #17365d;
    margin: 28px 0 15px;
}

.subject-grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 14px;
}

.subject-card {
    background: white;
    border: 1px solid #e4eaf3;
    border-radius: 12px;
    padding: 17px;
}

.subject-card h4 {
    margin: 0 0 8px;
    color: #17365d;
}

.subject-card p {
    margin: 0;
    color: #667085;
    font-size: 13px;
}

.toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin: 20px 0;
}

.toolbar input,
.toolbar select {
    padding: 12px 14px;
    border: 1px solid #d0d5dd;
    border-radius: 8px;
    background: white;
    font-size: 14px;
    min-width: 190px;
}

.toolbar input {
    flex: 1;
}

.btn {
    background: #17365d;
    color: white;
    border: none;
    padding: 12px 17px;
    border-radius: 8px;
    cursor: pointer;
    font-weight: 600;
}

.btn:hover {
    background: #24548c;
}

.table-container {
    overflow-x: auto;
    background: white;
    border-radius: 12px;
    border: 1px solid #e4eaf3;
    box-shadow: 0 4px 15px rgba(20,40,80,.04);
}

table {
    width: 100%;
    border-collapse: collapse;
    min-width: 1050px;
}

th, td {
    padding: 14px 13px;
    border-bottom: 1px solid #e9edf4;
    text-align: left;
    font-size: 13px;
}

th {
    background: #17365d;
    color: white;
    white-space: nowrap;
}

tbody tr:hover {
    background: #f7f9fc;
}

.progress {
    width: 100px;
    height: 8px;
    background: #e9edf4;
    border-radius: 10px;
    overflow: hidden;
    margin-top: 6px;
}

.progress-fill {
    height: 100%;
    background: #168451;
    border-radius: 10px;
}

.low-progress {
    background: #d04444;
}

.status {
    display: inline-block;
    padding: 5px 9px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 700;
}

.eligible {
    color: #087443;
    background: #e7f7ef;
}

.shortage-status {
    color: #b42318;
    background: #fff0ee;
}

.pending {
    color: #875b00;
    background: #fff5d8;
}

.info {
    background: #edf5ff;
    border: 1px solid #c9def8;
    color: #244c7d;
    padding: 15px;
    border-radius: 10px;
    margin: 18px 0;
    line-height: 1.6;
    font-size: 13px;
}

.error {
    background: #fff1f0;
    color: #b42318;
    border: 1px solid #f3b7b2;
    padding: 18px;
    border-radius: 10px;
    margin: 20px 0;
}

.empty {
    text-align: center;
    padding: 30px;
    color: #667085;
}

.note {
    color: #667085;
    font-size: 13px;
    line-height: 1.7;
    margin-top: 18px;
}

footer {
    text-align: center;
    color: #667085;
    padding: 25px;
    font-size: 12px;
}

@media(max-width: 900px) {
    .stats {
        grid-template-columns: repeat(2, 1fr);
    }

    .subject-grid {
        grid-template-columns: repeat(2, 1fr);
    }
}

@media(max-width: 520px) {
    header h1 {
        font-size: 18px;
    }

    main {
        padding: 0 12px;
    }

    .stats {
        gap: 10px;
    }

    .stat-card {
        padding: 14px;
    }

    .stat-card h3 {
        font-size: 22px;
    }

    .subject-grid {
        grid-template-columns: 1fr;
    }

    .toolbar input,
    .toolbar select {
        width: 100%;
    }
}
</style>
</head>

<body>

<header>
    <h1>AttendancePro | Smart Analytics</h1>

    <div class="header-right">
        <span>Welcome, <%= esc(teacherName) %></span>
        <a href="<%= request.getContextPath() %>/teacherDashboard.jsp">
            Dashboard
        </a>
    </div>
</header>

<main>

<section class="intro">
    <h2>Smart Attendance Analytics</h2>
    <p>
        Teacher-wise student attendance, subject performance
        and 75% attendance eligibility.
    </p>
</section>

<% if (databaseError) { %>

    <div class="error">
        <strong>Database connection error.</strong>
        <p>Unable to load attendance analytics. Please check DBConnection and server logs.</p>
    </div>

<% } else { %>

<section class="stats">

    <div class="stat-card">
        <p>Assigned Subjects</p>
        <h3><%= totalSubjects %></h3>
    </div>

    <div class="stat-card">
        <p>Students in Roster</p>
        <h3><%= totalStudents %></h3>
    </div>

    <div class="stat-card">
        <p>Closed Subject Lectures</p>
        <h3><%= totalClosedLectures %></h3>
    </div>

    <div class="stat-card">
        <p>Overall Attendance</p>
        <h3 class="<%= totalPossible == 0 ? "" : (overallPercentage >= 75 ? "green" : "red") %>">
            <%= totalPossible == 0 ? "N/A" : pct(overallPercentage) + "%" %>
        </h3>
    </div>

</section>

<div class="info">
    <strong>75% attendance rule:</strong>
    Only closed lectures are included in the calculation.
    Open and cancelled lectures are excluded.
    Students with no completed lectures are shown as awaiting data.
</div>

<h3 class="section-title">Subject-wise Overview</h3>

<div class="subject-grid">

    <% if (subjectMap.isEmpty()) { %>

        <div class="subject-card">
            <h4>No assigned subjects found</h4>
            <p>Check the teacher's active timetable assignments.</p>
        </div>

    <% } else {
        for (Map.Entry<String, Map<String, Object>> entry : subjectMap.entrySet()) {
    %>

        <div class="subject-card">
            <h4><%= esc(entry.getKey()) %></h4>
            <p><%= esc(String.valueOf(entry.getValue().get("name"))) %></p>
            <p style="margin-top:8px;">
                Closed lectures:
                <strong><%= entry.getValue().get("lectures") %></strong>
            </p>
        </div>

    <%
        }
    } %>

</div>

<h3 class="section-title">Student-wise Attendance Details</h3>

<div class="toolbar">

    <input
        type="text"
        id="searchInput"
        placeholder="Search student name or roll number..."
        onkeyup="filterTable()">

    <select id="subjectFilter" onchange="filterTable()">
        <option value="">All Subjects</option>
        <% for (String code : subjectMap.keySet()) { %>
            <option value="<%= esc(code) %>"><%= esc(code) %></option>
        <% } %>
    </select>

    <button class="btn" type="button" onclick="downloadCSV()">
        Export CSV
    </button>

</div>

<div class="table-container">

<table id="attendanceTable">

<thead>
<tr>
    <th>Subject</th>
    <th>Roll No.</th>
    <th>Student Name</th>
    <th>Closed Lectures</th>
    <th>Present</th>
    <th>Absent</th>
    <th>Attendance %</th>
    <th>75% Status</th>
    <th>Classes Needed</th>
</tr>
</thead>

<tbody>

<% if (studentRows.isEmpty()) { %>

<tr>
    <td colspan="9" class="empty">
        No matching students or assigned subjects found.
    </td>
</tr>

<% } else {
    for (Map<String, Object> row : studentRows) {

        int lectures = (Integer) row.get("lectures");
        int present = (Integer) row.get("present");
        int absent = (Integer) row.get("absent");
        int shortage = (Integer) row.get("shortage");

        double percentage = (Double) row.get("percentage");

        String statusClass;
        String statusText;

        if (lectures == 0) {
            statusClass = "pending";
            statusText = "Awaiting data";
        } else if (percentage >= 75.0) {
            statusClass = "eligible";
            statusText = "Eligible";
        } else {
            statusClass = "shortage-status";
            statusText = "Shortage";
        }

        double barWidth = Math.min(100.0, percentage);
%>

<tr>
    <td><strong><%= esc(String.valueOf(row.get("subjectCode"))) %></strong></td>

    <td><%= esc(String.valueOf(row.get("rollNo"))) %></td>

    <td><%= esc(String.valueOf(row.get("studentName"))) %></td>

    <td><%= lectures %></td>

    <td><%= present %></td>

    <td><%= absent %></td>

    <td>
        <% if (lectures == 0) { %>
            N/A
        <% } else { %>

            <strong><%= pct(percentage) %>%</strong>

            <div class="progress">
                <div class="progress-fill <%= percentage < 75 ? "low-progress" : "" %>"
                     style="width:<%= barWidth %>%;">
                </div>
            </div>

        <% } %>
    </td>

    <td>
        <span class="status <%= statusClass %>">
            <%= statusText %>
        </span>
    </td>

    <td>
        <%= lectures == 0 ? "N/A" : (shortage == 0 ? "0" : shortage) %>
    </td>
</tr>

<%
    }
} %>

</tbody>
</table>

</div>

<p class="note">
    <strong>Calculation:</strong>
    Attendance percentage = Present lectures / Closed lectures × 100.
    The system treats a student without a Present record in a closed lecture
    as absent for this calculation. Classes Needed estimates how many
    consecutive future lectures the student must attend to reach 75%.
    This is a projection, not a guarantee of final eligibility.
</p>

<% } %>

</main>

<footer>
    AttendancePro &copy; 2026 | Student Attendance Management System
</footer>

<script>
function filterTable() {

    const search = document.getElementById("searchInput")
        .value.toLowerCase();

    const subject = document.getElementById("subjectFilter")
        .value.toLowerCase();

    const rows = document.querySelectorAll(
        "#attendanceTable tbody tr"
    );

    rows.forEach(function(row) {

        const text = row.innerText.toLowerCase();
        const rowSubject = row.cells[0]
            ? row.cells[0].innerText.toLowerCase()
            : "";

        const matchesSearch = text.includes(search);
        const matchesSubject = subject === "" ||
            rowSubject === subject;

        row.style.display =
            matchesSearch && matchesSubject ? "" : "none";
    });
}

function downloadCSV() {

    const table = document.getElementById("attendanceTable");

    if (!table) {
        alert("Attendance table is not available.");
        return;
    }

    const rows = Array.from(table.querySelectorAll("tr"))
        .filter(function(row) {
            return row.style.display !== "none";
        });

    const csv = rows.map(function(row) {

        return Array.from(row.querySelectorAll("th, td"))
            .map(function(cell) {

                let value = cell.innerText
                    .replace(/\s+/g, " ")
                    .trim();

                return '"' + value.replace(/"/g, '""') + '"';

            }).join(",");

    }).join("\r\n");

    const blob = new Blob(
        ["\uFEFF" + csv],
        { type: "text/csv;charset=utf-8;" }
    );

    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");

    link.href = url;
    link.download = "AttendancePro_Teacher_Report.csv";

    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    URL.revokeObjectURL(url);
}
</script>

</body>
</html>
