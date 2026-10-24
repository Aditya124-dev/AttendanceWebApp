
package com.attendance;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HexFormat;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/qrCheckIn")
public class QrCheckInServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private String escapeHtml(String value) {
        if (value == null) return "";

        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }

    private void showMessage(
            HttpServletResponse response,
            int status,
            String title,
            String message,
            String contextPath) throws IOException {

        response.setStatus(status);
        response.setContentType("text/html;charset=UTF-8");
        response.setHeader("Cache-Control", "no-store");

        response.getWriter().println(
            "<!DOCTYPE html><html><head><meta charset='UTF-8'>"
            + "<meta name='viewport' content='width=device-width,initial-scale=1'>"
            + "<title>QR Attendance</title>"
            + "<style>body{font-family:Arial;background:#f1f5fc;"
            + "padding:25px;color:#192746}"
            + ".card{max-width:480px;margin:50px auto;background:white;"
            + "padding:28px;border-radius:16px;text-align:center;"
            + "box-shadow:0 8px 25px #0001}"
            + "a{display:inline-block;margin-top:18px;padding:12px 18px;"
            + "background:#4357dc;color:white;text-decoration:none;"
            + "border-radius:8px}</style></head><body><div class='card'>"
            + "<h2>" + escapeHtml(title) + "</h2>"
            + "<p>" + escapeHtml(message) + "</p>"
            + "<a href='" + escapeHtml(contextPath)
            + "/index.jsp'>Go to Dashboard</a>"
            + "</div></body></html>"
        );
    }

    private boolean isLoggedIn(HttpSession session) {
        return session != null
            && session.getAttribute("studentId") instanceof Integer;
    }

    private String hashToken(String token) throws Exception {
        byte[] bytes = MessageDigest.getInstance("SHA-256")
            .digest(token.getBytes(StandardCharsets.UTF_8));

        return HexFormat.of().formatHex(bytes);
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        HttpSession session = request.getSession(false);

        if (!isLoggedIn(session)) {
            request.setAttribute(
                "error",
                "Please sign in first, then scan the QR code again."
            );

            request.getRequestDispatcher("/studentLogin.jsp")
                   .forward(request, response);
            return;
        }

        String token = request.getParameter("token");

        if (token == null || !token.matches("[A-Za-z0-9_-]{40,50}")) {
            showMessage(response, 400,
                "Invalid QR Code",
                "Please scan a valid attendance QR code.",
                request.getContextPath());
            return;
        }

        try (Connection con = DBConnection.getConnection()) {

            String sql =
                "SELECT attendance_date FROM attendance_qr_sessions "
                + "WHERE token_hash=? AND is_active=1 "
                + "AND expires_at > NOW()";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, hashToken(token));

                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        showMessage(response, 400,
                            "QR Code Expired",
                            "This QR session is invalid or expired. Ask the administrator for a new code.",
                            request.getContextPath());
                        return;
                    }
                }
            }

            String studentName =
                (String) session.getAttribute("studentName");

            response.setContentType("text/html;charset=UTF-8");

            response.getWriter().println(
                "<!DOCTYPE html><html lang='en'><head>"
                + "<meta charset='UTF-8'>"
                + "<meta name='viewport' content='width=device-width,initial-scale=1'>"
                + "<title>Confirm Attendance</title>"
                + "<style>body{font-family:Arial;background:#f1f5fc;"
                + "padding:20px;color:#192746}"
                + ".card{max-width:450px;margin:40px auto;padding:28px;"
                + "background:white;border-radius:18px;text-align:center;"
                + "box-shadow:0 8px 25px #0001}"
                + "button{padding:14px 20px;background:#4357dc;color:white;"
                + "border:0;border-radius:9px;font-size:15px;cursor:pointer}"
                + "p{color:#758198;line-height:1.7}</style>"
                + "</head><body><div class='card'>"
                + "<h2>Confirm Attendance</h2>"
                + "<p>Student: <strong>"
                + escapeHtml(studentName)
                + "</strong></p>"
                + "<p>Confirm to record your attendance for this QR session.</p>"
                + "<form method='post' action='"
                + escapeHtml(request.getContextPath())
                + "/qrCheckIn'>"
                + "<input type='hidden' name='token' value='"
                + escapeHtml(token) + "'>"
                + "<button type='submit'>Confirm Attendance</button>"
                + "</form></div></body></html>"
            );

        } catch (Exception e) {
            getServletContext().log("QR validation failed", e);

            showMessage(response, 500,
                "Unable to Check QR",
                "Please try again or ask the administrator for help.",
                request.getContextPath());
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        HttpSession session = request.getSession(false);

        if (!isLoggedIn(session)) {
            response.sendRedirect(
                request.getContextPath() + "/studentLogin.jsp");
            return;
        }

        String token = request.getParameter("token");

        if (token == null || !token.matches("[A-Za-z0-9_-]{40,50}")) {
            showMessage(response, 400,
                "Invalid QR Code",
                "Please scan a valid QR code.",
                request.getContextPath());
            return;
        }

        int studentId = (Integer) session.getAttribute("studentId");

        try (Connection con = DBConnection.getConnection()) {

            con.setAutoCommit(false);

            try {
                Date attendanceDate;

                String qrSql =
                    "SELECT attendance_date FROM attendance_qr_sessions "
                    + "WHERE token_hash=? AND is_active=1 "
                    + "AND expires_at > NOW() FOR UPDATE";

                try (PreparedStatement ps = con.prepareStatement(qrSql)) {
                    ps.setString(1, hashToken(token));

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            con.rollback();

                            showMessage(response, 400,
                                "QR Code Expired",
                                "This QR session is no longer active. Ask for a new code.",
                                request.getContextPath());
                            return;
                        }

                        attendanceDate = rs.getDate("attendance_date");
                    }
                }

                String duplicateSql =
                    "SELECT attendance_id FROM attendance "
                    + "WHERE student_id=? AND attendance_date=?";

                try (PreparedStatement ps =
                         con.prepareStatement(duplicateSql)) {

                    ps.setInt(1, studentId);
                    ps.setDate(2, attendanceDate);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            con.rollback();

                            showMessage(response, 409,
                                "Already Marked",
                                "Your attendance has already been recorded for this date.",
                                request.getContextPath());
                            return;
                        }
                    }
                }

                String insertSql =
                    "INSERT INTO attendance "
                    + "(student_id, attendance_date, status) "
                    + "VALUES (?, ?, 'Present')";

                try (PreparedStatement ps =
                         con.prepareStatement(insertSql)) {

                    ps.setInt(1, studentId);
                    ps.setDate(2, attendanceDate);
                    ps.executeUpdate();
                }

                con.commit();

                showMessage(response, 200,
                    "Attendance Marked Successfully!",
                    "Your attendance has been recorded.",
                    request.getContextPath());

            } catch (Exception e) {
                try {
                    con.rollback();
                } catch (Exception rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;
            }

        } catch (Exception e) {
            getServletContext().log("QR check-in failed", e);

            showMessage(response, 500,
                "Attendance Could Not Be Marked",
                "Please try again or ask the administrator for help.",
                request.getContextPath());
        }
    }
}
