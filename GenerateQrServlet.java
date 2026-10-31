
package com.attendance;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Base64;
import java.util.HexFormat;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/generateQr")
public class GenerateQrServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final ZoneId ZONE =
            ZoneId.of("Asia/Kolkata");

    private static final SecureRandom RANDOM =
            new SecureRandom();

    private static String hash(String value) throws Exception {
        byte[] bytes = MessageDigest.getInstance("SHA-256")
                .digest(value.getBytes(StandardCharsets.UTF_8));

        return HexFormat.of().formatHex(bytes);
    }

    private static String randomHex(int byteCount) {
        byte[] bytes = new byte[byteCount];
        RANDOM.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    private static boolean isTeacher(HttpSession session) {
        return session != null
                && session.getAttribute("teacherId") instanceof Integer
                && "TEACHER".equals(
                        session.getAttribute("userRole"));
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        HttpSession session = request.getSession(false);

        if (!isTeacher(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/teacherLogin.jsp");
            return;
        }

        int teacherId =
                (Integer) session.getAttribute("teacherId");

        LocalDateTime now = LocalDateTime.now(ZONE);
        LocalDate today = now.toLocalDate();
        LocalTime currentTime = now.toLocalTime();

        getServletContext().log(
                "QR Java time (Asia/Kolkata): " + now);

        getServletContext().log(
                "QR DEBUG: teacherId=" + teacherId
                + ", dayOfWeek=" + today.getDayOfWeek().getValue()
                + ", currentTime=" + currentTime);

        String token = null;
        String pin = null;

        try (Connection con = DBConnection.getConnection()) {

            con.setAutoCommit(false);

            try {
                int timetableId;
                int lectureId;
                LocalTime lectureStart;
                LocalTime lectureEnd;
                String subjectName;
                String subjectCode;

                String scheduleSql =
                    "SELECT ct.timetable_id, ct.start_time, ct.end_time, "
                  + "s.subject_code, s.subject_name "
                  + "FROM class_timetable ct "
                  + "JOIN subjects s ON s.subject_id = ct.subject_id "
                  + "WHERE ct.is_active = 1 "
                  + "AND ct.teacher_id = ? "
                  + "AND ct.day_of_week = ? "
                  + "AND ct.start_time <= ? "
                  + "AND ct.end_time > ? "
                  + "ORDER BY ct.start_time LIMIT 1";

                try (PreparedStatement ps =
                        con.prepareStatement(scheduleSql)) {

                    ps.setInt(1, teacherId);
                    ps.setInt(2, today.getDayOfWeek().getValue());
                    ps.setTime(3, Time.valueOf(currentTime));
                    ps.setTime(4, Time.valueOf(currentTime));

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new IllegalStateException(
                                "No lecture assigned to you is currently "
                              + "scheduled. Generate the QR during your "
                              + "own lecture time.");
                        }

                        timetableId = rs.getInt("timetable_id");
                        lectureStart =
                                rs.getTime("start_time").toLocalTime();
                        lectureEnd =
                                rs.getTime("end_time").toLocalTime();
                        subjectCode = rs.getString("subject_code");
                        subjectName = rs.getString("subject_name");
                    }
                }

                String findLectureSql =
                    "SELECT lecture_id, session_status "
                  + "FROM lecture_sessions "
                  + "WHERE timetable_id = ? AND lecture_date = ? "
                  + "LIMIT 1 FOR UPDATE";

                try (PreparedStatement ps =
                        con.prepareStatement(findLectureSql)) {

                    ps.setInt(1, timetableId);
                    ps.setDate(2, Date.valueOf(today));

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            lectureId = rs.getInt("lecture_id");

                            if ("Cancelled".equals(
                                    rs.getString("session_status"))) {
                                throw new IllegalStateException(
                                        "This lecture has been cancelled.");
                            }
                        } else {
                            String insertLectureSql =
                                "INSERT INTO lecture_sessions "
                              + "(timetable_id, lecture_date, "
                              + "scheduled_start, scheduled_end, "
                              + "session_status) "
                              + "VALUES (?, ?, ?, ?, 'Open')";

                            try (PreparedStatement insert =
                                    con.prepareStatement(
                                            insertLectureSql)) {

                                insert.setInt(1, timetableId);
                                insert.setDate(2, Date.valueOf(today));
                                insert.setTime(
                                        3, Time.valueOf(lectureStart));
                                insert.setTime(
                                        4, Time.valueOf(lectureEnd));
                                insert.executeUpdate();
                            }

                            try (PreparedStatement find =
                                    con.prepareStatement(
                                            findLectureSql)) {

                                find.setInt(1, timetableId);
                                find.setDate(
                                        2, Date.valueOf(today));

                                try (ResultSet rs2 =
                                        find.executeQuery()) {
                                    if (!rs2.next()) {
                                        throw new IllegalStateException(
                                                "Lecture session could "
                                              + "not be created.");
                                    }

                                    lectureId =
                                            rs2.getInt("lecture_id");
                                }
                            }
                        }
                    }
                }

                // Generate six-digit PIN and salted hash.
                pin = String.format(
                        "%06d", RANDOM.nextInt(1_000_000));

                String salt = randomHex(16);
                String pinHash = hash(salt + ":" + pin);

                LocalDateTime lectureExpiry =
                        LocalDateTime.of(today, lectureEnd);

                // Deactivate older PINs for this lecture.
                String deactivateCodesSql =
                    "UPDATE lecture_attendance_codes "
                  + "SET is_active = 0 "
                  + "WHERE lecture_id = ? AND is_active = 1";

                try (PreparedStatement ps =
                        con.prepareStatement(deactivateCodesSql)) {

                    ps.setInt(1, lectureId);
                    ps.executeUpdate();
                }

                // Deactivate older QR codes for this lecture.
                try (PreparedStatement ps =
                        con.prepareStatement(
                            "UPDATE attendance_qr_sessions "
                          + "SET is_active = 0 "
                          + "WHERE lecture_id = ? AND is_active = 1")) {

                    ps.setInt(1, lectureId);
                    ps.executeUpdate();
                }

                String insertCodeSql =
                    "INSERT INTO lecture_attendance_codes "
                  + "(lecture_id, teacher_id, code_hash, code_salt, "
                  + "expires_at, is_active) "
                  + "VALUES (?, ?, ?, ?, ?, 1)";

                try (PreparedStatement ps =
                        con.prepareStatement(insertCodeSql)) {

                    ps.setInt(1, lectureId);
                    ps.setInt(2, teacherId);
                    ps.setString(3, pinHash);
                    ps.setString(4, salt);
                    ps.setObject(5, lectureExpiry);

                    ps.executeUpdate();
                }

                // QR expires after 10 minutes or at lecture end.
                LocalDateTime qrExpiry = now.plusMinutes(10);

                if (lectureExpiry.isBefore(qrExpiry)) {
                    qrExpiry = lectureExpiry;
                }

                byte[] randomBytes = new byte[32];
                RANDOM.nextBytes(randomBytes);

                token = Base64.getUrlEncoder()
                        .withoutPadding()
                        .encodeToString(randomBytes);

                String tokenHash = hash(token);

                // Keep existing one-active-QR behavior.
                try (PreparedStatement ps =
                        con.prepareStatement(
                            "UPDATE attendance_qr_sessions "
                          + "SET is_active = 0 WHERE is_active = 1")) {

                    ps.executeUpdate();
                }

                String insertQrSql =
                    "INSERT INTO attendance_qr_sessions "
                  + "(lecture_id, token_hash, attendance_date, "
                  + "expires_at, is_active) "
                  + "VALUES (?, ?, ?, ?, 1)";

                try (PreparedStatement ps =
                        con.prepareStatement(insertQrSql)) {

                    ps.setInt(1, lectureId);
                    ps.setString(2, tokenHash);
                    ps.setDate(3, Date.valueOf(today));
                    ps.setObject(4, qrExpiry);

                    ps.executeUpdate();
                }

                con.commit();

                // PUBLIC QR URL
                String publicUrl =
                        System.getenv("ATTENDANCE_PUBLIC_URL");

                String baseUrl;

                if (publicUrl != null && !publicUrl.isBlank()) {

                    // Render URL is treated as the complete
                    // externally accessible application base URL.
                    baseUrl = publicUrl.trim()
                            .replaceAll("/+$", "");

                } else {

                    // Local Eclipse/Tomcat fallback.
                    String scheme = request.getScheme();
                    String host = request.getServerName();
                    int port = request.getServerPort();

                    baseUrl = scheme + "://" + host;

                    boolean standardPort =
                            ("http".equalsIgnoreCase(scheme)
                                    && port == 80)
                            || ("https".equalsIgnoreCase(scheme)
                                    && port == 443);

                    if (!standardPort) {
                        baseUrl += ":" + port;
                    }

                    baseUrl += request.getContextPath();
                }

                String qrUrl = baseUrl
                        + "/qrCheckIn?token="
                        + URLEncoder.encode(
                                token, StandardCharsets.UTF_8);

                getServletContext().log(
                        "ATTENDANCE_PUBLIC_URL = " + publicUrl);

                getServletContext().log(
                        "FINAL QR BASE URL = " + baseUrl);

                getServletContext().log(
                        "FINAL QR URL = " + qrUrl);

                request.setAttribute("qrUrl", qrUrl);
                request.setAttribute("classPin", pin);
                request.setAttribute("subjectName", subjectName);
                request.setAttribute("subjectCode", subjectCode);
                request.setAttribute(
                        "lectureEndTime", lectureEnd.toString());
                request.setAttribute(
                        "qrExpiryTime", qrExpiry.toLocalTime().toString());

                request.getRequestDispatcher("/adminQr.jsp")
                        .forward(request, response);

            } catch (Exception e) {
                try {
                    con.rollback();
                } catch (Exception rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;
            }

        } catch (Exception e) {
            getServletContext().log(
                    "Unable to generate attendance QR/PIN", e);

            request.setAttribute(
                    "qrError",
                    e instanceof IllegalStateException
                            ? e.getMessage()
                            : "QR/PIN generation failed. Check the Eclipse Console.");

            request.getRequestDispatcher("/adminQr.jsp")
                    .forward(request, response);
        }
    }
}
