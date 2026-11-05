
package com.attendance;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/resetPassword")
public class ResetPasswordServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null
                || !Boolean.TRUE.equals(
                        session.getAttribute("resetOtpVerified"))
                || !(session.getAttribute("resetStudentId")
                        instanceof Integer)) {

            request.setAttribute("error",
                    "Please verify your OTP before resetting your password.");

            request.getRequestDispatcher(
                    "/forgotPassword.jsp").forward(request, response);
            return;
        }

        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        if (newPassword == null || confirmPassword == null
                || newPassword.length() < 8
                || newPassword.length() > 72) {

            showError(request, response,
                    "Password must contain 8 to 72 characters.");
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            showError(request, response,
                    "New password and confirm password do not match.");
            return;
        }

        int studentId =
                (Integer) session.getAttribute("resetStudentId");

        try {
            String salt = PasswordUtil.generateSalt();

            String passwordHash =
                    PasswordUtil.hashPassword(newPassword, salt);

            String sql =
                    "UPDATE student_accounts "
                    + "SET password_hash = ?, password_salt = ? "
                    + "WHERE student_id = ?";

            int updatedRows;

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(sql)) {

                ps.setString(1, passwordHash);
                ps.setString(2, salt);
                ps.setInt(3, studentId);

                updatedRows = ps.executeUpdate();
            }

            if (updatedRows != 1) {
                showError(request, response,
                        "Password could not be updated. Please try again.");
                return;
            }

            // Invalidate the OTP/reset session after successful update.
            session.invalidate();

            request.setAttribute("success",
                    "Password reset successfully. Please login with your new password.");

            request.getRequestDispatcher(
                    "/studentLogin.jsp").forward(request, response);

        } catch (Exception e) {

            getServletContext().log(
                    "Student password reset failed", e);

            showError(request, response,
                    "Unable to reset password right now. Please try again.");
        }
    }

    private void showError(
            HttpServletRequest request,
            HttpServletResponse response,
            String message)
            throws ServletException, IOException {

        request.setAttribute("otpSent", true);
        request.setAttribute("otpVerified", true);
        request.setAttribute("error", message);

        request.getRequestDispatcher(
                "/forgotPassword.jsp").forward(request, response);
    }
}
