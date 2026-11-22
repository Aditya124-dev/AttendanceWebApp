
package com.attendance;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/scheduledAttendanceAlerts")
public class ScheduledAttendanceAlertServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String expectedToken =
                System.getenv("ATTENDANCE_SCHEDULER_TOKEN");

        String providedToken =
                request.getHeader("Authorization");

        if (expectedToken == null || expectedToken.isBlank()) {
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            response.getWriter().write(
                    "{\"status\":\"error\",\"message\":\"Scheduler not configured\"}"
            );
            return;
        }

        String expectedHeader = "Bearer " + expectedToken;

        if (providedToken == null ||
                !MessageDigest.isEqual(
                        expectedHeader.getBytes(StandardCharsets.UTF_8),
                        providedToken.getBytes(StandardCharsets.UTF_8))) {

            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write(
                    "{\"status\":\"error\",\"message\":\"Unauthorized\"}"
            );
            return;
        }

        try {
            int sentCount =
                    AttendanceAlertService.sendLowAttendanceAlerts();

            response.setStatus(HttpServletResponse.SC_OK);
            response.getWriter().write(
                    "{\"status\":\"success\",\"emailsSent\":"
                    + sentCount + "}"
            );

        } catch (Exception e) {

            getServletContext().log(
                    "Scheduled attendance alert execution failed.", e
            );

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
            );

            response.getWriter().write(
                    "{\"status\":\"error\",\"message\":\"Alert execution failed\"}"
            );
        }
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
    }
}
