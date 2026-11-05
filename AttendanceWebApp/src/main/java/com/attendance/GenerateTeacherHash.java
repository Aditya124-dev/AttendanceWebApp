
package com.attendance;

public class GenerateTeacherHash {

    public static void main(String[] args) throws Exception {
        String password = "Teacher@123";

        String salt = PasswordUtil.generateSalt();
        String hash = PasswordUtil.hashPassword(password, salt);

        System.out.println("SALT=" + salt);
        System.out.println("HASH=" + hash);
    }
}
