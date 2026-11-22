
package com.attendance;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import jakarta.mail.internet.InternetAddress;

public class AttendanceAlertService {

    private static final BigDecimal THRESHOLD =
            new BigDecimal("75.00");

    private static final int COOLDOWN_DAYS = 7;

    private static class LowAttendance {
        int studentId;
        String studentName;
        String email;
        int totalClasses;
        int presentClasses;
        BigDecimal percentage;

        LowAttendance(
                int studentId,
                String studentName,
                String email,
                int totalClasses,
                int presentClasses,
                BigDecimal percentage) {

            this.studentId = studentId;
            this.studentName = studentName;
            this.email = email;
            this.totalClasses = totalClasses;
            this.presentClasses = presentClasses;
            this.percentage = percentage;
        }
    }

    public static class AlertPreview {

        private final int studentId;
        private final String studentName;
        private final String email;
        private final int totalClasses;
        private final int presentClasses;
        private final BigDecimal percentage;
        private final String status;

        AlertPreview(LowAttendance student, String status) {
            this.studentId = student.studentId;
            this.studentName = student.studentName;
            this.email = student.email;
            this.totalClasses = student.totalClasses;
            this.presentClasses = student.presentClasses;
            this.percentage = student.percentage;
            this.status = status;
        }

        public int getStudentId() {
            return studentId;
        }

        public String getStudentName() {
            return studentName;
        }

        public String getEmail() {
            return email;
        }

        public int getTotalClasses() {
            return totalClasses;
        }

        public int getPresentClasses() {
            return presentClasses;
        }

        public BigDecimal getPercentage() {
            return percentage;
        }

        public String getStatus() {
            return status;
        }

        public boolean isReady() {
            return "READY".equals(status);
        }
    }

    /*
     * PREVIEW
     * No email is sent and no database record is inserted.
     */
    public static List<AlertPreview> getLowAttendancePreview()
            throws Exception {

        List<AlertPreview> preview = new ArrayList<>();

        for (LowAttendance student : findLowAttendanceStudents()) {

            if (student.email == null || student.email.isBlank()) {
                preview.add(new AlertPreview(student, "MISSING_EMAIL"));

            } else if (isInCooldown(student.studentId)) {
                preview.add(new AlertPreview(student, "COOLDOWN"));

            } else {
                preview.add(new AlertPreview(student, "READY"));
            }
        }

        return preview;
    }

    /*
     * TEST EMAIL
     * Sends only to the supplied test recipient.
     * Does not insert alert logs or change cooldown.
     */
    public static void sendTestAlert(
            int studentId,
            String testRecipient
    ) throws Exception {

        if (studentId <= 0) {
            throw new IllegalArgumentException(
                    "Invalid student ID.");
        }

        if (testRecipient == null || testRecipient.isBlank()) {
            throw new IllegalArgumentException(
                    "Test recipient email is required.");
        }

        InternetAddress address =
                new InternetAddress(testRecipient.trim());

        address.validate();

        LowAttendance selectedStudent = null;

        for (LowAttendance student : findLowAttendanceStudents()) {

            if (student.studentId == studentId) {
                selectedStudent = student;
                break;
            }
        }

        if (selectedStudent == null) {
            throw new IllegalArgumentException(
                    "Student not found in the low-attendance list.");
        }

        EmailService.sendEmail(
                address.getAddress(),
                "[TEST] Low Attendance Alert - AttendancePro",
                buildAlertHtml(selectedStudent, true)
        );

        System.out.println(
                "Test attendance email sent for student ID "
                + studentId + " to " + address.getAddress()
        );
    }

    /*
     * AUTOMATIC / MANUAL BULK ALERT PROCESS
     *
     * Only students below 75% are considered.
     * Successful email cooldown is 7 days.
     * Failed emails can be retried on the next run.
     */
    public static int sendLowAttendanceAlerts() throws Exception {

        List<LowAttendance> students =
                findLowAttendanceStudents();

        int sentCount = 0;

        for (LowAttendance student : students) {

            if (student.email == null || student.email.isBlank()) {
                System.err.println(
                        "Alert skipped: Email missing for student ID "
                        + student.studentId);
                continue;
            }

            long alertId;

            try {
                alertId = createPendingAlert(student);

            } catch (Exception e) {
                System.err.println(
                        "Could not create alert for student ID "
                        + student.studentId + ": " + e.getMessage());
                continue;
            }

            if (alertId == -1) {
                System.out.println(
                        "Alert skipped: Pending alert or 7-day cooldown "
                        + "for student ID " + student.studentId);
                continue;
            }

            try {

                EmailService.sendEmail(
                        student.email,
                        "Low Attendance Alert - AttendancePro",
                        buildAlertHtml(student, false)
                );

            } catch (IOException | RuntimeException e) {

                markFailed(alertId, e);

                System.err.println(
                        "Email failed for student ID "
                        + student.studentId + ": " + e.getMessage());

                continue;

            } catch (InterruptedException e) {

                markFailed(alertId, e);

                Thread.currentThread().interrupt();

                System.err.println(
                        "Email sending interrupted for student ID "
                        + student.studentId);

                break;
            }

            /*
             * Update is intentionally outside the email try/catch.
             * If marking Sent fails, Pending remains in the database.
             * This prevents an automatic duplicate attempt.
             */
            updateAlertStatus(alertId, true);

            sentCount++;

            System.out.println(
                    "Attendance alert sent to " + student.email);
        }

        System.out.println(
                "Attendance alert process completed. Emails sent: "
                + sentCount);

        return sentCount;
    }

    /*
     * Marks a failed email attempt.
     */
    private static void markFailed(long alertId, Exception originalError) {

        try {
            updateAlertStatus(alertId, false);

        } catch (Exception updateError) {
            originalError.addSuppressed(updateError);

            System.err.println(
                    "Could not update failed alert status for alert ID "
                    + alertId + ": " + updateError.getMessage());
        }
    }

    private static String buildAlertHtml(
            LowAttendance student,
            boolean test
    ) {

        String heading = test
                ? "Low Attendance Email Test"
                : "Low Attendance Warning";

        String intro = test
                ? "This is a test email generated by a teacher. "
                  + "It is not an official student notification."
                : "Your overall attendance is below the required 75%.";

        return "<html><body>"
                + "<h2>" + heading + "</h2>"
                + "<p>Dear " + escapeHtml(student.studentName) + ",</p>"
                + "<p>" + intro + "</p>"
                + "<p>Classes held: " + student.totalClasses
                + "<br>Classes attended: " + student.presentClasses
                + "<br>Attendance: "
                + student.percentage.toPlainString()
                + "%</p>"
                + "<p>Required attendance: 75%</p>"
                + "<p>Please attend upcoming classes regularly.</p>"
                + "<hr>"
                + "<small>AttendancePro - Student Attendance "
                + "Management System</small>"
                + "</body></html>";
    }

    /*
     * OVERALL ATTENDANCE CALCULATION
     */
    private static List<LowAttendance> findLowAttendanceStudents()
            throws Exception {

        List<LowAttendance> result = new ArrayList<>();

        String sql =
                "SELECT s.student_id, s.name, s.email, "
                + "COUNT(a.attendance_id) AS total_classes, "
                + "COALESCE(SUM(CASE "
                + "WHEN UPPER(TRIM(a.status)) = 'PRESENT' "
                + "THEN 1 ELSE 0 END), 0) AS present_classes, "
                + "ROUND(100.0 * "
                + "COALESCE(SUM(CASE "
                + "WHEN UPPER(TRIM(a.status)) = 'PRESENT' "
                + "THEN 1 ELSE 0 END), 0) "
                + "/ NULLIF(COUNT(a.attendance_id), 0), 2) "
                + "AS percentage "
                + "FROM students s "
                + "JOIN attendance a "
                + "ON a.student_id = s.student_id "
                + "GROUP BY s.student_id, s.name, s.email "
                + "HAVING COUNT(a.attendance_id) > 0 "
                + "AND (100.0 * "
                + "SUM(CASE "
                + "WHEN UPPER(TRIM(a.status)) = 'PRESENT' "
                + "THEN 1 ELSE 0 END) "
                + "/ COUNT(a.attendance_id)) < ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setBigDecimal(1, THRESHOLD);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    result.add(new LowAttendance(
                            rs.getInt("student_id"),
                            rs.getString("name"),
                            rs.getString("email"),
                            rs.getInt("total_classes"),
                            rs.getInt("present_classes"),
                            rs.getBigDecimal("percentage")
                    ));
                }
            }
        }

        return result;
    }

    /*
     * COOLDOWN CHECK
     *
     * Pending = blocks another attempt.
     * Sent within last 7 days = blocks another attempt.
     * Failed = does not block retry.
     *
     * sent_at is used instead of created_at.
     */
    private static boolean isInCooldown(int studentId)
            throws Exception {

        String sql =
                "SELECT alert_id "
                + "FROM attendance_alert_logs "
                + "WHERE student_id = ? "
                + "AND subject_id IS NULL "
                + "AND alert_type = 'LOW_ATTENDANCE' "
                + "AND channel = 'Email' "
                + "AND ("
                + "delivery_status = 'Pending' "
                + "OR (delivery_status = 'Sent' "
                + "AND sent_at >= DATE_SUB(CURRENT_TIMESTAMP, "
                + "INTERVAL " + COOLDOWN_DAYS + " DAY))"
                + ") "
                + "LIMIT 1";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, studentId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /*
     * ATOMIC PENDING RECORD CREATION
     *
     * Locks the student row so two application instances
     * cannot simultaneously create an alert for the same student.
     *
     * Requires the existing InnoDB students table.
     */
    private static long createPendingAlert(LowAttendance student)
            throws Exception {

        String lockSql =
                "SELECT student_id FROM students "
                + "WHERE student_id = ? FOR UPDATE";

        String checkSql =
                "SELECT alert_id "
                + "FROM attendance_alert_logs "
                + "WHERE student_id = ? "
                + "AND subject_id IS NULL "
                + "AND alert_type = 'LOW_ATTENDANCE' "
                + "AND channel = 'Email' "
                + "AND ("
                + "delivery_status = 'Pending' "
                + "OR (delivery_status = 'Sent' "
                + "AND sent_at >= DATE_SUB(CURRENT_TIMESTAMP, "
                + "INTERVAL " + COOLDOWN_DAYS + " DAY))"
                + ") "
                + "LIMIT 1";

        String insertSql =
                "INSERT INTO attendance_alert_logs "
                + "(student_id, subject_id, alert_type, channel, "
                + "attendance_percentage, delivery_status) "
                + "VALUES (?, NULL, 'LOW_ATTENDANCE', "
                + "'Email', ?, 'Pending')";

        try (Connection con = DBConnection.getConnection()) {

            con.setAutoCommit(false);

            try {

                /*
                 * Serialize alert creation per student.
                 */
                try (PreparedStatement lock =
                        con.prepareStatement(lockSql)) {

                    lock.setInt(1, student.studentId);

                    try (ResultSet rs = lock.executeQuery()) {

                        if (!rs.next()) {
                            con.rollback();
                            return -1;
                        }
                    }
                }

                /*
                 * Recheck cooldown after obtaining the row lock.
                 */
                try (PreparedStatement check =
                        con.prepareStatement(checkSql)) {

                    check.setInt(1, student.studentId);

                    try (ResultSet rs = check.executeQuery()) {

                        if (rs.next()) {
                            con.rollback();
                            return -1;
                        }
                    }
                }

                /*
                 * Insert Pending record.
                 */
                try (PreparedStatement insert =
                        con.prepareStatement(
                                insertSql,
                                PreparedStatement.RETURN_GENERATED_KEYS)) {

                    insert.setInt(1, student.studentId);

                    insert.setBigDecimal(
                            2,
                            student.percentage.setScale(
                                    2,
                                    RoundingMode.HALF_UP
                            )
                    );

                    insert.executeUpdate();

                    try (ResultSet keys = insert.getGeneratedKeys()) {

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

    /*
     * UPDATE DELIVERY STATUS
     */
    private static void updateAlertStatus(
            long alertId,
            boolean sent
    ) throws Exception {

        String sql = sent
                ? "UPDATE attendance_alert_logs "
                  + "SET delivery_status = 'Sent', "
                  + "sent_at = CURRENT_TIMESTAMP "
                  + "WHERE alert_id = ?"
                : "UPDATE attendance_alert_logs "
                  + "SET delivery_status = 'Failed' "
                  + "WHERE alert_id = ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

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
