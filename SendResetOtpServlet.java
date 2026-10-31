
package com.attendance;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Base64;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/sendResetOtp")
public class SendResetOtpServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final SecureRandom RANDOM = new SecureRandom();

    private static final long OTP_VALIDITY = 5 * 60 * 1000L;
    private static final long RESEND_WAIT = 60 * 1000L;

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String email = request.getParameter("email");

        if (email == null || email.trim().isEmpty()
                || email.length() > 150) {

            request.setAttribute("error",
                    "Please enter a valid registered email address.");

            request.getRequestDispatcher(
                    "/forgotPassword.jsp").forward(request, response);
            return;
        }

        email = email.trim().toLowerCase();

        HttpSession session = request.getSession(true);

        try {
            Object lastRequest =
                    session.getAttribute("resetLastRequest");

            if (lastRequest instanceof Long) {
                long elapsed = System.currentTimeMillis()
                        - (Long) lastRequest;

                if (elapsed < RESEND_WAIT) {
                    request.setAttribute("otpSent", true);
                    request.setAttribute("message",
                            "Please wait before requesting another OTP.");

                    request.getRequestDispatcher(
                            "/forgotPassword.jsp")
                            .forward(request, response);
                    return;
                }
            }

            // Remove any previous reset attempt.
            clearResetSession(session);

            session.setAttribute(
                    "resetLastRequest", System.currentTimeMillis());

            int studentId = 0;
            String registeredEmail = null;

            String sql =
                    "SELECT student_id, email FROM students "
                    + "WHERE LOWER(TRIM(email)) = ? LIMIT 2";

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(sql)) {

                ps.setString(1, email);

                try (ResultSet rs = ps.executeQuery()) {

                    if (rs.next()) {
                        studentId = rs.getInt("student_id");
                        registeredEmail = rs.getString("email");

                        // Do not send OTP if the email is shared
                        // by multiple student records.
                        if (rs.next()) {
                            studentId = 0;
                            registeredEmail = null;
                        }
                    }
                }
            }

            if (studentId > 0 && registeredEmail != null) {

                int otpNumber = RANDOM.nextInt(900000) + 100000;
                String otp = String.valueOf(otpNumber);

                byte[] saltBytes = new byte[16];
                RANDOM.nextBytes(saltBytes);

                String salt = Base64.getEncoder()
                        .encodeToString(saltBytes);

                String otpHash = hashOtp(otp, salt);

                // Send email before activating the OTP.
                EmailUtil.sendOtp(registeredEmail, otp);

                session.setAttribute("resetStudentId", studentId);
                session.setAttribute("resetOtpHash", otpHash);
                session.setAttribute("resetOtpSalt", salt);
                session.setAttribute(
                        "resetOtpExpiry",
                        System.currentTimeMillis() + OTP_VALIDITY);
                session.setAttribute("resetOtpAttempts", 0);
            }

            // Same response whether the email exists or not.
            request.setAttribute("otpSent", true);
            request.setAttribute("message",
                    "If an account is registered with this email, "
                    + "an OTP has been sent. Check your inbox.");

        } catch (Exception e) {

            getServletContext().log(
                    "Password reset OTP request failed", e);

            clearResetSession(session);

            request.setAttribute("error",
                    "Unable to process your request right now. "
                    + "Please try again later.");
        }

        request.getRequestDispatcher(
                "/forgotPassword.jsp").forward(request, response);
    }

    private static String hashOtp(String otp, String salt)
            throws Exception {

        MessageDigest digest =
                MessageDigest.getInstance("SHA-256");

        digest.update(
                Base64.getDecoder().decode(salt));

        byte[] hash = digest.digest(
                otp.getBytes(StandardCharsets.UTF_8));

        return Base64.getEncoder().encodeToString(hash);
    }

    private static void clearResetSession(HttpSession session) {

        session.removeAttribute("resetStudentId");
        session.removeAttribute("resetOtpHash");
        session.removeAttribute("resetOtpSalt");
        session.removeAttribute("resetOtpExpiry");
        session.removeAttribute("resetOtpAttempts");
    }
}
