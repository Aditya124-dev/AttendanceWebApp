
package com.attendance;

import java.io.IOException;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/attendanceAlertPreview")
public class AttendanceAlertPreviewServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(
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

        try {
            List<AttendanceAlertService.AlertPreview> preview =
                    AttendanceAlertService.getLowAttendancePreview();

            request.setAttribute("alertPreview", preview);

            request.getRequestDispatcher(
                    "/attendanceAlertPreview.jsp"
            ).forward(request, response);

        } catch (Exception e) {

            getServletContext().log(
                    "Attendance alert preview failed.",
                    e
            );

            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Unable to generate attendance alert preview."
            );
        }
    }
}
