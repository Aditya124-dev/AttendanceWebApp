
package com.attendance;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

@WebServlet("/addStudent")
public class StudentServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        // Teacher-only authorization
        HttpSession session = request.getSession(false);

        if (session == null
                || !(session.getAttribute("teacherId") instanceof Integer)
                || !"TEACHER".equals(session.getAttribute("userRole"))) {

            response.sendError(HttpServletResponse.SC_UNAUTHORIZED,
                    "Please login as a teacher to add students.");
            return;
        }

        String rollNo = trim(request.getParameter("rollNo"));
        String name = trim(request.getParameter("name"));
        String course = trim(request.getParameter("course"));
        String semesterText = trim(request.getParameter("semester"));
        String email = trim(request.getParameter("email"));
        String phone = trim(request.getParameter("phone"));

        if (rollNo.isEmpty() || name.isEmpty()
                || course.isEmpty() || semesterText.isEmpty()
                || email.isEmpty() || phone.isEmpty()) {

            showMessage(response, HttpServletResponse.SC_BAD_REQUEST,
                    "All fields are required.");
            return;
        }

        // Match existing database column limits.
        if (rollNo.length() > 20 || name.length() > 100
                || course.length() > 50 || email.length() > 150
                || phone.length() > 20) {

            showMessage(response, HttpServletResponse.SC_BAD_REQUEST,
                    "One or more fields exceed the allowed length.");
            return;
        }

        // No 12/13-digit minimum: existing short roll numbers remain valid.
        if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
            showMessage(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Please enter a valid email address.");
            return;
        }

        if (!phone.matches("[0-9]{10}")) {
            showMessage(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Please enter a valid 10-digit mobile number.");
            return;
        }

        int semester;

        try {
            semester = Integer.parseInt(semesterText);

            if (semester < 1) {
                showMessage(response, HttpServletResponse.SC_BAD_REQUEST,
                        "Semester must be at least 1.");
                return;
            }

        } catch (NumberFormatException e) {
            showMessage(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Please enter a valid semester.");
            return;
        }

        String sql = "INSERT INTO students "
                + "(roll_no, name, course, semester, email, phone) "
                + "VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, rollNo);
            ps.setString(2, name);
            ps.setString(3, course);
            ps.setInt(4, semester);
            ps.setString(5, email);
            ps.setString(6, phone);

            int result = ps.executeUpdate();

            if (result > 0) {
                showMessage(response, HttpServletResponse.SC_OK,
                        "Student added successfully.");
            } else {
                showMessage(response,
                        HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                        "Student could not be added.");
            }

        } catch (SQLException e) {
            getServletContext().log("Unable to add student.", e);

            if ("23000".equals(e.getSQLState())) {
                showMessage(response, HttpServletResponse.SC_CONFLICT,
                        "This roll number may already be registered.");
            } else {
                showMessage(response,
                        HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                        "Database operation failed. Please check the server log.");
            }

        } catch (Exception e) {
            getServletContext().log("Student registration failed.", e);

            showMessage(response,
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Student registration failed. Please check the server log.");
        }
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private void showMessage(HttpServletResponse response,
                             int status,
                             String message) throws IOException {

        response.setStatus(status);
        response.setContentType("text/html;charset=UTF-8");

        response.getWriter().println(
                "<!DOCTYPE html>"
                + "<html><head><meta charset='UTF-8'>"
                + "<title>Student Registration</title></head>"
                + "<body style='font-family:Arial,sans-serif;"
                + "text-align:center;margin:60px;'>"
                + "<h2>" + escapeHtml(message) + "</h2>"
                + "<p><a href='addStudent.jsp'>Back to Add Student</a></p>"
                + "<p><a href='teacherDashboard.jsp'>Teacher Dashboard</a></p>"
                + "</body></html>");
    }

    private String escapeHtml(String value) {
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#x27;");
    }
}
