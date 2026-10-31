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

@WebServlet("/studentRegister")
public class StudentRegisterServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String rollNo = request.getParameter("rollNo");
        String name = request.getParameter("name");
        String password = request.getParameter("password");
        String confirmPassword =
                request.getParameter("confirmPassword");

        rollNo = rollNo == null ? "" : rollNo.trim();
        name = name == null ? "" : name.trim();

        if (rollNo.isEmpty() || name.isEmpty()
                || password == null || password.isEmpty()
                || confirmPassword == null
                || confirmPassword.isEmpty()) {

            showError(request, response,
                    "Please fill in all fields.");
            return;
        }

        if (password.length() < 8) {
            showError(request, response,
                    "Password must contain at least 8 characters.");
            return;
        }

        if (!password.equals(confirmPassword)) {
            showError(request, response,
                    "Passwords do not match.");
            return;
        }

        try (Connection con = DBConnection.getConnection()) {

            int studentId;

            String findStudent =
                    "SELECT student_id FROM students "
                    + "WHERE roll_no = ? AND LOWER(name) = LOWER(?)";

            try (PreparedStatement ps =
                         con.prepareStatement(findStudent)) {

                ps.setString(1, rollNo);
                ps.setString(2, name);

                try (ResultSet rs = ps.executeQuery()) {

                    if (!rs.next()) {
                        showError(request, response,
                                "Student details do not match our records.");
                        return;
                    }

                    studentId = rs.getInt("student_id");
                }
            }

            String checkAccount =
                    "SELECT student_id FROM student_accounts "
                    + "WHERE student_id = ?";

            try (PreparedStatement ps =
                         con.prepareStatement(checkAccount)) {

                ps.setInt(1, studentId);

                try (ResultSet rs = ps.executeQuery()) {

                    if (rs.next()) {
                        showError(request, response,
                                "An account already exists for this student.");
                        return;
                    }
                }
            }

            String salt = PasswordUtil.generateSalt();

            String passwordHash =
                    PasswordUtil.hashPassword(password, salt);

            String insert =
                    "INSERT INTO student_accounts "
                    + "(student_id, password_hash, password_salt) "
                    + "VALUES (?, ?, ?)";

            try (PreparedStatement ps =
                         con.prepareStatement(insert)) {

                ps.setInt(1, studentId);
                ps.setString(2, passwordHash);
                ps.setString(3, salt);

                ps.executeUpdate();
            }

            response.sendRedirect(
                    request.getContextPath()
                    + "/studentLogin.jsp?registered=1");

        } catch (Exception e) {

            getServletContext().log(
                    "Student registration failed", e);

            showError(request, response,
                    "Registration could not be completed. Please try again.");
        }
    }

    private void showError(
            HttpServletRequest request,
            HttpServletResponse response,
            String message)
            throws ServletException, IOException {

        request.setAttribute("error", message);

        request.getRequestDispatcher(
                "/studentRegister.jsp").forward(request, response);
    }
}