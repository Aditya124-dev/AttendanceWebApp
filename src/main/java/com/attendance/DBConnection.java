
package com.attendance;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    private static final String URL =
            getEnv("ATTENDANCE_DB_URL",
                   "jdbc:mysql://localhost:3306/attendance_db");

    private static final String USER =
            getEnv("ATTENDANCE_DB_USER", "root");

    // Password is read from an environment variable, not source code.
    private static final String PASSWORD =
            System.getenv("ATTENDANCE_DB_PASSWORD");

    private static String getEnv(String name, String defaultValue) {
        String value = System.getenv(name);
        return (value == null || value.isBlank())
                ? defaultValue : value;
    }

    public static Connection getConnection() throws Exception {

        if (PASSWORD == null || PASSWORD.isBlank()) {
            throw new SQLException(
                "ATTENDANCE_DB_PASSWORD environment variable is not set."
            );
        }

        Class.forName("com.mysql.cj.jdbc.Driver");

        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    public static void main(String[] args) {
        try (Connection connection = getConnection()) {
            System.out.println(
                "MySQL Database Connected Successfully!"
            );
        } catch (Exception e) {
            System.out.println("Database Connection Failed!");
            e.printStackTrace();
        }
    }
}
