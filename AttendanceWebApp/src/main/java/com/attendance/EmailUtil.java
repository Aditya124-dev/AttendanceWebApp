
package com.attendance;

public final class EmailUtil {

    private EmailUtil() {
    }

    public static void sendOtp(String recipientEmail, String otp)
            throws Exception {

        if (recipientEmail == null || recipientEmail.isBlank()
                || otp == null || otp.isBlank()) {

            throw new IllegalArgumentException(
                    "Recipient email and OTP are required."
            );
        }

        String subject = "AttendancePro - Password Reset OTP";

        String message =
                "Hello,\n\n"
                + "Your password reset OTP is: " + otp + "\n\n"
                + "This OTP is valid for 5 minutes.\n"
                + "Do not share this OTP with anyone.\n\n"
                + "If you did not request this, ignore this email.\n\n"
                + "AttendancePro - Student Attendance Management System";

        GmailApiEmailSender.sendText(
                recipientEmail,
                subject,
                message
        );
    }
}
