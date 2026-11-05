<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%!
    // Escapes HTML special characters (replaces JSTL <c:out>, no external jar needed)
    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String ctx = request.getContextPath();
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
    String csrf = (String) session.getAttribute("csrfToken");
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Register a new student in AttendancePro">
    <title>Add Student | AttendancePro</title>

    <style>
        :root {
            --bg-1: #e8efff;
            --bg-2: #f5f7ff;
            --bg-3: #e6f4ff;
            --surface: #ffffff;
            --surface-alt: #f8fafc;
            --text: #1e293b;
            --text-muted: #64748b;
            --text-faint: #94a3b8;
            --heading: #172554;
            --border: #dbe3ef;
            --primary: #2563eb;
            --primary-2: #4f46e5;
            --primary-soft: #eff6ff;
            --danger: #dc2626;
            --danger-soft: #fef2f2;
            --success: #16a34a;
            --success-soft: #f0fdf4;
            --shadow: 0 20px 55px rgba(30, 58, 138, 0.10);
            --radius: 12px;
        }

        [data-theme="dark"] {
            --bg-1: #0b1120;
            --bg-2: #0f172a;
            --bg-3: #111c36;
            --surface: #162036;
            --surface-alt: #1c2842;
            --text: #e2e8f0;
            --text-muted: #94a3b8;
            --text-faint: #64748b;
            --heading: #f1f5f9;
            --border: #2b3a57;
            --primary-soft: #1b2a4a;
            --danger-soft: #3b1818;
            --success-soft: #11301d;
            --shadow: 0 20px 55px rgba(0, 0, 0, 0.45);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: "Segoe UI", system-ui, -apple-system, Arial, sans-serif;
            min-height: 100vh;
            background: linear-gradient(135deg, var(--bg-1), var(--bg-2), var(--bg-3));
            color: var(--text);
            padding: 30px 18px;
            transition: background 0.3s, color 0.3s;
        }

        /* ---------- Top bar ---------- */
        .topbar {
            max-width: 1100px;
            margin: 0 auto 26px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
        }

        .brand { display: flex; align-items: center; gap: 12px; }

        .brand-icon {
            width: 48px; height: 48px;
            background: linear-gradient(135deg, var(--primary), var(--primary-2));
            color: #fff;
            display: grid; place-items: center;
            border-radius: 14px;
            font-size: 23px; font-weight: bold;
        }

        .brand h2 { font-size: 21px; color: var(--heading); }
        .brand p { color: var(--text-muted); font-size: 12px; margin-top: 3px; }

        .top-actions { display: flex; gap: 10px; align-items: center; }

        .btn-ghost {
            text-decoration: none;
            color: var(--text);
            background: var(--surface);
            padding: 11px 17px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 600;
            border: 1px solid var(--border);
            cursor: pointer;
            font-family: inherit;
            transition: 0.2s;
        }
        .btn-ghost:hover { background: var(--primary-soft); color: var(--primary); }

        /* ---------- Breadcrumb ---------- */
        .breadcrumb {
            max-width: 1100px;
            margin: 0 auto 16px;
            font-size: 12px;
            color: var(--text-muted);
        }
        .breadcrumb a { color: var(--primary); text-decoration: none; }
        .breadcrumb a:hover { text-decoration: underline; }

        /* ---------- Layout ---------- */
        .main-container {
            max-width: 1100px;
            margin: auto;
            display: grid;
            grid-template-columns: 0.85fr 1.15fr;
            background: var(--surface);
            border-radius: 20px;
            overflow: hidden;
            box-shadow: var(--shadow);
        }

        .left-panel {
            background: linear-gradient(150deg, #172554, #1d4ed8, #4338ca);
            color: #fff;
            padding: 50px 38px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            position: relative;
            overflow: hidden;
        }
        .left-panel::after {
            content: "";
            position: absolute;
            width: 260px; height: 260px;
            right: -90px; bottom: -90px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.06);
        }

        .illustration {
            width: 78px; height: 78px;
            border-radius: 20px;
            background: rgba(255, 255, 255, 0.15);
            display: grid; place-items: center;
            font-size: 36px;
            margin-bottom: 25px;
        }

        .left-panel h1 { font-size: 29px; line-height: 1.3; margin-bottom: 15px; }
        .left-panel > p { color: #dbeafe; line-height: 1.8; font-size: 14px; }

        .feature-list { margin-top: 30px; display: grid; gap: 17px; position: relative; z-index: 1; }
        .feature { display: flex; gap: 12px; align-items: center; font-size: 13px; color: #eff6ff; }
        .check {
            width: 25px; height: 25px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.2);
            display: grid; place-items: center;
            flex-shrink: 0;
        }

        /* Progress tracker */
        .progress-card {
            margin-top: 34px;
            padding: 16px;
            border-radius: 14px;
            background: rgba(255, 255, 255, 0.12);
            position: relative; z-index: 1;
        }
        .progress-head { display: flex; justify-content: space-between; font-size: 12px; margin-bottom: 10px; color: #dbeafe; }
        .progress-track { height: 8px; border-radius: 99px; background: rgba(255, 255, 255, 0.2); overflow: hidden; }
        .progress-bar { height: 100%; width: 0; background: linear-gradient(90deg, #67e8f9, #a5f3fc); border-radius: 99px; transition: width 0.35s ease; }

        .right-panel { padding: 42px 45px; }
        .form-heading { margin-bottom: 24px; }
        .form-heading h2 { font-size: 25px; color: var(--heading); margin-bottom: 8px; }
        .form-heading p { color: var(--text-muted); font-size: 13px; }

        /* ---------- Alerts ---------- */
        .alert {
            display: flex; gap: 10px; align-items: flex-start;
            padding: 13px 15px;
            border-radius: 10px;
            font-size: 13px;
            line-height: 1.5;
            margin-bottom: 20px;
            border: 1px solid transparent;
        }
        .alert-error { background: var(--danger-soft); color: var(--danger); border-color: rgba(220, 38, 38, 0.25); }
        .alert-success { background: var(--success-soft); color: var(--success); border-color: rgba(22, 163, 74, 0.25); }

        /* ---------- Form ---------- */
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px 18px; }
        .form-group { min-width: 0; }
        .full-width { grid-column: 1 / -1; }

        label {
            display: flex; justify-content: space-between; align-items: center;
            margin-bottom: 8px;
            color: var(--text);
            font-size: 13px;
            font-weight: 650;
        }
        .required { color: #ef4444; }
        .counter { font-size: 11px; font-weight: 500; color: var(--text-faint); }

        .input-wrap { position: relative; }
        .input-icon {
            position: absolute; left: 14px; top: 50%;
            transform: translateY(-50%);
            font-size: 15px;
            pointer-events: none;
        }

        input, select {
            width: 100%;
            height: 48px;
            padding: 0 40px 0 42px;
            border: 1px solid var(--border);
            border-radius: 10px;
            background: var(--surface-alt);
            font-size: 14px;
            font-family: inherit;
            color: var(--text);
            outline: none;
            transition: 0.2s;
        }
        select { appearance: none; cursor: pointer; }
        .select-arrow {
            position: absolute; right: 14px; top: 50%;
            transform: translateY(-50%);
            font-size: 11px; color: var(--text-faint);
            pointer-events: none;
        }

        input:focus, select:focus {
            background: var(--surface);
            border-color: #3b82f6;
            box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.12);
        }
        input::placeholder { color: var(--text-faint); }

        .form-group.invalid input,
        .form-group.invalid select { border-color: var(--danger); background: var(--danger-soft); }
        .form-group.valid input,
        .form-group.valid select { border-color: var(--success); }

        .status-icon {
            position: absolute; right: 13px; top: 50%;
            transform: translateY(-50%);
            font-size: 14px; font-weight: bold;
            display: none;
        }
        .form-group.valid .status-icon { display: block; color: var(--success); }
        .form-group.invalid .status-icon { display: block; color: var(--danger); }

        .hint { color: var(--text-faint); font-size: 11px; margin-top: 6px; }
        .error-msg { color: var(--danger); font-size: 11px; margin-top: 6px; min-height: 0; display: none; }
        .form-group.invalid .error-msg { display: block; }
        .form-group.invalid .hint { display: none; }

        /* ---------- Buttons ---------- */
        .btn-row { display: grid; grid-template-columns: 1fr 2fr; gap: 12px; margin-top: 27px; }

        .reset-btn {
            height: 51px;
            border: 1px solid var(--border);
            border-radius: 11px;
            background: var(--surface);
            color: var(--text);
            font-size: 14px; font-weight: 600;
            cursor: pointer;
            font-family: inherit;
            transition: 0.2s;
        }
        .reset-btn:hover { background: var(--primary-soft); }

        .submit-btn {
            height: 51px;
            border: none;
            border-radius: 11px;
            background: linear-gradient(110deg, var(--primary), var(--primary-2));
            color: #fff;
            font-size: 15px; font-weight: 650;
            cursor: pointer;
            font-family: inherit;
            box-shadow: 0 7px 18px rgba(37, 99, 235, 0.20);
            transition: 0.2s;
            display: flex; align-items: center; justify-content: center; gap: 10px;
        }
        .submit-btn:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 11px 24px rgba(37, 99, 235, 0.28); }
        .submit-btn:disabled { opacity: 0.7; cursor: not-allowed; }

        .spinner {
            width: 17px; height: 17px;
            border: 2px solid rgba(255, 255, 255, 0.4);
            border-top-color: #fff;
            border-radius: 50%;
            animation: spin 0.7s linear infinite;
            display: none;
        }
        .submit-btn.loading .spinner { display: inline-block; }
        @keyframes spin { to { transform: rotate(360deg); } }

        .security-note {
            margin-top: 18px;
            padding: 12px;
            background: var(--primary-soft);
            border-radius: 9px;
            color: var(--text-muted);
            font-size: 11px;
            line-height: 1.6;
        }

        .footer { text-align: center; margin-top: 25px; color: var(--text-faint); font-size: 11px; }

        /* ---------- Toast ---------- */
        .toast {
            position: fixed; right: 20px; bottom: 20px;
            background: #0f172a; color: #fff;
            padding: 12px 18px;
            border-radius: 10px;
            font-size: 13px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
            opacity: 0; transform: translateY(12px);
            pointer-events: none;
            transition: 0.3s;
            z-index: 50;
        }
        .toast.show { opacity: 1; transform: translateY(0); }

        /* ---------- Responsive ---------- */
        @media (max-width: 800px) {
            .main-container { grid-template-columns: 1fr; }
            .left-panel { padding: 35px; }
            .right-panel { padding: 35px 28px; }
        }

        @media (max-width: 500px) {
            body { padding: 18px 12px; }
            .brand h2 { font-size: 17px; }
            .brand-icon { width: 42px; height: 42px; }
            .btn-ghost { padding: 9px 11px; font-size: 11px; }
            .form-grid { grid-template-columns: 1fr; }
            .full-width { grid-column: auto; }
            .right-panel { padding: 27px 20px; }
            .left-panel { padding: 28px 23px; }
            .btn-row { grid-template-columns: 1fr; }
        }

        @media (prefers-reduced-motion: reduce) {
            * { animation: none !important; transition: none !important; }
        }
    </style>
</head>

<body>

    <header class="topbar">
        <div class="brand">
            <div class="brand-icon">A</div>
            <div>
                <h2>AttendancePro</h2>
                <p>Smart Attendance Management System</p>
            </div>
        </div>

        <div class="top-actions">
            <button type="button" class="btn-ghost" id="themeToggle" aria-label="Toggle dark mode">🌙 Dark</button>
            <a href="<%= ctx %>/index.jsp" class="btn-ghost">← Back to Home</a>
        </div>
    </header>

    <nav class="breadcrumb" aria-label="Breadcrumb">
        <a href="<%= ctx %>/index.jsp">Home</a> &rsaquo;
        <a href="<%= ctx %>/viewStudents">Students</a> &rsaquo;
        <span>Add Student</span>
    </nav>

    <main class="main-container">

        <section class="left-panel">
            <div class="illustration">🎓</div>
            <h1>Add a New Student</h1>
            <p>
                Register students into AttendancePro and manage
                their academic information through one centralized
                attendance management platform.
            </p>

            <div class="feature-list">
                <div class="feature"><span class="check">✓</span><span>Secure student record management</span></div>
                <div class="feature"><span class="check">✓</span><span>Academic information tracking</span></div>
                <div class="feature"><span class="check">✓</span><span>Email and mobile details</span></div>
                <div class="feature"><span class="check">✓</span><span>Integrated attendance monitoring</span></div>
            </div>

            <div class="progress-card" aria-live="polite">
                <div class="progress-head">
                    <span>Form completion</span>
                    <span id="progressText">0%</span>
                </div>
                <div class="progress-track">
                    <div class="progress-bar" id="progressBar"></div>
                </div>
            </div>
        </section>

        <section class="right-panel">

            <div class="form-heading">
                <h2>Student Registration</h2>
                <p>Enter the student's details to create a new record.</p>
            </div>

            <%-- Server-side messages: set these as request attributes in your servlet --%>
            <% if (error != null && !error.isEmpty()) { %>
                <div class="alert alert-error" role="alert">
                    <span>⚠</span><span><%= esc(error) %></span>
                </div>
            <% } %>
            <% if (success != null && !success.isEmpty()) { %>
                <div class="alert alert-success" role="status">
                    <span>✔</span><span><%= esc(success) %></span>
                </div>
            <% } %>

            <form action="<%= ctx %>/addStudent" method="post" id="studentForm" novalidate autocomplete="off">

                <%-- CSRF token: generate and store in session as "csrfToken" (ignored if unused) --%>
                <input type="hidden" name="csrfToken" value="<%= esc(csrf) %>">

                <div class="form-grid">

                    <!-- Roll Number -->
                    <div class="form-group" data-field="rollNo">
                        <label for="rollNo">
                            <span>Roll Number <span class="required">*</span></span>
                            <span class="counter" id="rollNoCount">0/13</span>
                        </label>
                        <div class="input-wrap">
                            <span class="input-icon">🪪</span>
                            <input type="text" id="rollNo" name="rollNo"
                                   inputmode="numeric" maxlength="13"
                                   placeholder="13-digit roll number"
                                   value="<%= esc(request.getParameter("rollNo")) %>"
                                   aria-describedby="rollNoMsg" required>
                            <span class="status-icon" aria-hidden="true"></span>
                        </div>
                        <p class="hint" id="rollNoHint">Exactly 13 numeric digits</p>
                        <p class="error-msg" id="rollNoMsg"></p>
                    </div>

                    <!-- Name -->
                    <div class="form-group" data-field="name">
                        <label for="name">
                            <span>Student Name <span class="required">*</span></span>
                            <span class="counter" id="nameCount">0/100</span>
                        </label>
                        <div class="input-wrap">
                            <span class="input-icon">👤</span>
                            <input type="text" id="name" name="name"
                                   maxlength="100" placeholder="Enter full name"
                                   value="<%= esc(request.getParameter("name")) %>"
                                   autocomplete="name" aria-describedby="nameMsg" required>
                            <span class="status-icon" aria-hidden="true"></span>
                        </div>
                        <p class="hint">Letters, spaces, dots and apostrophes only</p>
                        <p class="error-msg" id="nameMsg"></p>
                    </div>

                    <!-- Course -->
                    <div class="form-group" data-field="course">
                        <label for="course"><span>Course <span class="required">*</span></span></label>
                        <div class="input-wrap">
                            <span class="input-icon">📚</span>
                            <input type="text" id="course" name="course"
                                   maxlength="50" list="courseList"
                                   placeholder="e.g. B.Tech CSE"
                                   value="<%= esc(request.getParameter("course")) %>"
                                   aria-describedby="courseMsg" required>
                            <span class="status-icon" aria-hidden="true"></span>
                        </div>
                        <datalist id="courseList">
                            <option value="B.Tech CSE">
                            <option value="B.Tech IT">
                            <option value="B.Tech ECE">
                            <option value="B.Tech ME">
                            <option value="B.Tech CE">
                            <option value="BCA">
                            <option value="MCA">
                            <option value="M.Tech">
                            <option value="B.Sc">
                            <option value="BBA">
                            <option value="MBA">
                        </datalist>
                        <p class="hint">Pick a suggestion or type your own</p>
                        <p class="error-msg" id="courseMsg"></p>
                    </div>

                    <!-- Semester -->
                    <div class="form-group" data-field="semester">
                        <label for="semester"><span>Semester <span class="required">*</span></span></label>
                        <div class="input-wrap">
                            <span class="input-icon">📅</span>
                            <select id="semester" name="semester" aria-describedby="semesterMsg" required>
                                <option value="">Select semester</option>
                                <option value="1">Semester 1</option>
                                <option value="2">Semester 2</option>
                                <option value="3">Semester 3</option>
                                <option value="4">Semester 4</option>
                                <option value="5">Semester 5</option>
                                <option value="6">Semester 6</option>
                                <option value="7">Semester 7</option>
                                <option value="8">Semester 8</option>
                                <option value="9">Semester 9</option>
                                <option value="10">Semester 10</option>
                            </select>
                            <span class="select-arrow">▼</span>
                        </div>
                        <p class="hint">Current academic semester</p>
                        <p class="error-msg" id="semesterMsg"></p>
                    </div>

                    <!-- Email -->
                    <div class="form-group full-width" data-field="email">
                        <label for="email"><span>Student Email <span class="required">*</span></span></label>
                        <div class="input-wrap">
                            <span class="input-icon">✉</span>
                            <input type="email" id="email" name="email"
                                   maxlength="254" placeholder="student@example.com"
                                   value="<%= esc(request.getParameter("email")) %>"
                                   autocomplete="email" aria-describedby="emailMsg" required>
                            <span class="status-icon" aria-hidden="true"></span>
                        </div>
                        <p class="hint">Used for attendance alerts and notifications</p>
                        <p class="error-msg" id="emailMsg"></p>
                    </div>

                    <!-- Phone -->
                    <div class="form-group full-width" data-field="phone">
                        <label for="phone">
                            <span>Mobile Number <span class="required">*</span></span>
                            <span class="counter" id="phoneCount">0/10</span>
                        </label>
                        <div class="input-wrap">
                            <span class="input-icon">📱</span>
                            <input type="tel" id="phone" name="phone"
                                   inputmode="numeric" maxlength="10"
                                   placeholder="Enter 10-digit mobile number"
                                   value="<%= esc(request.getParameter("phone")) %>"
                                   autocomplete="tel" aria-describedby="phoneMsg" required>
                            <span class="status-icon" aria-hidden="true"></span>
                        </div>
                        <p class="hint">10 digits, starting with 6, 7, 8 or 9</p>
                        <p class="error-msg" id="phoneMsg"></p>
                    </div>

                </div>

                <div class="btn-row">
                    <button type="button" class="reset-btn" id="resetBtn">Reset</button>
                    <button type="submit" class="submit-btn" id="submitBtn">
                        <span class="spinner" aria-hidden="true"></span>
                        <span id="submitLabel">+ Add Student</span>
                    </button>
                </div>

                <div class="security-note">
                    🔒 Please verify all student information before
                    submitting the registration.
                </div>

            </form>
        </section>

    </main>

    <footer class="footer">
        © 2026 AttendancePro | Smart Attendance Management System
    </footer>

    <div class="toast" id="toast" role="status" aria-live="polite"></div>

    <script>
    (function () {
        'use strict';

        var form = document.getElementById('studentForm');
        var submitBtn = document.getElementById('submitBtn');
        var submitLabel = document.getElementById('submitLabel');
        var resetBtn = document.getElementById('resetBtn');
        var toastEl = document.getElementById('toast');
        var progressBar = document.getElementById('progressBar');
        var progressText = document.getElementById('progressText');
        var themeToggle = document.getElementById('themeToggle');

        /* ---------- Validation rules ---------- */
        var nameRegex = /^[A-Za-z][A-Za-z .'\-]{1,99}$/;
        var emailRegex = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/;

        var rules = {
            rollNo: function (v) {
                if (!v) return 'Roll number is required.';
                if (!/^[0-9]{13}$/.test(v)) return 'Roll number must be exactly 13 digits.';
                return '';
            },
            name: function (v) {
                v = v.trim();
                if (!v) return 'Student name is required.';
                if (v.length < 2) return 'Name must be at least 2 characters.';
                if (!nameRegex.test(v)) return 'Name can contain only letters, spaces, . \' and -';
                return '';
            },
            course: function (v) {
                v = v.trim();
                if (!v) return 'Course is required.';
                if (v.length < 2) return 'Enter a valid course name.';
                return '';
            },
            semester: function (v) {
                if (!v) return 'Please select a semester.';
                var n = parseInt(v, 10);
                if (isNaN(n) || n < 1 || n > 12) return 'Semester must be between 1 and 12.';
                return '';
            },
            email: function (v) {
                v = v.trim();
                if (!v) return 'Email address is required.';
                if (!emailRegex.test(v)) return 'Enter a valid email address.';
                return '';
            },
            phone: function (v) {
                if (!v) return 'Mobile number is required.';
                if (!/^[0-9]{10}$/.test(v)) return 'Mobile number must be exactly 10 digits.';
                if (!/^[6-9]/.test(v)) return 'Mobile number must start with 6, 7, 8 or 9.';
                return '';
            }
        };

        var fields = Object.keys(rules);
        var touched = {};

        function groupOf(id) { return form.querySelector('[data-field="' + id + '"]'); }

        function setState(id, message) {
            var group = groupOf(id);
            var msg = document.getElementById(id + 'Msg');
            var input = document.getElementById(id);
            var icon = group.querySelector('.status-icon');

            group.classList.remove('valid', 'invalid');
            if (message) {
                group.classList.add('invalid');
                msg.textContent = message;
                input.setAttribute('aria-invalid', 'true');
                if (icon) icon.textContent = '✕';
            } else {
                group.classList.add('valid');
                msg.textContent = '';
                input.removeAttribute('aria-invalid');
                if (icon) icon.textContent = '✓';
            }
        }

        function validateField(id, showErrors) {
            var value = document.getElementById(id).value;
            var message = rules[id](value);
            if (showErrors || touched[id]) {
                setState(id, message);
            }
            return message === '';
        }

        function validateAll() {
            var firstInvalid = null;
            fields.forEach(function (id) {
                touched[id] = true;
                if (!validateField(id, true) && !firstInvalid) firstInvalid = id;
            });
            return firstInvalid;
        }

        /* ---------- Progress tracker ---------- */
        function updateProgress() {
            var done = fields.filter(function (id) {
                return rules[id](document.getElementById(id).value) === '';
            }).length;
            var pct = Math.round((done / fields.length) * 100);
            progressBar.style.width = pct + '%';
            progressText.textContent = pct + '%';
        }

        /* ---------- Counters ---------- */
        function updateCounter(id, max) {
            var el = document.getElementById(id + 'Count');
            if (el) el.textContent = document.getElementById(id).value.length + '/' + max;
        }

        /* ---------- Input sanitising ---------- */
        function digitsOnly(id, max) {
            var el = document.getElementById(id);
            el.addEventListener('input', function () {
                el.value = el.value.replace(/[^0-9]/g, '').slice(0, max);
            });
            el.addEventListener('paste', function (e) {
                e.preventDefault();
                var text = (e.clipboardData || window.clipboardData).getData('text');
                el.value = text.replace(/[^0-9]/g, '').slice(0, max);
                el.dispatchEvent(new Event('input', { bubbles: true }));
            });
        }
        digitsOnly('rollNo', 13);
        digitsOnly('phone', 10);

        /* ---------- Wire up events ---------- */
        fields.forEach(function (id) {
            var el = document.getElementById(id);
            var evt = (el.tagName === 'SELECT') ? 'change' : 'input';

            el.addEventListener(evt, function () {
                validateField(id, false);
                updateProgress();
            });
            el.addEventListener('blur', function () {
                touched[id] = true;
                validateField(id, true);
            });
        });

        document.getElementById('rollNo').addEventListener('input', function () { updateCounter('rollNo', 13); });
        document.getElementById('phone').addEventListener('input', function () { updateCounter('phone', 10); });
        document.getElementById('name').addEventListener('input', function () { updateCounter('name', 100); });

        /* ---------- Submit ---------- */
        form.addEventListener('submit', function (e) {
            var firstInvalid = validateAll();
            if (firstInvalid) {
                e.preventDefault();
                document.getElementById(firstInvalid).focus();
                showToast('Please fix the highlighted fields.');
                return;
            }

            // Normalize before sending
            var nameEl = document.getElementById('name');
            nameEl.value = nameEl.value.trim().replace(/\s+/g, ' ');
            var emailEl = document.getElementById('email');
            emailEl.value = emailEl.value.trim().toLowerCase();
            var courseEl = document.getElementById('course');
            courseEl.value = courseEl.value.trim();

            // Prevent double submission
            if (submitBtn.disabled) { e.preventDefault(); return; }
            submitBtn.disabled = true;
            submitBtn.classList.add('loading');
            submitLabel.textContent = 'Saving...';
        });

        /* ---------- Reset ---------- */
        resetBtn.addEventListener('click', function () {
            if (!confirm('Clear all entered details?')) return;
            form.reset();
            touched = {};
            fields.forEach(function (id) {
                var g = groupOf(id);
                g.classList.remove('valid', 'invalid');
                document.getElementById(id + 'Msg').textContent = '';
                document.getElementById(id).removeAttribute('aria-invalid');
            });
            updateCounter('rollNo', 13);
            updateCounter('phone', 10);
            updateCounter('name', 100);
            updateProgress();
            showToast('Form cleared.');
        });

        /* ---------- Toast ---------- */
        var toastTimer;
        function showToast(text) {
            toastEl.textContent = text;
            toastEl.classList.add('show');
            clearTimeout(toastTimer);
            toastTimer = setTimeout(function () { toastEl.classList.remove('show'); }, 2800);
        }

        /* ---------- Theme ---------- */
        function applyTheme(theme) {
            document.documentElement.setAttribute('data-theme', theme);
            themeToggle.textContent = theme === 'dark' ? '☀ Light' : '🌙 Dark';
        }
        var savedTheme = 'light';
        try { savedTheme = localStorage.getItem('ap-theme') || 'light'; } catch (err) { /* storage blocked */ }
        applyTheme(savedTheme);

        themeToggle.addEventListener('click', function () {
            var next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
            applyTheme(next);
            try { localStorage.setItem('ap-theme', next); } catch (err) { /* ignore */ }
        });

        /* ---------- Restore state after a server-side error (values re-filled from request) ---------- */
        fields.forEach(function (id) {
            var el = document.getElementById(id);
            if (el.value) { touched[id] = true; validateField(id, true); }
        });
        updateCounter('rollNo', 13);
        updateCounter('phone', 10);
        updateCounter('name', 100);
        updateProgress();

        // Re-enable the button if user navigates back (bfcache)
        window.addEventListener('pageshow', function (ev) {
            if (ev.persisted) {
                submitBtn.disabled = false;
                submitBtn.classList.remove('loading');
                submitLabel.textContent = '+ Add Student';
            }
        });
    })();
    </script>

</body>
</html>
