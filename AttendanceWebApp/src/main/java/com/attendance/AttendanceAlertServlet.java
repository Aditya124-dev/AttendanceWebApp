
package com.attendance;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/sendAttendanceAlerts")
public class AttendanceAlertServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("teacherId") == null
                || !"TEACHER".equals(session.getAttribute("userRole"))) {

            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Please log in as a teacher first."
            );
            return;
        }

        String sessionToken =
                (String) session.getAttribute("csrfToken");

        String requestToken =
                request.getParameter("csrfToken");

        if (sessionToken == null
                || requestToken == null
                || !MessageDigest.isEqual(
                        sessionToken.getBytes(StandardCharsets.UTF_8),
                        requestToken.getBytes(StandardCharsets.UTF_8))) {

            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Invalid security token. Refresh the page and try again."
            );
            return;
        }

        try {
            int sentCount =
                    AttendanceAlertService.sendLowAttendanceAlerts();

            session.setAttribute(
                    "attendanceAlertMessage",
                    "Attendance alert process completed. Emails sent: "
                            + sentCount
            );

            response.sendRedirect(
                    request.getContextPath() + "/teacherDashboard.jsp"
            );

        } catch (Exception e) {

            getServletContext().log(
                    "Attendance alert processing failed.",
                    e
            );

            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Attendance alerts could not be processed. "
                            + "Check the server log."
            );
        }
    }
}
