<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<%!
    private String escapeHtml(String value) {
        if (value == null) return "";

        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1">

    <title>Student Registration</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            font-family: Arial, sans-serif;
            background: #f1f5ff;
            color: #192747;
        }

        .card {
            width: 100%;
            max-width: 430px;
            background: white;
            padding: 34px;
            border-radius: 18px;
            box-shadow: 0 12px 35px rgba(34, 51, 100, .09);
        }

        .logo {
            width: 55px;
            height: 55px;
            display: grid;
            place-items: center;
            border-radius: 15px;
            background: #4d5fe5;
            color: white;
            font-size: 25px;
            font-weight: bold;
            margin-bottom: 22px;
        }

        h1 {
            margin: 0 0 9px;
            font-size: 26px;
        }

        .muted {
            color: #758198;
            font-size: 13px;
            line-height: 1.6;
            margin-bottom: 25px;
        }

        label {
            display: block;
            margin: 16px 0 7px;
            font-size: 13px;
            font-weight: bold;
        }

        input {
            width: 100%;
            padding: 13px;
            border: 1px solid #dce2ee;
            border-radius: 9px;
            font-size: 14px;
        }

        input:focus {
            outline: 2px solid #dce3ff;
            border-color: #4d5fe5;
        }

        button {
            width: 100%;
            margin-top: 24px;
            padding: 14px;
            border: none;
            border-radius: 9px;
            background: #4d5fe5;
            color: white;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
        }

        button:hover { background: #3548cf; }

        .error {
            padding: 12px;
            border-radius: 8px;
            background: #fff0f0;
            color: #a92727;
            font-size: 13px;
            margin-bottom: 15px;
        }

        .bottom {
            text-align: center;
            color: #758198;
            font-size: 13px;
            margin-top: 23px;
        }

        a {
            color: #4055dc;
            text-decoration: none;
            font-weight: bold;
        }
    </style>
</head>

<body>
<div class="card">

    <div class="logo">S</div>

    <h1>Create Student Account</h1>

    <p class="muted">
        Use the roll number and name already registered
        in your college attendance system.
    </p>

    <%
        String error = (String) request.getAttribute("error");

        if (error != null) {
    %>
        <div class="error"><%= escapeHtml(error) %></div>
    <%
        }
    %>

    <form action="<%= request.getContextPath() %>/studentRegister"
          method="post">

        <label for="rollNo">Roll Number</label>
        <input id="rollNo"
               type="text"
               name="rollNo"
               maxlength="50"
               autocomplete="username"
               required>

        <label for="name">Full Name</label>
        <input id="name"
               type="text"
               name="name"
               maxlength="100"
               required>

        <label for="password">Create Password</label>
        <input id="password"
               type="password"
               name="password"
               minlength="8"
               autocomplete="new-password"
               required>

        <label for="confirmPassword">Confirm Password</label>
        <input id="confirmPassword"
               type="password"
               name="confirmPassword"
               minlength="8"
               autocomplete="new-password"
               required>

        <button type="submit">Create Account</button>
    </form>

    <div class="bottom">
        Already registered?
        <a href="studentLogin.jsp">Sign in</a>
    </div>

</div>
</body>
</html>