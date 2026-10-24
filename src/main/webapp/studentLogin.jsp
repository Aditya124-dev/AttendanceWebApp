
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
          content="width=device-width, initial-scale=1.0">

    <title>Student Login | AttendancePro</title>

    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            min-height: 100vh;
            padding: 25px;
            display: flex;
            justify-content: center;
            align-items: center;
            background: #eef2ff;
            background-image:
                radial-gradient(circle at 10% 10%, #dbe6ff 0, transparent 35%),
                radial-gradient(circle at 90% 90%, #e5dcff 0, transparent 35%);
            color: #192746;
            font-family: "Segoe UI", Arial, sans-serif;
        }

        .app {
            width: 100%;
            max-width: 1050px;
            min-height: 600px;
            display: grid;
            grid-template-columns: 1.05fr 0.95fr;
            overflow: hidden;
            border-radius: 26px;
            background: white;
            box-shadow: 0 25px 70px rgba(30, 47, 100, 0.14);
        }

        /* LEFT BRAND PANEL */

        .brand-panel {
            position: relative;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            padding: 38px;
            color: white;
            background: linear-gradient(145deg, #172554, #3548a8 65%, #6558d9);
        }

        .brand-panel::before,
        .brand-panel::after {
            content: "";
            position: absolute;
            border: 1px solid rgba(255,255,255,.13);
            border-radius: 50%;
            pointer-events: none;
        }

        .brand-panel::before {
            width: 360px;
            height: 360px;
            right: -145px;
            top: 130px;
        }

        .brand-panel::after {
            width: 260px;
            height: 260px;
            right: -95px;
            top: 180px;
        }

        .brand,
        .hero,
        .brand-footer {
            position: relative;
            z-index: 1;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .brand-logo {
            width: 46px;
            height: 46px;
            display: flex;
            justify-content: center;
            align-items: center;
            border-radius: 14px;
            background: rgba(255,255,255,.16);
            border: 1px solid rgba(255,255,255,.25);
            font-size: 23px;
            font-weight: 800;
        }

        .brand-name {
            font-size: 19px;
            font-weight: 750;
            letter-spacing: .2px;
        }

        .brand-caption {
            margin-top: 4px;
            color: #c7d2fe;
            font-size: 10px;
            letter-spacing: 1.8px;
        }

        .hero {
            margin: 45px 0;
        }

        .hero-label {
            display: inline-block;
            padding: 8px 12px;
            border-radius: 25px;
            border: 1px solid rgba(255,255,255,.2);
            background: rgba(255,255,255,.09);
            color: #e0e7ff;
            font-size: 11px;
            letter-spacing: .6px;
        }

        .hero h1 {
            max-width: 430px;
            margin-top: 23px;
            font-size: clamp(31px, 3.4vw, 43px);
            line-height: 1.18;
            letter-spacing: -1.3px;
        }

        .hero p {
            max-width: 370px;
            margin-top: 18px;
            color: #d2dcff;
            font-size: 14px;
            line-height: 1.8;
        }

        .illustration {
            display: flex;
            justify-content: center;
            align-items: center;
            margin-top: 25px;
        }

        .illustration svg {
            width: 100%;
            max-width: 340px;
            height: auto;
        }

        .brand-footer {
            color: #c7d2fe;
            font-size: 11px;
            line-height: 1.7;
        }

        /* LOGIN PANEL */

        .login-panel {
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 45px clamp(25px, 4.5vw, 54px);
            background: white;
        }

        .mobile-brand {
            display: none;
        }

        .welcome-label {
            color: #5969df;
            font-size: 11px;
            font-weight: 800;
            letter-spacing: 1.8px;
        }

        .login-panel h2 {
            margin-top: 12px;
            font-size: 31px;
            letter-spacing: -.8px;
            color: #192746;
        }

        .subtitle {
            margin-top: 10px;
            margin-bottom: 28px;
            color: #8490a7;
            font-size: 13px;
            line-height: 1.7;
        }

        .message {
            padding: 12px 14px;
            margin-bottom: 17px;
            border-radius: 10px;
            font-size: 12px;
            line-height: 1.6;
        }

        .error {
            color: #a92735;
            background: #fff0f2;
            border: 1px solid #ffd9de;
        }

        .success {
            color: #16734a;
            background: #eafaf1;
            border: 1px solid #cceedd;
        }

        .field {
            margin-bottom: 19px;
        }

        .field label {
            display: block;
            margin-bottom: 8px;
            color: #35425d;
            font-size: 12px;
            font-weight: 700;
        }

        .input-wrap {
            position: relative;
        }

        .input-wrap input {
            width: 100%;
            height: 49px;
            padding: 0 14px;
            border: 1px solid #e0e5ef;
            border-radius: 11px;
            background: #fbfcff;
            color: #1b2944;
            font-size: 14px;
            transition: border-color .2s, box-shadow .2s;
        }

        .input-wrap input:focus {
            outline: none;
            border-color: #5969e8;
            box-shadow: 0 0 0 4px rgba(89,105,232,.10);
            background: white;
        }

        .input-wrap input::placeholder {
            color: #a7b0c2;
        }

        .password-input {
            padding-right: 72px !important;
        }

        .show-password {
            position: absolute;
            top: 0;
            right: 12px;
            height: 49px;
            border: 0;
            background: transparent;
            color: #5969df;
            cursor: pointer;
            font-size: 11px;
            font-weight: 750;
        }

        .login-button {
            width: 100%;
            height: 50px;
            margin-top: 5px;
            border: 0;
            border-radius: 11px;
            background: linear-gradient(100deg, #4357d9, #6659df);
            color: white;
            font-size: 14px;
            font-weight: 750;
            cursor: pointer;
            box-shadow: 0 8px 18px rgba(76,87,212,.22);
            transition: transform .2s, box-shadow .2s;
        }

        .login-button:hover {
            transform: translateY(-1px);
            box-shadow: 0 11px 23px rgba(76,87,212,.30);
        }

        .login-button:active {
            transform: translateY(0);
        }

        .register {
            margin-top: 25px;
            text-align: center;
            color: #8490a7;
            font-size: 12px;
        }

        .register a {
            color: #4c5fe0;
            font-weight: 750;
            text-decoration: none;
        }

        .register a:hover {
            text-decoration: underline;
        }

        .divider {
            height: 1px;
            margin: 25px 0 18px;
            background: #eef0f6;
        }

        .security-note {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 7px;
            color: #8994a8;
            text-align: center;
            font-size: 10px;
            line-height: 1.6;
        }

        .security-icon {
            color: #319b72;
            font-size: 15px;
        }

        .back-home {
            margin-top: 22px;
            text-align: center;
            font-size: 12px;
        }

        .back-home a {
            color: #66738a;
            text-decoration: none;
        }

        .back-home a:hover {
            color: #4257dc;
        }

        /* RESPONSIVE MOBILE APP LOOK */

        @media (max-width: 760px) {
            body {
                padding: 15px;
                align-items: center;
            }

            .app {
                max-width: 450px;
                min-height: auto;
                display: block;
                border-radius: 23px;
            }

            .brand-panel {
                display: none;
            }

            .login-panel {
                padding: 32px 25px;
            }

            .mobile-brand {
                display: flex;
                align-items: center;
                gap: 11px;
                margin-bottom: 32px;
            }

            .mobile-brand .brand-logo {
                background: linear-gradient(135deg, #4357d9, #7562e9);
                color: white;
                border: 0;
            }

            .mobile-brand .brand-name {
                color: #1d2c4e;
                font-size: 18px;
            }

            .mobile-brand .brand-caption {
                color: #8a96ad;
            }

            .login-panel h2 {
                font-size: 29px;
            }

            .subtitle {
                margin-bottom: 25px;
            }

            .divider {
                margin-top: 23px;
            }
        }

        @media (max-width: 360px) {
            body {
                padding: 8px;
            }

            .login-panel {
                padding: 25px 18px;
            }

            .login-panel h2 {
                font-size: 26px;
            }
        }
    </style>
</head>

<body>

<div class="app">

    <!-- LEFT SIDE: APP BRANDING -->
    <section class="brand-panel">

        <div class="brand">
            <div class="brand-logo">A</div>
            <div>
                <div class="brand-name">AttendancePro</div>
                <div class="brand-caption">STUDENT PORTAL</div>
            </div>
        </div>

        <div class="hero">

            <span class="hero-label">YOUR CAMPUS, CONNECTED</span>

            <h1>Your academic journey, all in one place.</h1>

            <p>
                Access your profile, follow your attendance,
                and stay up to date with your academic records
                through your personal student portal.
            </p>

            <div class="illustration">
                <svg viewBox="0 0 340 180"
                     xmlns="http://www.w3.org/2000/svg"
                     role="img"
                     aria-label="Student dashboard illustration">

                    <rect x="33" y="22" width="274" height="143"
                          rx="14" fill="#ffffff" opacity=".12"/>

                    <rect x="44" y="33" width="252" height="122"
                          rx="10" fill="#ffffff"/>

                    <rect x="57" y="45" width="72" height="98"
                          rx="7" fill="#edf0ff"/>

                    <circle cx="93" cy="70" r="17" fill="#b9c3ff"/>
                    <path d="M68 109 Q93 77 118 109 L118 121 L68 121Z"
                          fill="#6574e8"/>

                    <rect x="145" y="48" width="112" height="10"
                          rx="5" fill="#dfe4f5"/>
                    <rect x="145" y="65" width="85" height="6"
                          rx="3" fill="#e9ecf7"/>

                    <rect x="145" y="84" width="65" height="51"
                          rx="7" fill="#e8f8ef"/>
                    <path d="M157 108 L168 118 L190 96"
                          fill="none" stroke="#21a675"
                          stroke-width="5" stroke-linecap="round"
                          stroke-linejoin="round"/>

                    <rect x="220" y="84" width="57" height="51"
                          rx="7" fill="#f0edff"/>
                    <path d="M230 119 L239 107 L247 112 L263 95"
                          fill="none" stroke="#7564e9"
                          stroke-width="3" stroke-linecap="round"
                          stroke-linejoin="round"/>

                    <circle cx="288" cy="28" r="5" fill="#a8b4ff"/>
                    <circle cx="24" cy="139" r="7" fill="#8ee4c1"/>
                </svg>
            </div>

        </div>

        <div class="brand-footer">
            Student Attendance Management System
            <br>
            Smart records. Clear insights. Better tracking.
        </div>

    </section>

    <!-- RIGHT SIDE: LOGIN FORM -->
    <section class="login-panel">

        <div class="mobile-brand">
            <div class="brand-logo">A</div>
            <div>
                <div class="brand-name">AttendancePro</div>
                <div class="brand-caption">STUDENT PORTAL</div>
            </div>
        </div>

        <div class="welcome-label">STUDENT SIGN IN</div>

        <h2>Welcome back!</h2>

        <p class="subtitle">
            Sign in with your student credentials
            to continue to your personal dashboard.
        </p>

        <%
            String error = (String) request.getAttribute("error");

            if (error != null) {
        %>
            <div class="message error">
                <%= escapeHtml(error) %>
            </div>
        <%
            }

            if ("1".equals(request.getParameter("registered"))) {
        %>
            <div class="message success">
                Your account was created successfully.
                Please sign in.
            </div>
        <%
            }

            if ("1".equals(request.getParameter("loggedOut"))) {
        %>
            <div class="message success">
                You have been logged out successfully.
            </div>
        <%
            }
        %>

        <form action="<%= request.getContextPath() %>/studentLogin"
              method="post">

            <div class="field">
                <label for="rollNo">Student Roll Number</label>

                <div class="input-wrap">
                    <input
                        id="rollNo"
                        type="text"
                        name="rollNo"
                        placeholder="Enter your roll number"
                        maxlength="50"
                        autocomplete="username"
                        required>
                </div>
            </div>

            <div class="field">
                <label for="password">Password</label>

                <div class="input-wrap">
                    <input
                        class="password-input"
                        id="password"
                        type="password"
                        name="password"
                        placeholder="Enter your password"
                        autocomplete="current-password"
                        required>

                    <button
                        class="show-password"
                        type="button"
                        id="togglePassword"
                        aria-controls="password"
                        aria-label="Show password">
                        SHOW
                    </button>
                </div>
            </div>

            <button class="login-button" type="submit">
                Sign In to Portal &rarr;
            </button>

        </form>

        <div class="register">
            New student here?
            <a href="studentRegister.jsp">Create an account</a>
        </div>

        <div class="divider"></div>

        <div class="security-note">
            <span class="security-icon">&#10003;</span>
            <span>Personal student access · Your own attendance records</span>
        </div>

        <div class="back-home">
            <a href="index.jsp">&larr; Back to main dashboard</a>
        </div>

    </section>

</div>

<script>
    const passwordInput = document.getElementById("password");
    const togglePassword = document.getElementById("togglePassword");

    togglePassword.addEventListener("click", function () {
        const isHidden = passwordInput.type === "password";

        passwordInput.type = isHidden ? "text" : "password";
        togglePassword.textContent = isHidden ? "HIDE" : "SHOW";
        togglePassword.setAttribute(
            "aria-label",
            isHidden ? "Hide password" : "Show password"
        );
    });
</script>

</body>
</html>
