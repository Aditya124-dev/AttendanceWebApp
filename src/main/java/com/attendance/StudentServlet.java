
package com.attendance;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;

@WebServlet("/addStudent")
public class StudentServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        String rollNo = request.getParameter("rollNo");
        String name = request.getParameter("name");
        String course = request.getParameter("course");
        String semester = request.getParameter("semester");

        try {
            String sql = "INSERT INTO students "
                    + "(roll_no, name, course, semester) "
                    + "VALUES (?, ?, ?, ?)";

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(sql)) {

                ps.setString(1, rollNo);
                ps.setString(2, name);
                ps.setString(3, course);
                ps.setInt(4, Integer.parseInt(semester));

                int result = ps.executeUpdate();

                if (result > 0) {
                    response.getWriter().println(
                        "<h2>Student added successfully!</h2>");
                    response.getWriter().println(
                        "<a href='index.jsp'>Go to Home</a>");
                }
            }

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().println("<h2>Unable to add student</h2>");
            response.getWriter().println("<p>" + e.getMessage() + "</p>");
            response.getWriter().println(
                "<a href='addStudent.jsp'>Go Back</a>");
        }
    }
}
