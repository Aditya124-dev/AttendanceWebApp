
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    boolean otpSent = Boolean.TRUE.equals(request.getAttribute("otpSent"));
    boolean otpVerified = Boolean.TRUE.equals(request.getAttribute("otpVerified"));
    String message = (String) request.getAttribute("message");
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Forgot Password | AttendancePro</title>

<style>
* {
    box-sizing: border-box;
    font-family: Arial, sans-serif;
}
body {
    margin: 0;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
    background: linear-gradient(135deg, #101b3c, #2455a4);
}
.container {
    width: 100%;
    max-width: 420px;
    background: white;
    padding: 35px;
    border-radius: 16px;
    box-shadow: 0 15px 40px rgba(0,0,0,.25);
}
h2 {
    text-align: center;
    color: #17376d;
    margin-bottom: 10px;
}
.subtitle {
    text-align: center;
    color: #666;
    font-size: 14px;
    line-height: 1.5;
    margin-bottom: 25px;
}
label {
    display: block;
    font-weight: bold;
    margin: 15px 0 7px;
    color: #333;
}
input {
    width: 100%;
    padding: 13px;
    border: 1px solid #ccc;
    border-radius: 8px;
    font-size: 15px;
}
button {
    width: 100%;
    padding: 14px;
    margin-top: 22px;
    border: none;
    border-radius: 8px;
    background: #2455a4;
    color: white;
    font-size: 16px;
    font-weight: bold;
    cursor: pointer;
}
button:hover {
    background: #17376d;
}
.message {
    padding: 12px;
    border-radius: 7px;
    margin-bottom: 15px;
    font-size: 14px;
    background: #e8f5e9;
    color: #216b32;
}
.error {
    background: #ffebee;
    color: #b3261e;
}
.back {
    display: block;
    text-align: center;
    margin-top: 22px;
    color: #2455a4;
    text-decoration: none;
    font-size: 14px;
}
</style>
</head>

<body>
<div class="container">

    <h2>Forgot Password?</h2>
    <p class="subtitle">
        Reset your Student Attendance account password securely.
    </p>

    <% if (message != null) { %>
        <div class="message"><%= message %></div>
    <% } %>

    <% if (error != null) { %>
        <div class="message error"><%= error %></div>
    <% } %>

    <% if (!otpSent) { %>

        <form action="<%= request.getContextPath() %>/sendResetOtp"
              method="post">

            <label>Registered Email Address</label>
            <input type="email" name="email"
                   placeholder="Enter your registered email"
                   maxlength="150" required>

            <button type="submit">Send OTP</button>
        </form>

    <% } else if (!otpVerified) { %>

        <form action="<%= request.getContextPath() %>/verifyResetOtp"
              method="post">

            <label>Enter 6-Digit OTP</label>
            <input type="text" name="otp"
                   placeholder="Enter OTP received on email"
                   inputmode="numeric"
                   pattern="[0-9]{6}"
                   maxlength="6" required>

            <button type="submit">Verify OTP</button>
        </form>

    <% } else { %>

        <form action="<%= request.getContextPath() %>/resetPassword"
              method="post">

            <label>New Password</label>
            <input type="password" name="newPassword"
                   placeholder="Enter new password"
                   minlength="8" maxlength="72" required>

            <label>Confirm New Password</label>
            <input type="password" name="confirmPassword"
                   placeholder="Confirm new password"
                   minlength="8" maxlength="72" required>

            <button type="submit">Reset Password</button>
        </form>

    <% } %>

    <a class="back"
       href="<%= request.getContextPath() %>/studentLogin.jsp">
       ← Back to Student Login
    </a>

</div>
</body>
</html>
