
package com.attendance;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class AttendanceAlertService {

    private static final BigDecimal THRESHOLD =
            new BigDecimal("75.00");

    private static final int COOLDOWN_DAYS = 7;

    private static class LowAttendance {
        int studentId;
        int subjectId;
        String studentName;
        String email;
        String subjectName;
        int totalClasses;
        int presentClasses;
        BigDecimal percentage;

        LowAttendance(
                int studentId,
                int subjectId,
                String studentName,
                String email,
                String subjectName,
                int totalClasses,
                int presentClasses,
                BigDecimal percentage) {

            this.studentId = studentId;
            this.subjectId = subjectId;
            this.studentName = studentName;
            this.email = email;
            this.subjectName = subjectName;
            this.totalClasses = totalClasses;
            this.presentClasses = presentClasses;
            this.percentage = percentage;
        }
    }

    public static int sendLowAttendanceAlerts()
            throws Exception {

        List<LowAttendance> students =
                findLowAttendanceStudents();

        int sentCount = 0;

        for (LowAttendance student : students) {

            if (student.email == null
                    || student.email.isBlank()) {
                continue;
            }

            long alertId = createPendingAlert(student);

            if (alertId == -1) {
                continue;
            }

            try {
                String emailSubject =
                        "Low Attendance Alert - "
                        + student.subjectName;

                String html =
                        "<html><body>"
                        + "<h2>Low Attendance Warning</h2>"
                        + "<p>Dear "
                        + escapeHtml(student.studentName)
                        + ",</p>"
                        + "<p>Your attendance in <b>"
                        + escapeHtml(student.subjectName)
                        + "</b> is below the required 75%.</p>"
                        + "<p>Classes held: "
                        + student.totalClasses
                        + "<br>Classes attended: "
                        + student.presentClasses
                        + "<br>Attendance percentage: "
                        + student.percentage.toPlainString()
                        + "%</p>"
                        + "<p>Please attend upcoming classes regularly.</p>"
                        + "</body></html>";

                EmailService.sendEmail(
                        student.email,
                        emailSubject,
                        html
                );

                updateAlertStatus(alertId, true);
                sentCount++;

            } catch (IOException | InterruptedException
                    | RuntimeException e) {

                try {
                    updateAlertStatus(alertId, false);
                } catch (Exception updateError) {
                    e.addSuppressed(updateError);
                }

                if (e instanceof InterruptedException) {
                    Thread.currentThread().interrupt();
                    break;
                }

                System.err.println(
                        "Attendance alert email failed for student ID "
                        + student.studentId + ": "
                        + e.getMessage()
                );
            }
        }

        return sentCount;
    }

    private static List<LowAttendance>
            findLowAttendanceStudents() throws Exception {

        List<LowAttendance> result = new ArrayList<>();

        String sql =
                "SELECT s.student_id, "
                + "sub.subject_id, "
                + "s.name, "
                + "s.email, "
                + "sub.subject_name, "

                + "COUNT(DISTINCT ls.lecture_id) "
                + "AS total_classes, "

                + "SUM(CASE "
                + "WHEN a.status = 'Present' "
                + "THEN 1 ELSE 0 END) "
                + "AS present_classes, "

                + "ROUND(100.0 * "
                + "SUM(CASE WHEN a.status = 'Present' "
                + "THEN 1 ELSE 0 END) "
                + "/ COUNT(DISTINCT ls.lecture_id), 2) "
                + "AS percentage "

                + "FROM students s "

+ "JOIN subjects sub "
+ "ON sub.course = 'B.Tech CSE' "
+ "AND TRIM(s.semester) = TRIM(sub.semester) "
+ "AND UPPER(REPLACE(REPLACE(TRIM(s.course), '.', ''), ' ', '')) "
+ "IN ('BTECH', 'BTECHCSE', 'CSE') "
               

                + "JOIN class_timetable ct "
                + "ON ct.subject_id = sub.subject_id "

                + "JOIN lecture_sessions ls "
                + "ON ls.timetable_id = ct.timetable_id "

                + "LEFT JOIN attendance a "
                + "ON a.student_id = s.student_id "
                + "AND a.lecture_id = ls.lecture_id "

                + "WHERE ls.session_status = 'Closed' "

                + "GROUP BY s.student_id, "
                + "sub.subject_id, "
                + "s.name, "
                + "s.email, "
                + "sub.subject_name "

                + "HAVING COUNT(DISTINCT ls.lecture_id) > 0 "
                + "AND (100.0 * "
                + "SUM(CASE WHEN a.status = 'Present' "
                + "THEN 1 ELSE 0 END) "
                + "/ COUNT(DISTINCT ls.lecture_id)) < ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps =
                     con.prepareStatement(sql)) {

            ps.setBigDecimal(1, THRESHOLD);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    result.add(new LowAttendance(
                            rs.getInt("student_id"),
                            rs.getInt("subject_id"),
                            rs.getString("name"),
                            rs.getString("email"),
                            rs.getString("subject_name"),
                            rs.getInt("total_classes"),
                            rs.getInt("present_classes"),
                            rs.getBigDecimal("percentage")
                    ));
                }
            }
        }

        return result;
    }

    private static long createPendingAlert(
            LowAttendance student) throws Exception {

        String checkSql =
                "SELECT alert_id "
                + "FROM attendance_alert_logs "
                + "WHERE student_id = ? "
                + "AND subject_id = ? "
                + "AND alert_type = 'LOW_ATTENDANCE' "
                + "AND channel = 'Email' "
                + "AND (delivery_status = 'Pending' "
                + "OR (delivery_status = 'Sent' "
                + "AND created_at >= ?)) "
                + "ORDER BY alert_id DESC LIMIT 1";

        LocalDateTime cutoff =
                LocalDateTime.now().minusDays(COOLDOWN_DAYS);

        String insertSql =
                "INSERT INTO attendance_alert_logs "
                + "(student_id, subject_id, alert_type, channel, "
                + "attendance_percentage, delivery_status) "
                + "VALUES (?, ?, 'LOW_ATTENDANCE', "
                + "'Email', ?, 'Pending')";

        try (Connection con = DBConnection.getConnection()) {

            con.setAutoCommit(false);

            try {
                try (PreparedStatement check =
                        con.prepareStatement(checkSql)) {

                    check.setInt(1, student.studentId);
                    check.setInt(2, student.subjectId);
                    check.setTimestamp(
                            3, Timestamp.valueOf(cutoff));

                    try (ResultSet rs = check.executeQuery()) {
                        if (rs.next()) {
                            con.rollback();
                            return -1;
                        }
                    }
                }

                try (PreparedStatement insert =
                        con.prepareStatement(
                                insertSql,
                                PreparedStatement.RETURN_GENERATED_KEYS)) {

                    insert.setInt(1, student.studentId);
                    insert.setInt(2, student.subjectId);
                    insert.setBigDecimal(
                            3,
                            student.percentage.setScale(
                                    2, RoundingMode.HALF_UP));

                    insert.executeUpdate();

                    try (ResultSet keys =
                            insert.getGeneratedKeys()) {

                        if (keys.next()) {
                            long alertId = keys.getLong(1);
                            con.commit();
                            return alertId;
                        }
                    }
                }

                con.rollback();
                return -1;

            } catch (Exception e) {
                con.rollback();
                throw e;

            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    private static void updateAlertStatus(
            long alertId, boolean sent) throws Exception {

        String sql = sent
                ? "UPDATE attendance_alert_logs "
                  + "SET delivery_status = 'Sent', "
                  + "sent_at = CURRENT_TIMESTAMP "
                  + "WHERE alert_id = ?"
                : "UPDATE attendance_alert_logs "
                  + "SET delivery_status = 'Failed' "
                  + "WHERE alert_id = ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps =
                     con.prepareStatement(sql)) {

            ps.setLong(1, alertId);
            ps.executeUpdate();
        }
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
}
