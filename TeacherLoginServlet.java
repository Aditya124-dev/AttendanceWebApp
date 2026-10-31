
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

@WebServlet("/teacherLogin")
public class TeacherLoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String teacherCode = request.getParameter("teacherCode");
        String password = request.getParameter("password");

        teacherCode = teacherCode == null ? "" : teacherCode.trim();

        if (teacherCode.isEmpty() || password == null || password.isEmpty()) {
            showError(request, response, "Please enter teacher code and password.");
            return;
        }

        String sql =
            "SELECT t.teacher_id, t.name, a.password_hash, a.password_salt " +
            "FROM teachers t " +
            "JOIN teacher_accounts a ON t.teacher_id = a.teacher_id " +
            "WHERE t.teacher_code = ? AND t.is_active = 1";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, teacherCode);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    showError(request, response, "Invalid teacher code or password.");
                    return;
                }

                int teacherId = rs.getInt("teacher_id");
                String teacherName = rs.getString("name");
                String storedHash = rs.getString("password_hash");
                String salt = rs.getString("password_salt");

                boolean valid = PasswordUtil.verifyPassword(
                    password, salt, storedHash
                );

                if (!valid) {
                    showError(request, response, "Invalid teacher code or password.");
                    return;
                }

                HttpSession session = request.getSession(true);
                request.changeSessionId();

                session.setAttribute("teacherId", teacherId);
                session.setAttribute("teacherName", teacherName);
                session.setAttribute("userRole", "TEACHER");

                response.sendRedirect(
                    request.getContextPath() + "/teacherDashboard.jsp"
                );
            }

        } catch (Exception e) {
            getServletContext().log("Teacher login failed", e);
            showError(request, response,
                "Login could not be completed. Please try again.");
        }
    }

    private void showError(HttpServletRequest request,
                           HttpServletResponse response,
                           String message)
            throws ServletException, IOException {

        request.setAttribute("error", message);
        request.getRequestDispatcher("/teacherLogin.jsp")
               .forward(request, response);
    }
}
