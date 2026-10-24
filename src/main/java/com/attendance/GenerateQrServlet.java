package com.attendance;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.net.URLEncoder;

@WebServlet("/generateQr")
public class GenerateQrServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        try {
            // Generate a random token
            byte[] randomBytes = new byte[32];
            new SecureRandom().nextBytes(randomBytes);

            String token = Base64.getUrlEncoder()
                    .withoutPadding()
                    .encodeToString(randomBytes);

            // Store only the SHA-256 hash in the database
            byte[] hashBytes = MessageDigest
                    .getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8));

            String tokenHash = HexFormat
                    .of()
                    .formatHex(hashBytes);

            try (Connection con = DBConnection.getConnection()) {

                con.setAutoCommit(false);

                try {
                    // Deactivate earlier QR sessions
                    String deactivateSql =
                            "UPDATE attendance_qr_sessions "
                            + "SET is_active = 0 WHERE is_active = 1";

                    try (PreparedStatement ps =
                                 con.prepareStatement(deactivateSql)) {
                        ps.executeUpdate();
                    }

                    // Create a new QR session that expires in 10 minutes
                    String insertSql =
                            "INSERT INTO attendance_qr_sessions "
                            + "(token_hash, attendance_date, expires_at, is_active) "
                            + "VALUES (?, CURDATE(), "
                            + "DATE_ADD(NOW(), INTERVAL 10 MINUTE), 1)";

                    try (PreparedStatement ps =
                                 con.prepareStatement(insertSql)) {

                        
                        // The token hash is stored, never the plain token.
                        ps.setString(1, tokenHash);
                        ps.executeUpdate();
                    }

                    con.commit();

                } catch (Exception e) {
                    con.rollback();
                    throw e;
                }
            }

            // Build the URL that the student's phone will open
            String baseUrl = request.getScheme()
                    + "://"
                    + request.getServerName()
                    + ":"
                    + request.getServerPort()
                    + request.getContextPath();

            String qrUrl = baseUrl
                    + "/qrCheckIn?token="
                    + URLEncoder.encode(
                            token, StandardCharsets.UTF_8);

            request.setAttribute("qrUrl", qrUrl);
            request.setAttribute("expiresMinutes", 10);

            request.getRequestDispatcher(
                    "/adminQr.jsp").forward(request, response);

        } catch (Exception e) {
            getServletContext().log(
                    "Unable to generate attendance QR code", e);

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR);

            response.getWriter().println(
                    "<h2>Unable to generate QR code.</h2>");
            response.getWriter().println(
                    "<a href='index.jsp'>Back to Dashboard</a>");
        }
    }
}