
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

@WebServlet("/sendAttendanceTest")
public class AttendanceAlertTestServlet extends HttpServlet {

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

        String studentIdValue = request.getParameter("studentId");
        String testEmail = request.getParameter("testEmail");

        if (studentIdValue == null || studentIdValue.isBlank()
                || testEmail == null || testEmail.isBlank()) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Student ID and test email are required."
            );
            return;
        }

        try {
            int studentId = Integer.parseInt(studentIdValue.trim());

            AttendanceAlertService.sendTestAlert(
                    studentId,
                    testEmail.trim()
            );

            session.setAttribute(
                    "attendanceAlertMessage",
                    "Test email sent successfully to "
                            + testEmail.trim()
            );

            response.sendRedirect(
                    request.getContextPath()
                            + "/attendanceAlertPreview"
            );

        } catch (NumberFormatException e) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid student ID."
            );

        } catch (IllegalArgumentException e) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    e.getMessage()
            );

        } catch (Exception e) {

            getServletContext().log(
                    "Attendance test email failed.",
                    e
            );

            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Test email failed. Check the server log."
            );
        }
    }
}
