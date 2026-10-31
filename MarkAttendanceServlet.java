package com.attendance;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/markAttendance")
public class MarkAttendanceServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        String rollNo = request.getParameter("rollNo");
        String dateValue = request.getParameter("date");
        String status = request.getParameter("status");

        String home = request.getContextPath() + "/index.jsp";
        String form = request.getContextPath() + "/markAttendance.jsp";

        try {
            // Validate form inputs
            if (rollNo == null || rollNo.trim().isEmpty()
                    || dateValue == null || dateValue.trim().isEmpty()
                    || status == null
                    || !(status.equals("Present")
                         || status.equals("Absent"))) {

                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().println(
                    "<h2>Please enter valid attendance details.</h2>");
                response.getWriter().println(
                    "<a href='" + form + "'>Go Back</a>");
                return;
            }

            LocalDate localDate;

            try {
                localDate = LocalDate.parse(dateValue);
            } catch (DateTimeParseException e) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().println(
                    "<h2>Invalid date format. Please use YYYY-MM-DD.</h2>");
                response.getWriter().println(
                    "<a href='" + form + "'>Go Back</a>");
                return;
            }

            try (Connection con = DBConnection.getConnection()) {

                // Find the student using the roll number
                String findStudent =
                    "SELECT student_id FROM students WHERE roll_no = ?";

                int studentId;

                try (PreparedStatement ps =
                         con.prepareStatement(findStudent)) {

                    ps.setString(1, rollNo.trim());

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            response.getWriter().println(
                                "<h2>Student not found. Check the roll number.</h2>");
                            response.getWriter().println(
                                "<a href='" + form + "'>Go Back</a>");
                            return;
                        }

                        studentId = rs.getInt("student_id");
                    }
                }

                // Prevent duplicate attendance for the same student and date
                String checkDuplicate =
                    "SELECT attendance_id FROM attendance "
                    + "WHERE student_id = ? AND attendance_date = ?";

                try (PreparedStatement ps =
                         con.prepareStatement(checkDuplicate)) {

                    ps.setInt(1, studentId);
                    ps.setDate(2, Date.valueOf(localDate));

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            response.getWriter().println(
                                "<h2>Attendance already recorded for this student on this date.</h2>");
                            response.getWriter().println(
                                "<a href='" + form + "'>Go Back</a>");
                            return;
                        }
                    }
                }

                // Save the attendance record
                String insertAttendance =
                    "INSERT INTO attendance "
                    + "(student_id, attendance_date, status) "
                    + "VALUES (?, ?, ?)";

                try (PreparedStatement ps =
                         con.prepareStatement(insertAttendance)) {

                    ps.setInt(1, studentId);
                    ps.setDate(2, Date.valueOf(localDate));
                    ps.setString(3, status);
                    ps.executeUpdate();
                }
            }

            response.getWriter().println(
                "<h2>Attendance Marked Successfully!</h2>");
            response.getWriter().println(
                "<a href='" + home + "'>Go to Dashboard</a>");

        } catch (Exception e) {
            getServletContext().log("Unable to mark attendance", e);
            response.setStatus(
                HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().println(
                "<h2>Unable to mark attendance. Please try again.</h2>");
            response.getWriter().println(
                "<a href='" + form + "'>Go Back</a>");
        }
    }
}