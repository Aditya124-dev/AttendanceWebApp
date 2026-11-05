
package com.attendance;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
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

    private static final ZoneId ZONE =
            ZoneId.of("Asia/Kolkata");

    private static String hash(String value) throws Exception {
        byte[] bytes = MessageDigest.getInstance("SHA-256")
                .digest(value.getBytes(StandardCharsets.UTF_8));

        return HexFormat.of().formatHex(bytes);
    }

    private static String escapeHtml(String value) {
        if (value == null) {
            return "";
        }

        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private static boolean isLoggedIn(HttpSession session) {
        return session != null
                && session.getAttribute("studentId") instanceof Integer;
    }

    private static boolean validToken(String token) {
        return token != null
                && token.matches("[A-Za-z0-9_-]{40,50}");
    }

    private static double distanceMeters(
            double lat1, double lon1,
            double lat2, double lon2) {

        double earthRadius = 6_371_000.0;

        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);

        return earthRadius * 2 * Math.atan2(
                Math.sqrt(a), Math.sqrt(1 - a));
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

        String html = """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport"
                        content="width=device-width, initial-scale=1">
                  <title>%s</title>
                  <style>
                    body {
                      margin: 0;
                      min-height: 100vh;
                      display: flex;
                      align-items: center;
                      justify-content: center;
                      background: #f1f5f9;
                      font-family: Arial, sans-serif;
                    }
                    .card {
                      background: white;
                      width: min(420px, 88%%);
                      padding: 30px;
                      border-radius: 16px;
                      box-shadow: 0 10px 35px #0001;
                      text-align: center;
                    }
                    h2 { color: #172554; }
                    p { color: #475569; line-height: 1.6; }
                    a {
                      display: inline-block;
                      margin-top: 12px;
                      padding: 12px 20px;
                      border-radius: 8px;
                      color: white;
                      background: #2563eb;
                      text-decoration: none;
                    }
                  </style>
                </head>
                <body>
                  <div class="card">
                    <h2>%s</h2>
                    <p>%s</p>
                    <a href="%s/index.jsp">Back to Home</a>
                  </div>
                </body>
                </html>
                """.formatted(
                    escapeHtml(title),
                    escapeHtml(title),
                    escapeHtml(message),
                    escapeHtml(contextPath));

        response.getWriter().write(html);
    }

    @Override
    protected void doGet(
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

        if (!validToken(token)) {
            showMessage(response, 400,
                    "Invalid QR Code",
                    "The QR token is invalid. Scan the current classroom QR code.",
                    request.getContextPath());
            return;
        }

        try (Connection con = DBConnection.getConnection()) {

            String sql =
                    "SELECT qr_id FROM attendance_qr_sessions "
                  + "WHERE token_hash = ? "
                  + "AND is_active = 1 "
                  + "AND attendance_date = ? "
                  + "AND expires_at > ? "
                  + "LIMIT 1";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, hash(token));
                ps.setDate(2, Date.valueOf(LocalDate.now(ZONE)));
                ps.setObject(3, LocalDateTime.now(ZONE));

                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        showMessage(response, 410,
                                "QR Expired",
                                "This QR code is expired or inactive. Ask your teacher to generate a new one.",
                                request.getContextPath());
                        return;
                    }
                }
            }

            response.setContentType("text/html;charset=UTF-8");

            String safeToken = escapeHtml(token);
            String action = request.getContextPath() + "/qrCheckIn";

            response.getWriter().write("""
                    <!DOCTYPE html>
                    <html lang="en">
                    <head>
                      <meta charset="UTF-8">
                      <meta name="viewport"
                            content="width=device-width, initial-scale=1">
                      <title>QR Attendance Check-In</title>
                      <style>
                        body {
                          margin: 0;
                          min-height: 100vh;
                          display: flex;
                          align-items: center;
                          justify-content: center;
                          background: #eff6ff;
                          font-family: Arial, sans-serif;
                        }
                        .card {
                          width: min(420px, 88%%);
                          padding: 28px;
                          background: white;
                          border-radius: 18px;
                          box-shadow: 0 10px 35px #0001;
                        }
                        h2 { color: #1e3a8a; }
                        label {
                          display: block;
                          margin-top: 16px;
                          font-weight: bold;
                        }
                        input {
                          box-sizing: border-box;
                          width: 100%%;
                          padding: 13px;
                          margin-top: 7px;
                          border: 1px solid #cbd5e1;
                          border-radius: 8px;
                          font-size: 17px;
                        }
                        button {
                          width: 100%%;
                          margin-top: 22px;
                          padding: 14px;
                          border: 0;
                          border-radius: 8px;
                          color: white;
                          background: #2563eb;
                          font-size: 16px;
                          cursor: pointer;
                        }
                        .note {
                          color: #64748b;
                          line-height: 1.5;
                          font-size: 14px;
                        }
                      </style>
                    </head>
                    <body>
                      <div class="card">
                        <h2>Student Attendance</h2>
                        <p class="note">
                          Enter the six-digit PIN provided by your teacher.
                          Allow location access to verify campus proximity.
                        </p>

                        <form id="attendanceForm" method="post"
                              action="%s">
                          <input type="hidden" name="token" value="%s">
                          <input type="hidden" name="latitude" id="latitude">
                          <input type="hidden" name="longitude" id="longitude">

                          <label for="pin">Lecture PIN</label>
                          <input id="pin" name="pin"
                                 inputmode="numeric"
                                 pattern="[0-9]{6}"
                                 maxlength="6"
                                 required
                                 autocomplete="one-time-code">

                          <button id="submitButton" type="submit">
                            Verify Location & Mark Attendance
                          </button>
                        </form>

                        <p id="locationStatus" class="note"></p>
                      </div>

                      <script>
                        const form = document.getElementById('attendanceForm');
                        const statusText =
                            document.getElementById('locationStatus');
                        const button =
                            document.getElementById('submitButton');

                        form.addEventListener('submit', function(event) {
                          event.preventDefault();

                          if (!navigator.geolocation) {
                            statusText.textContent =
                              'Geolocation is not supported by this browser.';
                            return;
                          }

                          button.disabled = true;
                          statusText.textContent =
                            'Checking your location...';

                          navigator.geolocation.getCurrentPosition(
                            function(position) {
                              document.getElementById('latitude').value =
                                position.coords.latitude;
                              document.getElementById('longitude').value =
                                position.coords.longitude;

                              form.submit();
                            },
                            function() {
                              button.disabled = false;
                              statusText.textContent =
                                'Location permission is required. Allow location access and try again.';
                            },
                            {
                              enableHighAccuracy: true,
                              timeout: 15000,
                              maximumAge: 0
                            }
                          );
                        });
                      </script>
                    </body>
                    </html>
                    """.formatted(action, safeToken));

        } catch (Exception e) {
            getServletContext().log(
                    "Unable to validate QR token", e);

            showMessage(response, 500,
                    "Attendance Unavailable",
                    "The QR code could not be verified. Please try again later.",
                    request.getContextPath());
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");

        HttpSession session = request.getSession(false);

        if (!isLoggedIn(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/studentLogin.jsp");
            return;
        }

        int studentId = (Integer) session.getAttribute("studentId");

        String token = request.getParameter("token");
        String pin = request.getParameter("pin");
        String latitudeText = request.getParameter("latitude");
        String longitudeText = request.getParameter("longitude");

        if (!validToken(token)
                || pin == null
                || !pin.matches("[0-9]{6}")) {

            showMessage(response, 400,
                    "Invalid Details",
                    "The QR token or six-digit PIN is invalid.",
                    request.getContextPath());
            return;
        }

        double latitude;
        double longitude;

        try {
            latitude = Double.parseDouble(latitudeText);
            longitude = Double.parseDouble(longitudeText);

            if (!Double.isFinite(latitude)
                    || !Double.isFinite(longitude)
                    || latitude < -90 || latitude > 90
                    || longitude < -180 || longitude > 180) {
                throw new IllegalArgumentException("Invalid coordinates");
            }
        } catch (Exception e) {
            showMessage(response, 400,
                    "Location Required",
                    "Allow location access and submit your attendance again.",
                    request.getContextPath());
            return;
        }

        String collegeLatText =
                System.getenv("ATTENDANCE_COLLEGE_LAT");
        String collegeLonText =
                System.getenv("ATTENDANCE_COLLEGE_LON");

        double collegeLat;
        double collegeLon;
        double radiusMeters;

        try {
            if (collegeLatText == null || collegeLonText == null) {
                throw new IllegalStateException(
                        "Campus coordinates are not configured.");
            }

            collegeLat = Double.parseDouble(collegeLatText);
            collegeLon = Double.parseDouble(collegeLonText);

            String radiusText =
                    System.getenv("ATTENDANCE_RADIUS_METERS");

            radiusMeters = radiusText == null
                    || radiusText.isBlank()
                    ? 150.0
                    : Double.parseDouble(radiusText);

            if (!Double.isFinite(collegeLat)
                    || !Double.isFinite(collegeLon)
                    || collegeLat < -90 || collegeLat > 90
                    || collegeLon < -180 || collegeLon > 180
                    || !Double.isFinite(radiusMeters)
                    || radiusMeters <= 0) {
                throw new IllegalArgumentException(
                        "Invalid campus location configuration.");
            }

        } catch (Exception e) {
            getServletContext().log(
                    "Campus location configuration error", e);

            showMessage(response, 500,
                    "Location Verification Unavailable",
                    "Campus location is not configured correctly. Contact the administrator.",
                    request.getContextPath());
            return;
        }

        double distance = distanceMeters(
                latitude, longitude, collegeLat, collegeLon);

        if (distance > radiusMeters) {
            showMessage(response, 403,
                    "Outside College Campus",
                    "Your reported location is outside the permitted attendance area.",
                    request.getContextPath());
            return;
        }

        LocalDateTime now = LocalDateTime.now(ZONE);
        LocalDate today = now.toLocalDate();

        try (Connection con = DBConnection.getConnection()) {

            con.setAutoCommit(false);

            try {
                int lectureId;
                String codeHash;
                String codeSalt;
                LocalDateTime codeExpiry;
                LocalTime scheduledStart;
                LocalTime scheduledEnd;
                String sessionStatus;

                String qrSql =
                        "SELECT q.lecture_id "
                      + "FROM attendance_qr_sessions q "
                      + "JOIN lecture_sessions l "
                      + "ON l.lecture_id = q.lecture_id "
                      + "WHERE q.token_hash = ? "
                      + "AND q.is_active = 1 "
                      + "AND q.attendance_date = ? "
                      + "AND q.expires_at > ? "
                      + "AND l.lecture_date = ? "
                      + "FOR UPDATE";

                try (PreparedStatement ps =
                             con.prepareStatement(qrSql)) {

                    ps.setString(1, hash(token));
                    ps.setDate(2, Date.valueOf(today));
                    ps.setObject(3, now);
                    ps.setDate(4, Date.valueOf(today));

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalStateException(
                                    "QR code expired or inactive. Scan a new QR code.");
                        }

                        lectureId = rs.getInt("lecture_id");
                    }
                }

                String lectureSql =
                        "SELECT scheduled_start, scheduled_end, "
                      + "session_status "
                      + "FROM lecture_sessions "
                      + "WHERE lecture_id = ? "
                      + "FOR UPDATE";

                try (PreparedStatement ps =
                             con.prepareStatement(lectureSql)) {

                    ps.setInt(1, lectureId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalStateException(
                                    "Lecture session not found.");
                        }

                        scheduledStart =
                                rs.getTime("scheduled_start").toLocalTime();
                        scheduledEnd =
                                rs.getTime("scheduled_end").toLocalTime();
                        sessionStatus = rs.getString("session_status");
                    }
                }

                if ("Cancelled".equalsIgnoreCase(sessionStatus)) {
                    throw new IllegalStateException(
                            "This lecture has been cancelled.");
                }

                LocalTime currentTime = now.toLocalTime();

                if (currentTime.isBefore(scheduledStart)
                        || !currentTime.isBefore(scheduledEnd)) {
                    throw new IllegalStateException(
                            "Attendance can only be marked during the scheduled lecture.");
                }

                String codeSql =
                        "SELECT code_hash, code_salt, expires_at "
                      + "FROM lecture_attendance_codes "
                      + "WHERE lecture_id = ? "
                      + "AND is_active = 1 "
                      + "ORDER BY created_at DESC LIMIT 1 "
                      + "FOR UPDATE";

                try (PreparedStatement ps =
                             con.prepareStatement(codeSql)) {

                    ps.setInt(1, lectureId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalStateException(
                                    "No active PIN exists for this lecture.");
                        }

                        codeHash = rs.getString("code_hash");
                        codeSalt = rs.getString("code_salt");

                        java.sql.Timestamp expiryTimestamp =
                                rs.getTimestamp("expires_at");

                        codeExpiry = expiryTimestamp.toLocalDateTime();
                    }
                }

                if (codeExpiry.isBefore(now)) {
                    throw new IllegalStateException(
                            "The lecture PIN has expired.");
                }

                String submittedHash = hash(codeSalt + ":" + pin);

                if (!MessageDigest.isEqual(
                        submittedHash.getBytes(StandardCharsets.UTF_8),
                        codeHash.getBytes(StandardCharsets.UTF_8))) {
                    throw new IllegalStateException(
                            "Incorrect lecture PIN. Please check with your teacher.");
                }

                String duplicateSql =
                        "SELECT attendance_id FROM attendance "
                      + "WHERE student_id = ? AND lecture_id = ? "
                      + "LIMIT 1";

                try (PreparedStatement ps =
                             con.prepareStatement(duplicateSql)) {

                    ps.setInt(1, studentId);
                    ps.setInt(2, lectureId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            throw new IllegalStateException(
                                    "Attendance has already been marked for this lecture.");
                        }
                    }
                }

                String insertSql =
                        "INSERT INTO attendance "
                      + "(student_id, lecture_id, attendance_date, status, "
                      + "latitude, longitude, distance, location_verified) "
                      + "VALUES (?, ?, ?, 'Present', ?, ?, ?, 1)";

                try (PreparedStatement ps =
                             con.prepareStatement(insertSql)) {

                    ps.setInt(1, studentId);
                    ps.setInt(2, lectureId);
                    ps.setDate(3, Date.valueOf(today));
                    ps.setDouble(4, latitude);
                    ps.setDouble(5, longitude);
                    ps.setDouble(6, distance);

                    ps.executeUpdate();
                }
               
                con.commit();
                
                try {
                    AttendanceAlertService.sendLowAttendanceAlerts();
                } catch (Exception alertError) {
                    getServletContext().log(
                        "Low attendance alert processing failed",
                        alertError
                    );
                }

                showMessage(response, 200,
                        "Attendance Marked Successfully",
                        "Your attendance has been recorded for this lecture.",
                        request.getContextPath());

            } catch (Exception e) {
                try {
                    con.rollback();
                } catch (Exception rollbackError) {
                    e.addSuppressed(rollbackError);
                }
                throw e;
            }

        } catch (IllegalStateException e) {
            showMessage(response, 400,
                    "Attendance Not Marked",
                    e.getMessage(),
                    request.getContextPath());

        } catch (Exception e) {
            getServletContext().log(
                    "QR attendance check-in failed", e);

            showMessage(response, 500,
                    "Attendance Error",
                    "Attendance could not be recorded. Check the application logs.",
                    request.getContextPath());
        }
    }
}
