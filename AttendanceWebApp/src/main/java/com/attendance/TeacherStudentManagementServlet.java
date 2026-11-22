
package com.attendance;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@WebServlet("/teacherStudents")
public class TeacherStudentManagementServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private boolean isTeacher(HttpSession session) {
        return session != null
                && session.getAttribute("teacherId") instanceof Integer
                && "TEACHER".equals(session.getAttribute("userRole"));
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (!isTeacher(session)) {
            response.sendRedirect(
                    request.getContextPath() + "/teacherLogin.jsp");
            return;
        }

        String csrfToken = (String) session.getAttribute("studentMgmtCsrf");

        if (csrfToken == null) {
            csrfToken = UUID.randomUUID().toString();
            session.setAttribute("studentMgmtCsrf", csrfToken);
        }

        String search = request.getParameter("search");
        String status = request.getParameter("status");

        if (search == null) search = "";
        if (status == null || !status.matches("active|archived|all")) {
            status = "active";
        }

        List<Map<String, Object>> students = new ArrayList<>();

        String sql =
                "SELECT s.student_id, s.roll_no, s.name, s.course, "
                + "s.semester, s.email, s.phone, s.is_active, "
                + "CASE WHEN sa.student_id IS NULL THEN 0 ELSE 1 END "
                + "AS has_account "
                + "FROM students s "
                + "LEFT JOIN student_accounts sa "
                + "ON sa.student_id = s.student_id "
                + "WHERE (? = 'all' "
                + "OR (? = 'active' AND s.is_active = 1) "
                + "OR (? = 'archived' AND s.is_active = 0)) "
                + "AND (? = '' OR s.roll_no LIKE ? "
                + "OR s.name LIKE ? OR s.email LIKE ? "
                + "OR s.phone LIKE ?) "
                + "ORDER BY s.is_active DESC, s.name ASC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            String pattern = "%" + search.trim() + "%";

            ps.setString(1, status);
            ps.setString(2, status);
            ps.setString(3, status);
            ps.setString(4, search.trim());
            ps.setString(5, pattern);
            ps.setString(6, pattern);
            ps.setString(7, pattern);
            ps.setString(8, pattern);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> student = new HashMap<>();

                    student.put("studentId", rs.getInt("student_id"));
                    student.put("rollNo", rs.getString("roll_no"));
                    student.put("name", rs.getString("name"));
                    student.put("course", rs.getString("course"));
                    student.put("semester", rs.getObject("semester"));
                    student.put("email", rs.getString("email"));
                    student.put("phone", rs.getString("phone"));
                    student.put("active", rs.getInt("is_active") == 1);
                    student.put("hasAccount",
                            rs.getInt("has_account") == 1);

                    students.add(student);
                }
            }

        } catch (SQLException e) {
            getServletContext().log(
                    "Student management list failed.", e);

            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Unable to load student records.");
            return;
        }

        request.setAttribute("students", students);
        request.setAttribute("search", search);
        request.setAttribute("status", status);

        request.getRequestDispatcher(
                "/teacherStudentManagement.jsp")
                .forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (!isTeacher(session)) {
            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Teacher login required.");
            return;
        }

        String suppliedToken = request.getParameter("csrfToken");
        String savedToken =
                (String) session.getAttribute("studentMgmtCsrf");

        if (suppliedToken == null || savedToken == null
                || !MessageDigest.isEqual(
                        suppliedToken.getBytes(java.nio.charset.StandardCharsets.UTF_8),
                        savedToken.getBytes(java.nio.charset.StandardCharsets.UTF_8))) {

            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Invalid security token. Reload the management page.");
            return;
        }

        String action = request.getParameter("action");

        try {
            if ("update".equals(action)) {
                updateStudent(request);
                setMessage(session, "Student details updated successfully.");

            } else if ("archive".equals(action)) {
                changeStudentStatus(request, false);
                setMessage(session,
                        "Student archived. Attendance history has been preserved.");

            } else if ("restore".equals(action)) {
                changeStudentStatus(request, true);
                setMessage(session, "Student account restored successfully.");

            } else {
                throw new IllegalArgumentException("Invalid operation.");
            }

        } catch (IllegalArgumentException e) {
            setMessage(session, e.getMessage());

        } catch (SQLException e) {
            getServletContext().log(
                    "Teacher student management database operation failed.", e);

            if ("23000".equals(e.getSQLState())) {
                setMessage(session,
                        "This roll number is already assigned to another student.");
            } else {
                setMessage(session,
                        "Database operation failed. Please try again.");
            }

        } catch (Exception e) {
            getServletContext().log(
                    "Teacher student management operation failed.", e);

            setMessage(session,
                    "Operation failed. Please try again.");
        }

        String search = request.getParameter("search");
        String status = request.getParameter("status");

        String redirect = request.getContextPath() + "/teacherStudents";

        if (search != null || status != null) {
            redirect += "?search=" + encode(search)
                    + "&status=" + encode(status);
        }

        response.sendRedirect(redirect);
    }

    private void updateStudent(HttpServletRequest request)
            throws SQLException {

        int studentId = getStudentId(request);

        String rollNo = trim(request.getParameter("rollNo"));
        String name = trim(request.getParameter("name"));
        String course = trim(request.getParameter("course"));
        String semesterText = trim(request.getParameter("semester"));
        String email = trim(request.getParameter("email"));
        String phone = trim(request.getParameter("phone"));

        if (rollNo.isEmpty() || name.isEmpty()) {
            throw new IllegalArgumentException(
                    "Roll number and student name are required.");
        }
        if (!rollNo.matches("[0-9]{13}")) {
            throw new IllegalArgumentException(
                    "Roll number must contain exactly 13 digits.");
        }

        if (name.length() > 100
                || course.length() > 50 || email.length() > 150
                || phone.length() > 20) {
            throw new IllegalArgumentException(
                    "One or more fields exceed the allowed length.");
        }

        if (!email.isEmpty()
                && !email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
            throw new IllegalArgumentException(
                    "Please enter a valid email address.");
        }

        if (!phone.isEmpty() && !phone.matches("[0-9]{10}")) {
            throw new IllegalArgumentException(
                    "Phone number must contain exactly 10 digits.");
        }

        Integer semester = null;

        if (!semesterText.isEmpty()) {
            try {
                semester = Integer.parseInt(semesterText);
                if (semester < 1) {
                    throw new IllegalArgumentException(
                            "Semester must be at least 1.");
                }
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException(
                        "Please enter a valid semester.");
            }
        }

        String sql =
                "UPDATE students SET roll_no=?, name=?, course=?, "
                + "semester=?, email=?, phone=? "
                + "WHERE student_id=?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, rollNo);
            ps.setString(2, name);
            ps.setString(3, course);

            if (semester == null) {
                ps.setNull(4, java.sql.Types.INTEGER);
            } else {
                ps.setInt(4, semester);
            }

            ps.setString(5, email.isEmpty() ? null : email);
            ps.setString(6, phone.isEmpty() ? null : phone);
            ps.setInt(7, studentId);

            if (ps.executeUpdate() != 1) {
                throw new IllegalArgumentException(
                        "Student record was not found.");
            }
        }
    }

    private void changeStudentStatus(HttpServletRequest request,
                                     boolean active)
            throws SQLException {

        int studentId = getStudentId(request);
        String checkSql = "SELECT is_active FROM students WHERE student_id=?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement check = con.prepareStatement(checkSql)) {

            check.setInt(1, studentId);

            try (ResultSet rs = check.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException("Student record was not found.");
                }
                if (rs.getInt("is_active") == (active ? 1 : 0)) {
                    return;
                }
            }

            String updateSql = "UPDATE students SET is_active=? WHERE student_id=?";

            try (PreparedStatement update = con.prepareStatement(updateSql)) {
                update.setInt(1, active ? 1 : 0);
                update.setInt(2, studentId);

                if (update.executeUpdate() != 1) {
                    throw new SQLException("Student status update failed.");
                }
            }
        }
    }

    private void resetStudentPassword(HttpServletRequest request)
            throws Exception {

        int studentId = getStudentId(request);
        String password = request.getParameter("newPassword");

        if (password == null || password.length() < 8 || password.length() > 72) {
            throw new IllegalArgumentException("Password must be 8 to 72 characters long.");
        }

        long nonWhitespace = password.chars()
                .filter(c -> !Character.isWhitespace(c))
                .count();

        if (nonWhitespace < 8) {
            throw new IllegalArgumentException(
                    "Password must contain at least 8 non-space characters.");
        }

        String salt = PasswordUtil.generateSalt();
        String hash = PasswordUtil.hashPassword(password, salt);

        String sql =
                "INSERT INTO student_accounts "
                + "(student_id, password_hash, password_salt) "
                + "SELECT student_id, ?, ? FROM students "
                + "WHERE student_id=? AND is_active=1 "
                + "ON DUPLICATE KEY UPDATE "
                + "password_hash=VALUES(password_hash), "
                + "password_salt=VALUES(password_salt)";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, hash);
            ps.setString(2, salt);
            ps.setInt(3, studentId);

            int affectedRows = ps.executeUpdate();

            if (affectedRows != 1 && affectedRows != 2) {
                throw new IllegalArgumentException(
                        "Password reset failed. Student may be inactive or unavailable.");
            }
        }
    }
    private int getStudentId(HttpServletRequest request) {
        try {
            int id = Integer.parseInt(
                    request.getParameter("studentId"));

            if (id <= 0) {
                throw new NumberFormatException();
            }

            return id;

        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(
                    "Invalid student ID.");
        }
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private void setMessage(HttpSession session, String message) {
        session.setAttribute("studentMgmtMessage", message);
    }

    private String encode(String value) {
        try {
            return java.net.URLEncoder.encode(
                    value == null ? "" : value,
                    java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            return "";
        }
    }
}
