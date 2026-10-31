
package com.attendance;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/verifyResetOtp")
public class VerifyResetOtpServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int MAX_ATTEMPTS = 5;

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("resetStudentId") == null
                || session.getAttribute("resetOtpHash") == null) {

            request.setAttribute("error",
                    "Your OTP session has expired. Please request a new OTP.");

            request.getRequestDispatcher(
                    "/forgotPassword.jsp").forward(request, response);
            return;
        }

        String otp = request.getParameter("otp");

        if (otp == null || !otp.matches("[0-9]{6}")) {
            showOtpError(request, response,
                    "Enter a valid 6-digit OTP.");
            return;
        }

        try {
            Object expiryObject =
                    session.getAttribute("resetOtpExpiry");

            if (!(expiryObject instanceof Long)
                    || System.currentTimeMillis()
                    > (Long) expiryObject) {

                clearOtpSession(session);

                request.setAttribute("error",
                        "OTP has expired. Please request a new OTP.");

                request.getRequestDispatcher(
                        "/forgotPassword.jsp").forward(request, response);
                return;
            }

            int attempts = 0;
            Object attemptsObject =
                    session.getAttribute("resetOtpAttempts");

            if (attemptsObject instanceof Integer) {
                attempts = (Integer) attemptsObject;
            }

            if (attempts >= MAX_ATTEMPTS) {
                clearOtpSession(session);

                request.setAttribute("error",
                        "Too many incorrect attempts. Please request a new OTP.");

                request.getRequestDispatcher(
                        "/forgotPassword.jsp").forward(request, response);
                return;
            }

            String storedHash =
                    (String) session.getAttribute("resetOtpHash");

            String salt =
                    (String) session.getAttribute("resetOtpSalt");

            String calculatedHash = hashOtp(otp, salt);

            byte[] actual = Base64.getDecoder()
                    .decode(calculatedHash);

            byte[] expected = Base64.getDecoder()
                    .decode(storedHash);

            if (!MessageDigest.isEqual(actual, expected)) {

                attempts++;

                session.setAttribute("resetOtpAttempts", attempts);

                if (attempts >= MAX_ATTEMPTS) {
                    clearOtpSession(session);

                    request.setAttribute("error",
                            "Too many incorrect attempts. Please request a new OTP.");
                } else {
                    request.setAttribute("otpSent", true);
                    request.setAttribute("error",
                            "Incorrect OTP. Attempts remaining: "
                            + (MAX_ATTEMPTS - attempts));
                }

                request.getRequestDispatcher(
                        "/forgotPassword.jsp").forward(request, response);
                return;
            }

            // OTP verified successfully.
            session.setAttribute("resetOtpVerified", true);

            session.removeAttribute("resetOtpHash");
            session.removeAttribute("resetOtpSalt");
            session.removeAttribute("resetOtpExpiry");
            session.removeAttribute("resetOtpAttempts");

            request.setAttribute("otpSent", true);
            request.setAttribute("otpVerified", true);
            request.setAttribute("message",
                    "OTP verified successfully. Set your new password.");

            request.getRequestDispatcher(
                    "/forgotPassword.jsp").forward(request, response);

        } catch (Exception e) {

            getServletContext().log(
                    "OTP verification failed", e);

            request.setAttribute("error",
                    "Unable to verify OTP. Please try again.");

            request.getRequestDispatcher(
                    "/forgotPassword.jsp").forward(request, response);
        }
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

    private static void clearOtpSession(HttpSession session) {

        session.removeAttribute("resetStudentId");
        session.removeAttribute("resetOtpHash");
        session.removeAttribute("resetOtpSalt");
        session.removeAttribute("resetOtpExpiry");
        session.removeAttribute("resetOtpAttempts");
        session.removeAttribute("resetOtpVerified");
    }

    private void showOtpError(
            HttpServletRequest request,
            HttpServletResponse response,
            String message)
            throws ServletException, IOException {

        request.setAttribute("otpSent", true);
        request.setAttribute("error", message);

        request.getRequestDispatcher(
                "/forgotPassword.jsp").forward(request, response);
    }
}
