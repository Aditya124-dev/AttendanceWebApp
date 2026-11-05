
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.Date" %>
<%@ page import="com.attendance.DBConnection" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>

<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>

<%
    request.setCharacterEncoding("UTF-8");

    String search = request.getParameter("search");
    String dateFilter = request.getParameter("date");
    String statusFilter = request.getParameter("status");
    String subjectParam = request.getParameter("subject");

    if (search == null) search = "";
    if (dateFilter == null) dateFilter = "";
    if (subjectParam == null) subjectParam = "";

    search = search.trim();

    if (!"Present".equals(statusFilter) && !"Absent".equals(statusFilter)) {
        statusFilter = "";
    }

    Integer subjectId = null;
    try {
        if (!subjectParam.isEmpty()) {
            subjectId = Integer.valueOf(subjectParam);
            if (subjectId <= 0) subjectId = null;
        }
    } catch (NumberFormatException ignored) {
        subjectId = null;
    }

    Date filterDate = null;
    String errorMessage = null;
    boolean exportCsv = "csv".equals(request.getParameter("export"));

    if (!dateFilter.isEmpty()) {
        try {
            filterDate = Date.valueOf(dateFilter);
        } catch (IllegalArgumentException e) {
            errorMessage = "Please select a valid attendance date.";
        }
    }

    StringBuilder sql = new StringBuilder(
        "SELECT s.roll_no, s.name, s.course, s.semester, " +
        "a.attendance_date, a.status, sub.subject_code, sub.subject_name " +
        "FROM students s " +
        "INNER JOIN attendance a ON s.student_id = a.student_id " +
        "LEFT JOIN lecture_sessions ls ON a.lecture_id = ls.lecture_id " +
        "LEFT JOIN class_timetable ct ON ls.timetable_id = ct.timetable_id " +
        "LEFT JOIN subjects sub ON ct.subject_id = sub.subject_id " +
        "WHERE 1=1 "
    );

    if (!search.isEmpty()) {
        sql.append("AND (s.roll_no LIKE ? OR s.name LIKE ?) ");
    }
    if (filterDate != null) {
        sql.append("AND a.attendance_date = ? ");
    }
    if (!statusFilter.isEmpty()) {
        sql.append("AND a.status = ? ");
    }
    if (subjectId != null) {
        sql.append("AND sub.subject_id = ? ");
    }

    sql.append("ORDER BY a.attendance_date DESC, s.name ASC");

    List<String[]> rows = new ArrayList<String[]>();
    List<String[]> subjects = new ArrayList<String[]>();

    try (Connection con = DBConnection.getConnection()) {
        try (PreparedStatement subjectPs = con.prepareStatement(
                "SELECT subject_id, subject_code, subject_name " +
                "FROM subjects WHERE is_active = 1 " +
                "ORDER BY subject_code")) {
            try (ResultSet subjectRs = subjectPs.executeQuery()) {
                while (subjectRs.next()) {
                    subjects.add(new String[] {
                        subjectRs.getString("subject_id"),
                        subjectRs.getString("subject_code"),
                        subjectRs.getString("subject_name")
                    });
                }
            }
        }

        if (errorMessage == null) {
            try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
                int i = 1;

                if (!search.isEmpty()) {
                    ps.setString(i++, "%" + search + "%");
                    ps.setString(i++, "%" + search + "%");
                }
                if (filterDate != null) ps.setDate(i++, filterDate);
                if (!statusFilter.isEmpty()) ps.setString(i++, statusFilter);
                if (subjectId != null) ps.setInt(i++, subjectId);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        rows.add(new String[] {
                            rs.getString("roll_no"),
                            rs.getString("name"),
                            rs.getString("course"),
                            rs.getString("semester"),
                            String.valueOf(rs.getDate("attendance_date")),
                            rs.getString("status"),
                            rs.getString("subject_code"),
                            rs.getString("subject_name")
                        });
                    }
                }
            }
        }
    } catch (Exception e) {
        application.log("Unable to load attendance report", e);
        errorMessage = "Unable to load the report. Please check the database connection.";
    }

    if (exportCsv && errorMessage == null) {
        response.setContentType("text/csv; charset=UTF-8");
        response.setHeader("Content-Disposition",
                           "attachment; filename=\"attendance-report.csv\"");
        out.clear();
        out.println("\uFEFFRoll Number,Student Name,Course,Semester,Attendance Date,Status,Subject Code,Subject Name");

        for (String[] row : rows) {
            for (int c = 0; c < row.length; c++) {
                if (c > 0) out.print(",");
                String value = row[c] == null ? "" : row[c];
                out.print("\"" + value.replace("\"", "\"\"") + "\"");
            }
            out.println();
        }
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Attendance Report | AttendancePro</title>
<style>
*{box-sizing:border-box}
body{margin:0;padding:28px 18px;font-family:"Segoe UI",Arial,sans-serif;background:#f3f6fc;color:#1d2940}
.container{max-width:1250px;margin:auto}
.header{display:flex;justify-content:space-between;align-items:center;gap:15px;flex-wrap:wrap;margin-bottom:24px}
h1{margin:0 0 8px;color:#172554;font-size:28px}
.subtitle{margin:0;color:#7b879b;font-size:14px}
.panel{background:#fff;padding:22px;border:1px solid #e6ebf4;border-radius:15px;margin-bottom:22px;box-shadow:0 5px 20px #1e325a08}
.panel-title{margin:0 0 18px;font-size:17px}
.filters{display:grid;grid-template-columns:2fr 1fr 1fr 1.5fr auto auto;gap:12px;align-items:end}
label{display:block;margin-bottom:7px;color:#66738a;font-size:12px;font-weight:600}
input,select{width:100%;min-width:0;padding:11px;border:1px solid #dce3ee;border-radius:8px;background:white;color:#26334c;font-size:13px}
.button{display:inline-block;padding:12px 15px;border:0;border-radius:8px;cursor:pointer;text-decoration:none;text-align:center;white-space:nowrap;font-size:13px;font-weight:600}
.primary{background:#4257dc;color:white}.secondary{background:#eef1f7;color:#41506b}.export{background:#168451;color:white}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;min-width:850px}
th{text-align:left;background:#f5f7fc;color:#65738b;font-size:11px;text-transform:uppercase;letter-spacing:.4px}
th,td{padding:13px 12px;border-bottom:1px solid #edf0f6}
td{font-size:13px;color:#34425b}
tbody tr:hover{background:#fafbff}
.status{display:inline-block;padding:6px 10px;border-radius:20px;font-size:11px;font-weight:700}
.present{background:#e3f8ec;color:#177b4c}.absent{background:#ffebeb;color:#b63131}
.empty,.error{padding:22px;text-align:center}.empty{color:#748198}.error{color:#b63131;background:#fff5f5}
.count{color:#68758c;font-size:13px;margin:0 0 14px}
.actions{display:flex;gap:10px;flex-wrap:wrap;margin-top:16px}
.footer{padding:18px 0 5px;color:#96a1b3;font-size:11px;text-align:center}
@media(max-width:1050px){.filters{grid-template-columns:repeat(3,minmax(0,1fr))}}
@media(max-width:600px){body{padding:16px 10px}h1{font-size:23px}.panel{padding:15px}.filters{grid-template-columns:1fr}.button{width:100%}}
</style>
</head>
<body>
<div class="container">
<header class="header">
    <div>
        <h1>Attendance Report</h1>
        <p class="subtitle">Search, filter and export saved student attendance records.</p>
    </div>
    <a class="button primary" href="index.jsp">&larr; Back to Dashboard</a>
</header>

<section class="panel">
<h2 class="panel-title">Search and Filter Records</h2>
<form action="viewReport.jsp" method="get" class="filters">
    <div>
        <label for="search">Student Name / Roll Number</label>
        <input id="search" name="search" value="<%= esc(search) %>" placeholder="Enter name or roll number">
    </div>
    <div>
        <label for="date">Attendance Date</label>
        <input id="date" type="date" name="date" value="<%= esc(dateFilter) %>">
    </div>
    <div>
        <label for="status">Status</label>
        <select id="status" name="status">
            <option value="">All statuses</option>
            <option value="Present" <%= "Present".equals(statusFilter) ? "selected" : "" %>>Present</option>
            <option value="Absent" <%= "Absent".equals(statusFilter) ? "selected" : "" %>>Absent</option>
        </select>
    </div>
    <div>
        <label for="subject">Subject</label>
        <select id="subject" name="subject">
            <option value="">All subjects</option>
            <% for (String[] sub : subjects) { %>
            <option value="<%= esc(sub[0]) %>" <%= subjectId != null && String.valueOf(subjectId).equals(sub[0]) ? "selected" : "" %>>
                <%= esc(sub[1]) %> - <%= esc(sub[2]) %>
            </option>
            <% } %>
        </select>
    </div>
    <button class="button primary" type="submit">Search</button>
    <a class="button secondary" href="viewReport.jsp">Reset</a>
</form>
<div class="actions">
    <form action="viewReport.jsp" method="get">
        <input type="hidden" name="search" value="<%= esc(search) %>">
        <input type="hidden" name="date" value="<%= esc(dateFilter) %>">
        <input type="hidden" name="status" value="<%= esc(statusFilter) %>">
        <input type="hidden" name="subject" value="<%= subjectId == null ? "" : subjectId %>">
        <button class="button export" type="submit" name="export" value="csv">Export CSV</button>
    </form>
</div>
</section>

<section class="panel">
<h2 class="panel-title">Attendance Records</h2>
<p class="count">Records found: <strong><%= rows.size() %></strong></p>
<div class="table-wrap">
<table>
<thead>
<tr>
<th>Roll Number</th><th>Student Name</th><th>Course</th><th>Semester</th>
<th>Date</th><th>Status</th><th>Subject Code</th><th>Subject Name</th>
</tr>
</thead>
<tbody>
<% if (errorMessage != null) { %>
<tr><td colspan="8" class="error"><%= esc(errorMessage) %></td></tr>
<% } else if (rows.isEmpty()) { %>
<tr><td colspan="8" class="empty">No attendance records found for the selected filters.</td></tr>
<% } else { for (String[] row : rows) { %>
<tr>
<td><%= esc(row[0]) %></td>
<td><%= esc(row[1]) %></td>
<td><%= esc(row[2]) %></td>
<td><%= esc(row[3]) %></td>
<td><%= esc(row[4]) %></td>
<td><span class="status <%= "Present".equals(row[5]) ? "present" : "absent" %>"><%= esc(row[5]) %></span></td>
<td><%= esc(row[6] == null ? "Unlinked" : row[6]) %></td>
<td><%= esc(row[7] == null ? "Legacy / No lecture link" : row[7]) %></td>
</tr>
<% } } %>
</tbody>
</table>
</div>
</section>
<footer class="footer">Student Attendance Management System | Academic Project</footer>
</div>
</body>
</html>
