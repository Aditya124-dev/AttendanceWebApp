package com.attendance;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/studentLogin")
public class StudentLoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String rollNo = request.getParameter("rollNo");
        String password = request.getParameter("password");

        rollNo = rollNo == null ? "" : rollNo.trim();

        if (rollNo.isEmpty()
                || password == null
                || password.isEmpty()) {

            showError(request, response,
                    "Enter your roll number and password.");
            return;
        }

        try (Connection con = DBConnection.getConnection()) {

            String sql =
                    "SELECT s.student_id, s.name, s.roll_no, "
                    + "a.password_hash, a.password_salt "
                    + "FROM students s "
                    + "JOIN student_accounts a "
                    + "ON s.student_id = a.student_id "
                    + "WHERE s.roll_no = ?";

            int studentId;
            String studentName;
            String storedHash;
            String salt;

            try (PreparedStatement ps =
                         con.prepareStatement(sql)) {

                ps.setString(1, rollNo);

                try (ResultSet rs = ps.executeQuery()) {

                    if (!rs.next()) {
                        showError(request, response,
                                "Invalid roll number or password.");
                        return;
                    }

                    studentId = rs.getInt("student_id");
                    studentName = rs.getString("name");
                    storedHash = rs.getString("password_hash");
                    salt = rs.getString("password_salt");
                }
            }

            if (!PasswordUtil.verifyPassword(
                    password, salt, storedHash)) {

                showError(request, response,
                        "Invalid roll number or password.");
                return;
            }

            // Prevent session fixation after successful login.
            HttpSession oldSession = request.getSession(false);

            if (oldSession != null) {
                oldSession.invalidate();
            }

            HttpSession session = request.getSession(true);

            session.setAttribute("studentId", studentId);
            session.setAttribute("studentName", studentName);
            session.setAttribute("studentRollNo", rollNo);

            session.setMaxInactiveInterval(30 * 60);

            response.sendRedirect(
                    request.getContextPath()
                    + "/studentProfile.jsp");

        } catch (Exception e) {

            getServletContext().log("Student login failed", e);

            showError(request, response,
                    "Login is temporarily unavailable. Please try again.");
        }
    }

    private void showError(
            HttpServletRequest request,
            HttpServletResponse response,
            String message)
            throws ServletException, IOException {

        request.setAttribute("error", message);

        request.getRequestDispatcher(
                "/studentLogin.jsp").forward(request, response);
    }
}