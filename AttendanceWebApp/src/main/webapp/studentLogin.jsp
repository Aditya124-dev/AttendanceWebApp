<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>
<%
    // Login page ko browser/proxy cache na kare (back button se purana form na dikhe)
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    response.setHeader("X-Content-Type-Options", "nosniff");
    response.setHeader("X-Frame-Options", "DENY");
    response.setHeader("Referrer-Policy", "same-origin");
%>
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
<%
    String ctx      = escapeHtml(request.getContextPath());
    String error    = (String) request.getAttribute("error");
    String success  = (String) request.getAttribute("success");
    // Servlet agar login fail hone par "rollNo" attribute set kare to field pre-fill ho jayega
    String prefill  = (String) request.getAttribute("rollNo");
    boolean registered = "1".equals(request.getParameter("registered"));
    boolean loggedOut  = "1".equals(request.getParameter("loggedOut"));
    int year = java.time.Year.now().getValue();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, nofollow">
    <meta name="theme-color" content="#0f3d3e">

    <title>Student Sign In | AttendancePro</title>

    <style>
        :root {
            --ink:        #10282c;
            --ink-soft:   #3d5559;
            --muted:      #66797c;
            --paper:      #f4f6f5;
            --surface:    #ffffff;
            --line:       #d8e0de;
            --brand:      #0f3d3e;
            --brand-2:    #14595a;
            --accent:     #0f766e;
            --accent-hov: #0b5e58;
            --focus:      #1d6fd1;
            --ok-bg:      #e9f6ef;
            --ok-line:    #bfe3cf;
            --ok-text:    #17603d;
            --err-bg:     #fdeeee;
            --err-line:   #f3c4c4;
            --err-text:   #9b1c1c;
            --warn-bg:    #fff6e0;
            --warn-line:  #f1dba0;
            --warn-text:  #7a5200;

            --font-ui:    "Segoe UI", system-ui, -apple-system, "Helvetica Neue", Arial, sans-serif;
            --font-head:  "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
        }

        *, *::before, *::after { box-sizing: border-box; }

        html, body { margin: 0; padding: 0; }

        body {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 18px;
            padding: 28px 20px;
            background: var(--paper);
            color: var(--ink);
            font-family: var(--font-ui);
            font-size: 15px;
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
        }

        a { color: var(--accent); }

        :focus-visible {
            outline: 3px solid var(--focus);
            outline-offset: 2px;
        }

        .skip-link {
            position: absolute;
            left: -9999px;
            top: 8px;
            padding: 10px 14px;
            background: var(--ink);
            color: #fff;
            border-radius: 6px;
            z-index: 10;
        }
        .skip-link:focus { left: 12px; }

        /* ---------- Shell ---------- */
        .shell {
            width: 100%;
            max-width: 1040px;
            display: grid;
            grid-template-columns: 1.02fr 0.98fr;
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: 14px;
            overflow: hidden;
            box-shadow: 0 1px 2px rgba(16, 40, 44, .05), 0 18px 40px -18px rgba(16, 40, 44, .22);
        }

        /* ---------- Brand panel ---------- */
        .brand-panel {
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            gap: 32px;
            padding: 40px 42px;
            color: #e8f1ef;
            background: var(--brand);
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .logo {
            width: 42px;
            height: 42px;
            flex: none;
            display: grid;
            place-items: center;
            border-radius: 10px;
            background: #e8f1ef;
            color: var(--brand);
        }

        .brand-name {
            font-size: 18px;
            font-weight: 650;
            letter-spacing: .2px;
            color: #fff;
        }

        .brand-sub {
            font-size: 13px;
            color: #a9c4c0;
        }

        .hero h1 {
            margin: 0;
            max-width: 15ch;
            font-family: var(--font-head);
            font-weight: 600;
            font-size: clamp(30px, 3.4vw, 40px);
            line-height: 1.15;
            letter-spacing: -.5px;
            color: #fff;
        }

        .hero p {
            margin: 16px 0 0;
            max-width: 44ch;
            font-size: 15px;
            line-height: 1.7;
            color: #bcd3cf;
        }

        /* Attendance register: the one memorable element */
        .register-card {
            margin-top: 28px;
            max-width: 400px;
            padding: 16px 18px 14px;
            border-radius: 10px;
            background: #fff;
            color: var(--ink);
            box-shadow: 0 12px 28px -14px rgba(0, 0, 0, .5);
        }

        .register-head {
            display: flex;
            justify-content: space-between;
            align-items: baseline;
            margin-bottom: 10px;
            font-size: 13px;
            font-weight: 650;
        }

        .register-head span {
            font-weight: 500;
            color: var(--muted);
        }

        .register-grid {
            width: 100%;
            border-collapse: collapse;
            font-size: 12.5px;
        }

        .register-grid th,
        .register-grid td {
            padding: 7px 0;
            text-align: center;
            border-bottom: 1px solid #e8eeec;
        }

        .register-grid th {
            font-weight: 600;
            color: var(--muted);
        }

        .register-grid th:first-child,
        .register-grid td:first-child {
            text-align: left;
            font-weight: 600;
            color: var(--ink-soft);
        }

        .register-grid tr:last-child td { border-bottom: 0; }

        .mark {
            display: inline-block;
            width: 20px;
            height: 20px;
            line-height: 20px;
            border-radius: 50%;
            font-size: 12px;
            font-weight: 700;
        }
        .mark.p { background: #dff3e8; color: #17603d; }
        .mark.a { background: #fbe3e3; color: #9b1c1c; }

        .register-foot {
            margin-top: 10px;
            font-size: 12px;
            color: var(--muted);
        }

        .brand-footer {
            font-size: 13px;
            color: #a9c4c0;
        }

        /* ---------- Form panel ---------- */
        .form-panel {
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 44px clamp(24px, 4.5vw, 56px);
        }

        .mobile-brand { display: none; }

        .form-panel h2 {
            margin: 0;
            font-family: var(--font-head);
            font-size: 30px;
            font-weight: 600;
            letter-spacing: -.4px;
            color: var(--ink);
        }

        .subtitle {
            margin: 8px 0 26px;
            color: var(--muted);
            font-size: 14.5px;
            line-height: 1.6;
        }

        .message {
            display: flex;
            gap: 10px;
            align-items: flex-start;
            margin-bottom: 16px;
            padding: 12px 14px;
            border: 1px solid;
            border-radius: 8px;
            font-size: 13.5px;
            line-height: 1.55;
        }
        .message svg { flex: none; margin-top: 2px; }
        .message.success { background: var(--ok-bg);   border-color: var(--ok-line);   color: var(--ok-text); }
        .message.error   { background: var(--err-bg);  border-color: var(--err-line);  color: var(--err-text); }

        .field { margin-bottom: 18px; }

        .field label {
            display: block;
            margin-bottom: 7px;
            font-size: 13.5px;
            font-weight: 600;
            color: var(--ink-soft);
        }

        .input-wrap { position: relative; }

        .input-wrap input {
            width: 100%;
            height: 48px;
            padding: 0 14px;
            border: 1px solid #c5d0cd;
            border-radius: 8px;
            background: #fff;
            color: var(--ink);
            font: inherit;
            font-size: 15px;
            transition: border-color .15s, box-shadow .15s;
        }

        .input-wrap input::placeholder { color: #94a3a1; }

        .input-wrap input:hover { border-color: #9fb1ad; }

        .input-wrap input:focus {
            outline: none;
            border-color: var(--accent);
            box-shadow: 0 0 0 3px rgba(15, 118, 110, .18);
        }

        .input-wrap input.has-toggle { padding-right: 76px; }

        .toggle-password {
            position: absolute;
            top: 6px;
            right: 6px;
            height: 36px;
            padding: 0 12px;
            border: 0;
            border-radius: 6px;
            background: transparent;
            color: var(--accent);
            font: inherit;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
        }
        .toggle-password:hover { background: #e9f3f1; }

        .caps-warning {
            display: none;
            margin-top: 8px;
            padding: 8px 12px;
            border: 1px solid var(--warn-line);
            border-radius: 6px;
            background: var(--warn-bg);
            color: var(--warn-text);
            font-size: 13px;
        }
        .caps-warning.visible { display: block; }

        .assist {
            margin: -4px 0 20px;
            text-align: right;
            font-size: 13.5px;
        }
        .assist a { font-weight: 600; text-decoration: none; }
        .assist a:hover { text-decoration: underline; }

        .submit {
            width: 100%;
            height: 49px;
            display: inline-flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
            border: 0;
            border-radius: 8px;
            background: var(--accent);
            color: #fff;
            font: inherit;
            font-size: 15px;
            font-weight: 650;
            cursor: pointer;
            transition: background .15s;
        }
        .submit:hover { background: var(--accent-hov); }
        .submit:disabled { background: #6aa8a2; cursor: progress; }

        .spinner {
            display: none;
            width: 16px;
            height: 16px;
            border: 2px solid rgba(255, 255, 255, .45);
            border-top-color: #fff;
            border-radius: 50%;
            animation: spin .7s linear infinite;
        }
        .submit.loading .spinner { display: inline-block; }

        @keyframes spin { to { transform: rotate(360deg); } }

        .signup {
            margin: 22px 0 0;
            text-align: center;
            color: var(--muted);
            font-size: 14px;
        }
        .signup a { font-weight: 600; text-decoration: none; }
        .signup a:hover { text-decoration: underline; }

        .divider {
            height: 1px;
            margin: 24px 0 16px;
            background: var(--line);
        }

        .privacy-note {
            display: flex;
            gap: 8px;
            align-items: flex-start;
            justify-content: center;
            color: var(--muted);
            font-size: 12.5px;
            line-height: 1.55;
            text-align: left;
        }
        .privacy-note svg { flex: none; margin-top: 2px; color: var(--accent); }

        .back-home {
            margin-top: 18px;
            text-align: center;
            font-size: 13.5px;
        }
        .back-home a { color: var(--ink-soft); text-decoration: none; }
        .back-home a:hover { color: var(--accent); text-decoration: underline; }

        .page-footer {
            color: var(--muted);
            font-size: 12.5px;
            text-align: center;
        }

        /* ---------- Responsive ---------- */
        @media (max-width: 860px) {
            .shell { grid-template-columns: 1fr; max-width: 460px; }
            .brand-panel { display: none; }
            .form-panel { padding: 32px 24px; }

            .mobile-brand {
                display: flex;
                align-items: center;
                gap: 11px;
                margin-bottom: 28px;
            }
            .mobile-brand .logo { background: var(--brand); color: #fff; }
            .mobile-brand .brand-name { color: var(--ink); }
            .mobile-brand .brand-sub  { color: var(--muted); }
        }

        @media (max-width: 380px) {
            body { padding: 12px 8px; }
            .form-panel { padding: 26px 18px; }
            .form-panel h2 { font-size: 26px; }
        }

        @media (prefers-reduced-motion: reduce) {
            *, *::before, *::after {
                animation-duration: .01ms !important;
                transition-duration: .01ms !important;
            }
        }
    </style>
</head>

<body>

<a class="skip-link" href="#rollNo">Skip to sign in form</a>

<main class="shell">

    <!-- ===== Brand panel ===== -->
    <section class="brand-panel" aria-label="About AttendancePro">

        <div class="brand">
            <div class="logo" aria-hidden="true">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                     stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="4" y="5" width="16" height="15" rx="2.5"/>
                    <path d="M8 3v4M16 3v4M4 10h16"/>
                    <path d="M9 15l2 2 4-4"/>
                </svg>
            </div>
            <div>
                <div class="brand-name">AttendancePro</div>
                <div class="brand-sub">Student Portal</div>
            </div>
        </div>

        <div class="hero">
            <h1>Know exactly where your attendance stands.</h1>
            <p>
                Check your subject-wise attendance, review your records,
                and keep your profile up to date, all from one place.
            </p>

            <div class="register-card" role="img"
                 aria-label="Sample attendance register showing present and absent marks for the week">
                <div class="register-head">
                    This week
                    <span>Sample view</span>
                </div>
                <table class="register-grid" aria-hidden="true">
                    <thead>
                        <tr><th></th><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th></tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Mathematics</td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark a">A</span></td>
                            <td><span class="mark p">P</span></td>
                        </tr>
                        <tr>
                            <td>Physics</td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark a">A</span></td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark p">P</span></td>
                        </tr>
                        <tr>
                            <td>Computer Sci.</td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark p">P</span></td>
                            <td><span class="mark p">P</span></td>
                        </tr>
                    </tbody>
                </table>
                <div class="register-foot">P = Present, A = Absent</div>
            </div>
        </div>

        <div class="brand-footer">
            Student Attendance Management System
        </div>

    </section>

    <!-- ===== Form panel ===== -->
    <section class="form-panel" aria-labelledby="signin-title">

        <div class="mobile-brand">
            <div class="logo" aria-hidden="true">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                     stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="4" y="5" width="16" height="15" rx="2.5"/>
                    <path d="M8 3v4M16 3v4M4 10h16"/>
                    <path d="M9 15l2 2 4-4"/>
                </svg>
            </div>
            <div>
                <div class="brand-name">AttendancePro</div>
                <div class="brand-sub">Student Portal</div>
            </div>
        </div>

        <h2 id="signin-title">Sign in to your account</h2>

        <p class="subtitle">
            Use your roll number and password to view your attendance.
        </p>

        <% if (success != null) { %>
            <div class="message success" role="status">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                     stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>
                </svg>
                <span><%= escapeHtml(success) %></span>
            </div>
        <% } %>

        <% if (registered) { %>
            <div class="message success" role="status">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                     stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>
                </svg>
                <span>Your account has been created. Sign in to continue.</span>
            </div>
        <% } %>

        <% if (loggedOut) { %>
            <div class="message success" role="status">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                     stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>
                </svg>
                <span>You have been signed out.</span>
            </div>
        <% } %>

        <% if (error != null) { %>
            <div class="message error" role="alert">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                     stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <circle cx="12" cy="12" r="9"/><path d="M12 7.5v5M12 16h.01"/>
                </svg>
                <span><%= escapeHtml(error) %></span>
            </div>
        <% } %>

        <form id="loginForm" action="<%= ctx %>/studentLogin" method="post" autocomplete="on">

            <div class="field">
                <label for="rollNo">Roll number</label>
                <div class="input-wrap">
                    <input
                        id="rollNo"
                        type="text"
                        name="rollNo"
                        value="<%= escapeHtml(prefill) %>"
                        placeholder="Enter your roll number"
                        maxlength="50"
                        autocomplete="username"
                        autocapitalize="off"
                        autocorrect="off"
                        spellcheck="false"
                        required
                        <%= (error != null) ? "aria-invalid=\"true\"" : "" %>>
                </div>
            </div>

            <div class="field">
                <label for="password">Password</label>
                <div class="input-wrap">
                    <input
                        class="has-toggle"
                        id="password"
                        type="password"
                        name="password"
                        placeholder="Enter your password"
                        autocomplete="current-password"
                        required
                        <%= (error != null) ? "aria-invalid=\"true\"" : "" %>>

                    <button
                        class="toggle-password"
                        type="button"
                        id="togglePassword"
                        aria-controls="password"
                        aria-pressed="false"
                        aria-label="Show password">
                        Show
                    </button>
                </div>
                <div class="caps-warning" id="capsWarning" role="status">
                    Caps Lock is on.
                </div>
            </div>

            <div class="assist">
                <a href="<%= ctx %>/forgotPassword.jsp">Forgot password?</a>
            </div>

            <button class="submit" type="submit" id="submitBtn">
                <span class="spinner" aria-hidden="true"></span>
                <span id="submitLabel">Sign in</span>
            </button>

        </form>

        <p class="signup">
            New student?
            <a href="<%= ctx %>/studentRegister.jsp">Create an account</a>
        </p>

        <div class="divider"></div>

        <div class="privacy-note">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6l7-3z"/><path d="M9 12l2 2 4-4"/>
            </svg>
            <span>You can only view your own attendance records.
                  Never share your password with anyone.</span>
        </div>

        <div class="back-home">
            <a href="<%= ctx %>/index.jsp">&larr; Back to main dashboard</a>
        </div>

    </section>

</main>

<footer class="page-footer">
    &copy; <%= year %> AttendancePro. All rights reserved.
</footer>

<script>
    (function () {
        "use strict";

        var form        = document.getElementById("loginForm");
        var pwd         = document.getElementById("password");
        var toggle      = document.getElementById("togglePassword");
        var caps        = document.getElementById("capsWarning");
        var submitBtn   = document.getElementById("submitBtn");
        var submitLabel = document.getElementById("submitLabel");

        // Show / hide password
        toggle.addEventListener("click", function () {
            var hidden = pwd.type === "password";
            pwd.type = hidden ? "text" : "password";
            toggle.textContent = hidden ? "Hide" : "Show";
            toggle.setAttribute("aria-pressed", String(hidden));
            toggle.setAttribute("aria-label", hidden ? "Hide password" : "Show password");
            pwd.focus();
        });

        // Caps Lock warning
        function checkCaps(e) {
            if (typeof e.getModifierState !== "function") return;
            caps.classList.toggle("visible", e.getModifierState("CapsLock"));
        }
        pwd.addEventListener("keydown", checkCaps);
        pwd.addEventListener("keyup", checkCaps);
        pwd.addEventListener("blur", function () { caps.classList.remove("visible"); });

        // Double-submit rokne ke liye loading state
        form.addEventListener("submit", function () {
            if (submitBtn.disabled) return;
            submitBtn.disabled = true;
            submitBtn.classList.add("loading");
            submitLabel.textContent = "Signing in...";
        });

        // Back button se aane par (bfcache) button reset karo
        window.addEventListener("pageshow", function (e) {
            if (e.persisted) {
                submitBtn.disabled = false;
                submitBtn.classList.remove("loading");
                submitLabel.textContent = "Sign in";
            }
        });

        // Error ke baad first empty field par focus
        var rollNo = document.getElementById("rollNo");
        if (rollNo.value) { pwd.focus(); } else { rollNo.focus(); }
    })();
</script>

</body>
</html>
