
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Teacher Login | AttendancePro</title>
<style>
* { box-sizing: border-box; }
body {
    margin: 0;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: Arial, sans-serif;
    background: linear-gradient(135deg, #102542, #2457a7);
    padding: 20px;
}
.login-card {
    background: white;
    width: 100%;
    max-width: 420px;
    padding: 35px;
    border-radius: 16px;
    box-shadow: 0 15px 40px rgba(0,0,0,.2);
}
h1 { margin: 0 0 8px; color: #17365d; }
.subtitle { color: #667085; margin-bottom: 25px; }
label { display: block; margin: 16px 0 7px; font-weight: bold; }
input {
    width: 100%;
    padding: 12px;
    border: 1px solid #ccd3df;
    border-radius: 8px;
    font-size: 15px;
}
button {
    width: 100%;
    margin-top: 24px;
    padding: 13px;
    background: #2457a7;
    color: white;
    border: 0;
    border-radius: 8px;
    font-size: 16px;
    font-weight: bold;
    cursor: pointer;
}
button:hover { background: #173f80; }
.error { color: #b42318; margin-top: 15px; }
.back { display: block; margin-top: 20px; text-align: center; color: #2457a7; }
</style>
</head>
<body>
<div class="login-card">
    <h1>Teacher Login</h1>
    <p class="subtitle">Sign in to manage student attendance.</p>

    <% if (request.getAttribute("error") != null) { %>
        <p class="error"><%= request.getAttribute("error") %></p>
    <% } %>

    <form action="<%= request.getContextPath() %>/teacherLogin" method="post">
        <label for="teacherCode">Teacher Code</label>
        <input type="text" id="teacherCode" name="teacherCode"
               maxlength="30" required autocomplete="username">

        <label for="password">Password</label>
        <input type="password" id="password" name="password"
               required autocomplete="current-password">

        <button type="submit">Login</button>
    </form>

    <a class="back" href="<%= request.getContextPath() %>/index.jsp">Back to Home</a>
</div>
</body>
</html>
