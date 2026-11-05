
package com.attendance;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

@WebServlet("/studentProfilePhoto")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 5 * 1024 * 1024,
    maxRequestSize = 6 * 1024 * 1024
)
public class StudentProfilePhotoServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final long MAX_PHOTO_SIZE = 5L * 1024 * 1024;

    private String detectImageType(byte[] data) {

        if (data == null) {
            return null;
        }

        // JPEG
        if (data.length >= 3
                && (data[0] & 0xff) == 0xff
                && (data[1] & 0xff) == 0xd8
                && (data[2] & 0xff) == 0xff) {
            return "image/jpeg";
        }

        // PNG
        if (data.length >= 8
                && (data[0] & 0xff) == 0x89
                && data[1] == 0x50
                && data[2] == 0x4e
                && data[3] == 0x47
                && data[4] == 0x0d
                && data[5] == 0x0a
                && data[6] == 0x1a
                && data[7] == 0x0a) {
            return "image/png";
        }

        // WEBP
        if (data.length >= 12
                && data[0] == 'R'
                && data[1] == 'I'
                && data[2] == 'F'
                && data[3] == 'F'
                && data[8] == 'W'
                && data[9] == 'E'
                && data[10] == 'B'
                && data[11] == 'P') {
            return "image/webp";
        }

        return null;
    }

    private Integer getLoggedInStudentId(HttpServletRequest request) {

        HttpSession session = request.getSession(false);

        if (session == null) {
            return null;
        }

        Object studentId = session.getAttribute("studentId");

        if (studentId instanceof Integer) {
            return (Integer) studentId;
        }

        return null;
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Integer studentId = getLoggedInStudentId(request);

        if (studentId == null) {
            response.sendRedirect(
                request.getContextPath() + "/studentLogin.jsp");
            return;
        }

        Part photoPart = request.getPart("profilePhoto");

        if (photoPart == null || photoPart.getSize() == 0) {
            response.sendRedirect(
                request.getContextPath()
                + "/studentprofile.jsp?photo=empty");
            return;
        }

        if (photoPart.getSize() > MAX_PHOTO_SIZE) {
            response.sendError(
                HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE,
                "Maximum photo size is 5 MB.");
            return;
        }

        byte[] photoBytes;

        try (var input = photoPart.getInputStream()) {
            photoBytes = input.readAllBytes();
        }

        String imageType = detectImageType(photoBytes);

        if (imageType == null) {
            response.sendError(
                HttpServletResponse.SC_UNSUPPORTED_MEDIA_TYPE,
                "Only valid JPG, PNG and WEBP images are allowed.");
            return;
        }

        String sql =
            "UPDATE students SET profile_photo = ? WHERE student_id = ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setBytes(1, photoBytes);
            ps.setInt(2, studentId);

            int updated = ps.executeUpdate();

            if (updated == 1) {

                response.sendRedirect(
                    request.getContextPath()
                    + "/studentprofile.jsp?photo=success");

            } else {

                response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "Student profile not found.");
            }

        } catch (Exception e) {

            getServletContext().log(
                "Student profile photo upload failed", e);

            response.sendError(
                HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                "Unable to upload profile photo.");
        }
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Integer studentId = getLoggedInStudentId(request);

        if (studentId == null) {
            response.sendError(
                HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        String sql =
            "SELECT profile_photo FROM students WHERE student_id = ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, studentId);

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND);
                    return;
                }

                byte[] photo = rs.getBytes("profile_photo");

                if (photo == null || photo.length == 0) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND);
                    return;
                }

                String contentType = detectImageType(photo);

                if (contentType == null) {
                    response.sendError(
                        HttpServletResponse.SC_UNSUPPORTED_MEDIA_TYPE);
                    return;
                }

                response.setContentType(contentType);
                response.setHeader(
                    "Cache-Control", "private, no-store");
                response.setContentLength(photo.length);

                response.getOutputStream().write(photo);
            }

        } catch (Exception e) {

            getServletContext().log(
                "Student profile photo display failed", e);

            response.sendError(
                HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
}
