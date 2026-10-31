
package com.attendance;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DBConnection {

    private static final String URL = getEnv(
        "ATTENDANCE_DB_URL",
        "jdbc:mysql://attendance-db-adi6268606967-202d.a.aivencloud.com:26394/attendance_db?sslMode=REQUIRED"
    );

    private static final String USER = getEnv(
        "ATTENDANCE_DB_USER",
        "avnadmin"
    );

    private static final String PASSWORD =
        System.getenv("ATTENDANCE_DB_PASSWORD");

    private static String getEnv(String name, String defaultValue) {
        String value = System.getenv(name);

        if (value == null || value.isBlank()) {
            return defaultValue;
        }

        return value.trim();
    }

    public static Connection getConnection() throws SQLException {
        if (PASSWORD == null || PASSWORD.isBlank()) {
            throw new SQLException(
                "ATTENDANCE_DB_PASSWORD environment variable is not set."
            );
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC driver not found.", e);
        }

        Properties properties = new Properties();
        properties.setProperty("user", USER);
        properties.setProperty("password", PASSWORD);
        properties.setProperty("connectionTimeZone", "UTC");
        properties.setProperty("forceConnectionTimeZoneToSession", "false");
        properties.setProperty("preserveInstants", "true");

        return DriverManager.getConnection(URL, properties);
    }
}
