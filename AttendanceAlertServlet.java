
package com.attendance;

import java.io.IOException;

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
            HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("teacherId") == null) {

            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Please log in as a teacher first."
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
                    "Attendance alert processing failed.", e
            );

            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Attendance alerts could not be processed. "
                    + "Check the server log."
            );
        }
    }
}
