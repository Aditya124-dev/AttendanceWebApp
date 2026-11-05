
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>

<%
    if (session.getAttribute("teacherId") == null
            || !"TEACHER".equals(session.getAttribute("userRole"))) {
        response.sendRedirect(request.getContextPath() + "/teacherLogin.jsp");
        return;
    }

    String contextPath = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>Mark Attendance | AttendancePro Teacher Portal</title>

<script>
try {
    var theme = localStorage.getItem('sp-theme');
    if (theme) {
        document.documentElement.setAttribute('data-theme', theme);
    } else if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        document.documentElement.setAttribute('data-theme', 'dark');
    }
} catch (e) {}
</script>

<style>
:root {
    --bg:#eef1f6;
    --surface:#fff;
    --surface-2:#f6f8fb;
    --line:#dde3ec;
    --ink:#101c36;
    --muted:#5d6b84;
    --brand:#1b3a8a;
    --brand-2:#2f5fe0;
    --on-brand:#fff;
    --good:#0d7a5f;
    --good-bg:#dff5ec;
    --bad:#b42318;
    --bad-bg:#fde6e4;
    --shadow:0 1px 2px rgba(16,28,54,.06),
             0 8px 24px -12px rgba(16,28,54,.18);
}

[data-theme="dark"] {
    --bg:#0b1222;
    --surface:#121b30;
    --surface-2:#18233d;
    --line:#26334f;
    --ink:#e8edf8;
    --muted:#92a0bd;
    --brand:#7ea1ff;
    --brand-2:#9db6ff;
    --on-brand:#0b1222;
    --good:#4fd1a5;
    --good-bg:#10362c;
    --bad:#ff8a80;
    --bad-bg:#3d1a18;
    --shadow:0 1px 2px rgba(0,0,0,.4),
             0 8px 24px -12px rgba(0,0,0,.6);
}

* { box-sizing:border-box; }

body {
    margin:0;
    min-height:100vh;
    background:var(--bg);
    color:var(--ink);
    font:15px/1.5 "Segoe UI",system-ui,-apple-system,Roboto,Arial,sans-serif;
    -webkit-font-smoothing:antialiased;
}

:focus-visible {
    outline:3px solid var(--brand-2);
    outline-offset:2px;
    border-radius:8px;
}

button,input { font:inherit; }

.topbar {
    background:var(--surface);
    border-bottom:1px solid var(--line);
}

.topbar-in {
    max-width:1120px;
    margin:auto;
    padding:12px 20px;
    display:flex;
    align-items:center;
    gap:14px;
}

.brand {
    display:flex;
    align-items:center;
    gap:10px;
    font-weight:700;
    margin-right:auto;
}

.brand-mark {
    width:36px;
    height:36px;
    border-radius:10px;
    background:var(--brand);
    color:var(--on-brand);
    display:grid;
    place-items:center;
}

.brand small {
    display:block;
    font-weight:500;
    color:var(--muted);
    font-size:12px;
    line-height:1.3;
}

.btn {
    border:1px solid var(--line);
    background:var(--surface);
    color:var(--ink);
    border-radius:10px;
    padding:9px 14px;
    cursor:pointer;
    font-weight:600;
    text-decoration:none;
    display:inline-flex;
    align-items:center;
    gap:8px;
}

.btn:hover {
    background:var(--surface-2);
    border-color:var(--muted);
}

main {
    max-width:560px;
    margin:34px auto;
    padding:0 16px;
}

.card {
    background:var(--surface);
    border:1px solid var(--line);
    border-radius:16px;
    box-shadow:var(--shadow);
    padding:26px;
}

.heading {
    display:flex;
    align-items:center;
    gap:12px;
    margin-bottom:22px;
}

.heading-icon {
    width:46px;
    height:46px;
    border-radius:12px;
    display:grid;
    place-items:center;
    background:var(--surface-2);
    color:var(--brand-2);
    font-size:23px;
}

h1 {
    margin:0 0 4px;
    font-size:24px;
}

.sub {
    color:var(--muted);
    margin:0;
    font-size:14px;
}

.field { margin-bottom:18px; }

label,.lbl {
    display:block;
    font-weight:600;
    font-size:14px;
    margin-bottom:6px;
}

.help {
    font-size:12px;
    color:var(--muted);
    margin-top:6px;
}

input[type=text],input[type=date] {
    width:100%;
    padding:12px 14px;
    border:1px solid var(--line);
    border-radius:10px;
    background:var(--surface);
    color:var(--ink);
}

input:hover { border-color:var(--muted); }

.row {
    display:flex;
    gap:8px;
    margin-top:8px;
    flex-wrap:wrap;
}

.chip {
    border:1px solid var(--line);
    background:var(--surface-2);
    color:var(--ink);
    border-radius:999px;
    padding:5px 14px;
    font-size:13px;
    cursor:pointer;
}

.chip:hover { border-color:var(--brand-2); }

.seg {
    display:grid;
    grid-template-columns:1fr 1fr;
    gap:10px;
}

.seg input {
    position:absolute;
    opacity:0;
    pointer-events:none;
}

.seg label {
    margin:0;
    text-align:center;
    padding:12px;
    border:1.5px solid var(--line);
    border-radius:10px;
    cursor:pointer;
    font-weight:700;
    color:var(--muted);
}

#sP:checked + label {
    background:var(--good-bg);
    border-color:var(--good);
    color:var(--good);
}

#sA:checked + label {
    background:var(--bad-bg);
    border-color:var(--bad);
    color:var(--bad);
}

.seg input:focus-visible + label {
    outline:3px solid var(--brand-2);
    outline-offset:2px;
}

.submit {
    width:100%;
    padding:13px;
    border:0;
    border-radius:10px;
    background:var(--brand);
    color:var(--on-brand);
    font-weight:700;
    cursor:pointer;
}

.submit:hover { background:var(--brand-2); }

.submit:disabled {
    opacity:.6;
    cursor:not-allowed;
}

.err {
    color:var(--bad);
    font-size:12px;
    font-weight:600;
    margin-top:6px;
}

.back {
    text-align:center;
    margin-top:18px;
}

.back a {
    color:var(--brand-2);
    font-weight:600;
    text-decoration:none;
}

@media(max-width:480px) {
    .card { padding:20px; }
    h1 { font-size:21px; }
}

@media(prefers-reduced-motion:reduce) {
    * { transition:none!important; }
}
</style>
</head>

<body>

<header class="topbar">
    <div class="topbar-in">
        <div class="brand">
            <span class="brand-mark" aria-hidden="true">✓</span>
            <span>
                AttendancePro
                <small>Teacher Portal · Attendance Management</small>
            </span>
        </div>

        <button type="button" class="btn" id="themeBtn"
                aria-label="Toggle dark mode">◐</button>
    </div>
</header>

<main>
    <div class="card">

        <div class="heading">
            <div class="heading-icon">✓</div>
            <div>
                <h1>Mark Attendance</h1>
                <p class="sub">Record daily student attendance.</p>
            </div>
        </div>

        <form action="<%= contextPath %>/markAttendance"
              method="post" id="attendanceForm" novalidate>

            <div class="field">
                <label for="rollNo">Student Roll Number</label>
                <input type="text"
                       id="rollNo"
                       name="rollNo"
                       placeholder="Enter student roll number"
                       autocomplete="off"
                       maxlength="30"
                       required
                       autofocus>
                <div class="err" id="rollErr" role="alert"></div>
            </div>

            <div class="field">
                <label for="date">Attendance Date</label>
                <input type="date" id="date" name="date" required>

                <div class="row">
                    <button type="button" class="chip" data-d="0">Today</button>
                    <button type="button" class="chip" data-d="-1">Yesterday</button>
                </div>

                <div class="help">
                    Future-date attendance is not allowed.
                </div>
                <div class="err" id="dateErr" role="alert"></div>
            </div>

            <div class="field">
                <span class="lbl" id="statusLabel">Attendance Status</span>

                <div class="seg" role="radiogroup"
                     aria-labelledby="statusLabel">

                    <input type="radio" id="sP"
                           name="status" value="Present" checked>
                    <label for="sP">Present</label>

                    <input type="radio" id="sA"
                           name="status" value="Absent">
                    <label for="sA">Absent</label>
                </div>
            </div>

            <button type="submit" class="submit" id="saveBtn">
                Save Attendance
            </button>
        </form>

        <p class="back">
            <a href="<%= contextPath %>/teacherDashboard.jsp">
                ← Back to Teacher Dashboard
            </a>
        </p>

    </div>
</main>

<script>
(function () {
    'use strict';

    var themeBtn = document.getElementById('themeBtn');

    themeBtn.addEventListener('click', function () {
        var root = document.documentElement;
        var next = root.getAttribute('data-theme') === 'dark'
            ? 'light' : 'dark';

        root.setAttribute('data-theme', next);

        try {
            localStorage.setItem('sp-theme', next);
        } catch (e) {}
    });

    var date = document.getElementById('date');
    var roll = document.getElementById('rollNo');

    function iso(offset) {
        var d = new Date();
        d.setDate(d.getDate() + offset);

        return d.getFullYear() + '-' +
            String(d.getMonth() + 1).padStart(2, '0') + '-' +
            String(d.getDate()).padStart(2, '0');
    }

    date.max = iso(0);
    date.value = iso(0);

    document.querySelectorAll('.chip').forEach(function (chip) {
        chip.addEventListener('click', function () {
            date.value = iso(Number(chip.dataset.d));
            document.getElementById('dateErr').textContent = '';
        });
    });

    roll.addEventListener('input', function () {
        roll.value = roll.value.toUpperCase();
        document.getElementById('rollErr').textContent = '';
    });

    document.getElementById('attendanceForm')
        .addEventListener('submit', function (event) {

        var valid = true;
        roll.value = roll.value.trim();

        if (!roll.value) {
            document.getElementById('rollErr').textContent =
                'Enter the student roll number.';
            valid = false;
        }

        if (!date.value) {
            document.getElementById('dateErr').textContent =
                'Choose an attendance date.';
            valid = false;
        } else if (date.value > date.max) {
            document.getElementById('dateErr').textContent =
                'Future-date attendance is not allowed.';
            valid = false;
        }

        if (!valid) {
            event.preventDefault();
            return;
        }

        var button = document.getElementById('saveBtn');
        button.disabled = true;
        button.textContent = 'Saving...';
    });
})();
</script>

</body>
</html>
