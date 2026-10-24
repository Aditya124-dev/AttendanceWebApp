<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="com.attendance.DBConnection" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Attendance Summary</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 30px;
            background: #f4f6f9;
        }

        h1 { color: #243b55; }

        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }

        th, td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }

        th {
            background: #243b55;
            color: white;
        }
    </style>
</head>
<body>

<h1>Student Attendance Percentage</h1>
<p><a href="index.jsp">Back to Home</a></p>

<table>
    <tr>
        <th>Roll No.</th>
        <th>Name</th>
        <th>Course</th>
        <th>Total Days</th>
        <th>Present</th>
        <th>Absent</th>
        <th>Attendance %</th>
    </tr>

<%
    String sql =
        "SELECT s.roll_no, s.name, s.course, " +
        "COUNT(a.attendance_id) AS total_days, " +
        "COALESCE(SUM(CASE WHEN a.status='Present' " +
        "THEN 1 ELSE 0 END), 0) AS present_days, " +
        "COALESCE(SUM(CASE WHEN a.status='Absent' " +
        "THEN 1 ELSE 0 END), 0) AS absent_days " +
        "FROM students s " +
        "LEFT JOIN attendance a ON s.student_id=a.student_id " +
        "GROUP BY s.student_id, s.roll_no, s.name, s.course " +
        "ORDER BY s.name";

    try (
        Connection con = DBConnection.getConnection();
        PreparedStatement ps = con.prepareStatement(sql);
        ResultSet rs = ps.executeQuery()
    ) {
        while (rs.next()) {
            int total = rs.getInt("total_days");
            int present = rs.getInt("present_days");
            int absent = rs.getInt("absent_days");

            double percentage = total == 0
                    ? 0.0
                    : (present * 100.0 / total);
%>

    <tr>
        <td><%= rs.getString("roll_no") %></td>
        <td><%= rs.getString("name") %></td>
        <td><%= rs.getString("course") %></td>
        <td><%= total %></td>
        <td><%= present %></td>
        <td><%= absent %></td>
        <td><%= String.format("%.2f%%", percentage) %></td>
    </tr>

<%
        }
    } catch (Exception e) {
%>
    <tr>
        <td colspan="7">
            Unable to load summary: <%= e.getMessage() %>
        </td>
    </tr>
<%
    }
%>

</table>

</body>
</html>