<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.Date" %>
<%@ page import="com.attendance.DBConnection" %>

<%
    request.setCharacterEncoding("UTF-8");

    String search = request.getParameter("search");
    String dateFilter = request.getParameter("date");
    String statusFilter = request.getParameter("status");

    if (search == null) {
        search = "";
    }
    search = search.trim();

    if (dateFilter == null) {
        dateFilter = "";
    }

    if (!"Present".equals(statusFilter)
            && !"Absent".equals(statusFilter)) {
        statusFilter = "";
    }

    Date filterDate = null;
    String errorMessage = null;
    boolean found = false;

    if (!dateFilter.isEmpty()) {
        try {
            filterDate = Date.valueOf(dateFilter);
        } catch (IllegalArgumentException e) {
            errorMessage = "Please select a valid attendance date.";
        }
    }

    StringBuilder sql = new StringBuilder(
        "SELECT s.roll_no, s.name, s.course, s.semester, " +
        "a.attendance_date, a.status " +
        "FROM students s " +
        "INNER JOIN attendance a " +
        "ON s.student_id = a.student_id " +
        "WHERE 1 = 1 "
    );

    if (!search.isEmpty()) {
        sql.append(
            "AND (s.roll_no LIKE ? OR s.name LIKE ?) "
        );
    }

    if (filterDate != null) {
        sql.append("AND a.attendance_date = ? ");
    }

    if (!statusFilter.isEmpty()) {
        sql.append("AND a.status = ? ");
    }

    sql.append(
        "ORDER BY a.attendance_date DESC, s.name ASC"
    );

    String safeSearch = search
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
        .replace("'", "&#39;");

    String safeDate = dateFilter
        .replace("&", "&amp;")
        .replace("\"", "&quot;")
        .replace("<", "&lt;")
        .replace(">", "&gt;");

%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Attendance Report | AttendancePro</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 30px 20px;
            font-family: "Segoe UI", Arial, sans-serif;
            background: #f3f6fc;
            color: #1d2940;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 25px;
        }

        h1 {
            margin: 0 0 8px;
            font-size: 28px;
            color: #172554;
        }

        .subtitle {
            margin: 0;
            color: #7b879b;
            font-size: 14px;
        }

        .home-button {
            display: inline-block;
            background: #4257dc;
            color: white;
            padding: 12px 18px;
            border-radius: 8px;
            text-decoration: none;
            font-size: 13px;
            font-weight: 600;
        }

        .home-button:hover {
            background: #3043be;
        }

        .panel {
            background: #ffffff;
            padding: 24px;
            border: 1px solid #e6ebf4;
            border-radius: 15px;
            margin-bottom: 22px;
            box-shadow: 0 5px 20px rgba(30, 50, 90, 0.04);
        }

        .panel-title {
            margin: 0 0 20px;
            font-size: 17px;
            color: #243451;
        }

        .filters {
            display: grid;
            grid-template-columns: 2fr 1fr 1fr auto auto;
            gap: 12px;
            align-items: end;
        }

        label {
            display: block;
            margin-bottom: 8px;
            color: #66738a;
            font-size: 12px;
            font-weight: 600;
        }

        input,
        select {
            width: 100%;
            min-width: 0;
            padding: 12px;
            border: 1px solid #dce3ee;
            border-radius: 8px;
            background: #ffffff;
            color: #26334c;
            font-size: 13px;
        }

        input:focus,
        select:focus {
            outline: 2px solid #dbe3ff;
            border-color: #5267e8;
        }

        .button {
            display: inline-block;
            padding: 12px 17px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            white-space: nowrap;
            text-decoration: none;
            text-align: center;
            font-size: 13px;
            font-weight: 600;
        }

        .search-button {
            background: #4257dc;
            color: white;
        }

        .search-button:hover {
            background: #3043be;
        }

        .reset-button {
            background: #eef1f7;
            color: #41506b;
        }

        .reset-button:hover {
            background: #e1e6f0;
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 700px;
        }

        th {
            text-align: left;
            background: #f5f7fc;
            color: #65738b;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        th,
        td {
            padding: 15px 13px;
            border-bottom: 1px solid #edf0f6;
        }

        td {
            font-size: 13px;
            color: #34425b;
        }

        tbody tr:hover {
            background: #fafbff;
        }

        .status {
            display: inline-block;
            padding: 6px 11px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
        }

        .present {
            background: #e3f8ec;
            color: #177b4c;
        }

        .absent {
            background: #ffebeb;
            color: #b63131;
        }

        .empty,
        .error {
            padding: 22px;
            text-align: center;
        }

        .empty {
            color: #748198;
        }

        .error {
            color: #b63131;
            background: #fff5f5;
        }

        .footer {
            padding: 20px 0 5px;
            color: #96a1b3;
            font-size: 11px;
            text-align: center;
        }

        @media (max-width: 950px) {
            .filters {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 520px) {
            body {
                padding: 18px 12px;
            }

            h1 {
                font-size: 23px;
            }

            .panel {
                padding: 16px;
            }

            .filters {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body>
<div class="container">

    <header class="header">
        <div>
            <h1>Attendance Report</h1>
            <p class="subtitle">
                Search and review saved student attendance records.
            </p>
        </div>

        <a class="home-button" href="index.jsp">
            &larr; Back to Dashboard
        </a>
    </header>

    <section class="panel">
        <h2 class="panel-title">Search and Filter Records</h2>

        <form action="viewReport.jsp" method="get" class="filters">

            <div>
                <label for="search">Student Name or Roll Number</label>
                <input
                    id="search"
                    type="text"
                    name="search"
                    placeholder="Enter name or roll number"
                    value="<%= safeSearch %>">
            </div>

            <div>
                <label for="date">Attendance Date</label>
                <input
                    id="date"
                    type="date"
                    name="date"
                    value="<%= safeDate %>">
            </div>

            <div>
                <label for="status">Attendance Status</label>
                <select id="status" name="status">
                    <option value="">All statuses</option>
                    <option value="Present"
                        <%= "Present".equals(statusFilter)
                            ? "selected" : "" %>>
                        Present
                    </option>
                    <option value="Absent"
                        <%= "Absent".equals(statusFilter)
                            ? "selected" : "" %>>
                        Absent
                    </option>
                </select>
            </div>

            <button type="submit" class="button search-button">
                Search
            </button>

            <a href="viewReport.jsp" class="button reset-button">
                Reset
            </a>

        </form>
    </section>

    <section class="panel">
        <h2 class="panel-title">Attendance Records</h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Roll Number</th>
                        <th>Student Name</th>
                        <th>Course</th>
                        <th>Semester</th>
                        <th>Attendance Date</th>
                        <th>Status</th>
                    </tr>
                </thead>

                <tbody>

                <%
                    if (errorMessage == null) {
                        try (
                            Connection con = DBConnection.getConnection();
                            PreparedStatement ps =
                                con.prepareStatement(sql.toString())
                        ) {
                            int index = 1;

                            if (!search.isEmpty()) {
                                String pattern = "%" + search + "%";
                                ps.setString(index++, pattern);
                                ps.setString(index++, pattern);
                            }

                            if (filterDate != null) {
                                ps.setDate(index++, filterDate);
                            }

                            if (!statusFilter.isEmpty()) {
                                ps.setString(index++, statusFilter);
                            }

                            try (ResultSet rs = ps.executeQuery()) {
                                while (rs.next()) {
                                    found = true;

                                    String roll = rs.getString("roll_no");
                                    String name = rs.getString("name");
                                    String course = rs.getString("course");
                                    String rowStatus = rs.getString("status");

                                    if (roll == null) roll = "";
                                    if (name == null) name = "";
                                    if (course == null) course = "";
                                    if (rowStatus == null) rowStatus = "";

                                    String safeRoll = roll
                                        .replace("&", "&amp;")
                                        .replace("<", "&lt;")
                                        .replace(">", "&gt;")
                                        .replace("\"", "&quot;")
                                        .replace("'", "&#39;");

                                    String safeName = name
                                        .replace("&", "&amp;")
                                        .replace("<", "&lt;")
                                        .replace(">", "&gt;")
                                        .replace("\"", "&quot;")
                                        .replace("'", "&#39;");

                                    String safeCourse = course
                                        .replace("&", "&amp;")
                                        .replace("<", "&lt;")
                                        .replace(">", "&gt;")
                                        .replace("\"", "&quot;")
                                        .replace("'", "&#39;");

                                    String safeStatus = rowStatus
                                        .replace("&", "&amp;")
                                        .replace("<", "&lt;")
                                        .replace(">", "&gt;")
                                        .replace("\"", "&quot;")
                                        .replace("'", "&#39;");

                                    String statusClass =
                                        "Present".equals(rowStatus)
                                        ? "present" : "absent";
                %>

                    <tr>
                        <td><%= safeRoll %></td>
                        <td><%= safeName %></td>
                        <td><%= safeCourse %></td>
                        <td><%= rs.getInt("semester") %></td>
                        <td><%= rs.getDate("attendance_date") %></td>
                        <td>
                            <span class="status <%= statusClass %>">
                                <%= safeStatus %>
                            </span>
                        </td>
                    </tr>

                <%
                                }
                            }
                        } catch (Exception e) {
                            application.log(
                                "Unable to load attendance report", e
                            );
                            errorMessage =
                                "Unable to load the report. Please check the database connection.";
                        }
                    }

                    if (errorMessage != null) {
                %>

                    <tr>
                        <td colspan="6" class="error">
                            <%= errorMessage %>
                        </td>
                    </tr>

                <%
                    } else if (!found) {
                %>

                    <tr>
                        <td colspan="6" class="empty">
                            No attendance records found for the selected filters.
                        </td>
                    </tr>

                <%
                    }
                %>

                </tbody>
            </table>
        </div>
    </section>

    <footer class="footer">
        Student Attendance Management System | Academic Project
    </footer>

</div>
</body>
</html>