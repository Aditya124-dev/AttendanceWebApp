
package com.attendance;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Scanner;

public class SetupTeacherPassword {

    public static void main(String[] args) throws Exception {

        Scanner sc = new Scanner(System.in);

        System.out.print("Enter teacher ID: ");
        int teacherId = Integer.parseInt(sc.nextLine().trim());

        System.out.print("Create teacher password (minimum 8 characters): ");
        String password = sc.nextLine();

        if (password.length() < 8) {
            System.out.println("Password must be at least 8 characters.");
            sc.close();
            return;
        }

        try (Connection con = DBConnection.getConnection()) {

            try (PreparedStatement check = con.prepareStatement(
                    "SELECT teacher_id FROM teachers "
                    + "WHERE teacher_id = ? AND is_active = 1")) {

                check.setInt(1, teacherId);

                try (ResultSet rs = check.executeQuery()) {
                    if (!rs.next()) {
                        System.out.println("Active teacher ID not found.");
                        sc.close();
                        return;
                    }
                }
            }

            String salt = PasswordUtil.generateSalt();
            String hash = PasswordUtil.hashPassword(password, salt);

            String sql =
                "INSERT INTO teacher_accounts "
                + "(teacher_id, password_hash, password_salt) "
                + "VALUES (?, ?, ?) "
                + "ON DUPLICATE KEY UPDATE "
                + "password_hash = VALUES(password_hash), "
                + "password_salt = VALUES(password_salt)";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, teacherId);
                ps.setString(2, hash);
                ps.setString(3, salt);
                ps.executeUpdate();
            }

            System.out.println("Teacher password saved successfully.");
        } finally {
            sc.close();
        }
    }
}
