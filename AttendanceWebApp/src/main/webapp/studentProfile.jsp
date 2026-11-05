<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Locale" %>
<%@ page import="com.attendance.DBConnection" %>

<%!
    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;")
                    .replace(">", "&gt;").replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    response.setHeader("X-Content-Type-Options", "nosniff");

    if (session == null || session.getAttribute("studentId") == null) {
        response.sendRedirect(request.getContextPath() + "/studentLogin.jsp");
        return;
    }

    int studentId = (Integer) session.getAttribute("studentId");

    String studentName = "", rollNo = "", course = "";
    int semester = 0, totalDays = 0, presentDays = 0, absentDays = 0;
    double percentage = 0.0;
    boolean hasPhoto = false;
    List<String[]> history = new ArrayList<>();
    String errorMessage = null, photoMessage = null, photoMessageType = null;

    final int REQUIRED = 75; // minimum attendance % (change if your college differs)

    String photoStatus = request.getParameter("photo");
    if ("success".equals(photoStatus)) {
        photoMessage = "Profile photo uploaded successfully.";
        photoMessageType = "success";
    } else if ("empty".equals(photoStatus)) {
        photoMessage = "Please select a photo before uploading.";
        photoMessageType = "error";
    }

    try (Connection con = DBConnection.getConnection()) {

        String profileSql =
            "SELECT s.roll_no, s.name, s.course, s.semester, "
            + "MAX(CASE WHEN s.profile_photo IS NOT NULL "
            + "AND OCTET_LENGTH(s.profile_photo) > 0 THEN 1 ELSE 0 END) AS has_photo, "
            + "COUNT(a.attendance_id) AS total_days, "
            + "COALESCE(SUM(CASE WHEN a.status='Present' THEN 1 ELSE 0 END), 0) AS present_days, "
            + "COALESCE(SUM(CASE WHEN a.status='Absent' THEN 1 ELSE 0 END), 0) AS absent_days "
            + "FROM students s LEFT JOIN attendance a ON s.student_id = a.student_id "
            + "WHERE s.student_id = ? "
            + "GROUP BY s.student_id, s.roll_no, s.name, s.course, s.semester";

        try (PreparedStatement ps = con.prepareStatement(profileSql)) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    rollNo = rs.getString("roll_no");
                    studentName = rs.getString("name");
                    course = rs.getString("course");
                    semester = rs.getInt("semester");
                    hasPhoto = rs.getBoolean("has_photo");
                    totalDays = rs.getInt("total_days");
                    presentDays = rs.getInt("present_days");
                    absentDays = rs.getInt("absent_days");
                } else {
                    session.invalidate();
                    response.sendRedirect(request.getContextPath() + "/studentLogin.jsp");
                    return;
                }
            }
        }

        if (totalDays > 0) percentage = presentDays * 100.0 / totalDays;

        String historySql =
            "SELECT attendance_date, status FROM attendance WHERE student_id = ? "
            + "ORDER BY attendance_date DESC, attendance_id DESC";

        try (PreparedStatement ps = con.prepareStatement(historySql)) {
            ps.setInt(1, studentId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    history.add(new String[] {
                        String.valueOf(rs.getDate("attendance_date")),
                        rs.getString("status")
                    });
                }
            }
        }
    } catch (Exception e) {
        application.log("Unable to load student profile", e);
        errorMessage = "Unable to load your profile. Please refresh the page or try again later.";
    }

    // Derived insight: how many classes to attend / can miss to stay at REQUIRED %
    String level = "none", levelText = "No data yet", insight = "Your attendance will appear here once classes are recorded.";
    if (totalDays > 0) {
        if (percentage >= REQUIRED + 10) { level = "good"; levelText = "Excellent"; }
        else if (percentage >= REQUIRED)  { level = "ok";   levelText = "Safe"; }
        else if (percentage >= REQUIRED - 10) { level = "warn"; levelText = "Low"; }
        else { level = "bad"; levelText = "Critical"; }

        if (percentage >= REQUIRED) {
            int canMiss = (100 * presentDays - REQUIRED * totalDays) / REQUIRED;
            insight = canMiss > 0
                ? "You can miss up to " + canMiss + " more class" + (canMiss == 1 ? "" : "es") + " and still stay at " + REQUIRED + "% or above."
                : "You are right at the " + REQUIRED + "% limit. Missing the next class will put you below it.";
        } else {
            int need = (int) Math.ceil((REQUIRED * totalDays - 100.0 * presentDays) / (100 - REQUIRED));
            insight = "Attend the next " + need + " class" + (need == 1 ? "" : "es") + " in a row to reach " + REQUIRED + "%.";
        }
    }
    String pctText = String.format(Locale.US, "%.1f", percentage);
    double circ = 2 * Math.PI * 52;
    double dashOffset = circ * (1 - Math.min(percentage, 100) / 100.0);
    String initial = (studentName == null || studentName.isEmpty()) ? "S" : studentName.substring(0, 1).toUpperCase();
%>
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>My Dashboard | Student Portal</title>
<script>
    try { var t = localStorage.getItem('sp-theme'); if (t) document.documentElement.setAttribute('data-theme', t);
          else if (window.matchMedia('(prefers-color-scheme: dark)').matches) document.documentElement.setAttribute('data-theme','dark'); } catch(e){}
</script>
<style>
:root{
    --bg:#eef1f6; --surface:#fff; --surface-2:#f6f8fb; --line:#dde3ec;
    --ink:#101c36; --muted:#5d6b84; --brand:#1b3a8a; --brand-2:#2f5fe0; --on-brand:#fff;
    --good:#0d7a5f; --good-bg:#dff5ec; --ok:#1b6fd1; --ok-bg:#e2eeff;
    --warn:#a65a00; --warn-bg:#fff0d6; --bad:#b42318; --bad-bg:#fde6e4;
    --shadow:0 1px 2px rgba(16,28,54,.06),0 8px 24px -12px rgba(16,28,54,.18);
}
[data-theme="dark"]{
    --bg:#0b1222; --surface:#121b30; --surface-2:#18233d; --line:#26334f;
    --ink:#e8edf8; --muted:#92a0bd; --brand:#7ea1ff; --brand-2:#9db6ff; --on-brand:#0b1222;
    --good:#4fd1a5; --good-bg:#10362c; --ok:#7eb4ff; --ok-bg:#142a4d;
    --warn:#ffb454; --warn-bg:#3a2b10; --bad:#ff8a80; --bad-bg:#3d1a18;
    --shadow:0 1px 2px rgba(0,0,0,.4),0 8px 24px -12px rgba(0,0,0,.6);
}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 "Segoe UI",system-ui,-apple-system,Roboto,Arial,sans-serif;-webkit-font-smoothing:antialiased}
a,button,input,select{font:inherit}
:focus-visible{outline:3px solid var(--brand-2);outline-offset:2px;border-radius:6px}
.skip{position:absolute;left:-999px;top:8px;background:var(--brand);color:var(--on-brand);padding:8px 14px;border-radius:8px;z-index:50}
.skip:focus{left:8px}

/* top bar */
.topbar{position:sticky;top:0;z-index:20;background:var(--surface);border-bottom:1px solid var(--line)}
.topbar-in{max-width:1120px;margin:auto;padding:12px 20px;display:flex;align-items:center;gap:14px}
.brand{display:flex;align-items:center;gap:10px;font-weight:700;letter-spacing:.2px;margin-right:auto}
.brand-mark{width:34px;height:34px;border-radius:9px;background:var(--brand);color:var(--on-brand);display:grid;place-items:center}
.brand small{display:block;font-weight:500;color:var(--muted);font-size:12px;line-height:1}
.icon-btn,.btn{border:1px solid var(--line);background:var(--surface);color:var(--ink);border-radius:10px;padding:9px 14px;cursor:pointer;font-weight:600;display:inline-flex;align-items:center;gap:8px;transition:background .15s,border-color .15s}
.icon-btn:hover,.btn:hover{background:var(--surface-2);border-color:var(--muted)}
.btn-primary{background:var(--brand);border-color:var(--brand);color:var(--on-brand)}
.btn-primary:hover{background:var(--brand-2);border-color:var(--brand-2)}
.logout{margin:0}
.btn svg,.icon-btn svg{width:18px;height:18px;flex:none}

main{max-width:1120px;margin:26px auto 40px;padding:0 20px;display:grid;gap:20px}
.card{background:var(--surface);border:1px solid var(--line);border-radius:16px;box-shadow:var(--shadow);padding:22px}
.card h2{margin:0 0 4px;font-size:17px}
.sub{color:var(--muted);font-size:13px;margin:0 0 16px}

.toast{padding:12px 16px;border-radius:12px;font-weight:600;font-size:14px;display:flex;justify-content:space-between;gap:12px;align-items:center}
.toast.success{background:var(--good-bg);color:var(--good)}
.toast.error{background:var(--bad-bg);color:var(--bad)}
.toast button{background:none;border:0;color:inherit;cursor:pointer;font-size:20px;line-height:1}

/* hero */
.hero{display:grid;grid-template-columns:1.4fr 1fr;gap:20px}
.identity{display:flex;gap:22px;align-items:flex-start;flex-wrap:wrap}
.avatar-wrap{position:relative;flex:none}
.avatar{width:112px;height:112px;border-radius:50%;object-fit:cover;border:3px solid var(--line);background:var(--brand);color:var(--on-brand);display:grid;place-items:center;font-size:42px;font-weight:700}
.id-main{flex:1;min-width:220px}
.id-main h1{margin:0;font-size:26px;line-height:1.2;overflow-wrap:anywhere}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin:12px 0 16px}
.chip{background:var(--surface-2);border:1px solid var(--line);border-radius:999px;padding:4px 12px;font-size:13px;color:var(--muted)}
.chip b{color:var(--ink);font-weight:600}
.upload{border:1.5px dashed var(--line);border-radius:12px;padding:12px 14px;background:var(--surface-2);display:flex;gap:12px;align-items:center;flex-wrap:wrap;transition:border-color .15s,background .15s}
.upload.drag{border-color:var(--brand-2);background:var(--ok-bg)}
.upload input[type=file]{flex:1;min-width:180px;font-size:13px;color:var(--muted)}
.upload .hint{width:100%;font-size:12px;color:var(--muted);margin:0}
.upload .hint.err{color:var(--bad);font-weight:600}

/* ring */
.score{display:flex;flex-direction:column;align-items:center;text-align:center;gap:12px}
.ring{position:relative;width:170px;height:170px}
.ring svg{width:100%;height:100%;transform:rotate(-90deg)}
.ring .track{fill:none;stroke:var(--line);stroke-width:10}
.ring .bar{fill:none;stroke-width:10;stroke-linecap:round;stroke-dasharray:<%= String.format(Locale.US, "%.2f", circ) %>;stroke-dashoffset:<%= String.format(Locale.US, "%.2f", circ) %>;transition:stroke-dashoffset 1.1s cubic-bezier(.2,.8,.2,1)}
.ring.go .bar{stroke-dashoffset:<%= String.format(Locale.US, "%.2f", dashOffset) %>}
.ring .mark{stroke:var(--ink);stroke-width:2}
.ring-label{position:absolute;inset:0;display:grid;place-content:center}
.ring-label strong{font-size:34px;line-height:1}
.ring-label span{font-size:12px;color:var(--muted)}
.lv-good .bar{stroke:var(--good)} .lv-ok .bar{stroke:var(--ok)} .lv-warn .bar{stroke:var(--warn)} .lv-bad .bar{stroke:var(--bad)} .lv-none .bar{stroke:var(--line)}
.pill{display:inline-block;padding:4px 12px;border-radius:999px;font-weight:700;font-size:13px}
.pill.good{background:var(--good-bg);color:var(--good)} .pill.ok{background:var(--ok-bg);color:var(--ok)}
.pill.warn{background:var(--warn-bg);color:var(--warn)} .pill.bad{background:var(--bad-bg);color:var(--bad)} .pill.none{background:var(--surface-2);color:var(--muted)}
.insight{font-size:14px;margin:0;max-width:300px}

/* stats */
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}
.stat{padding:18px 20px}
.stat .k{color:var(--muted);font-size:13px}
.stat .v{font-size:30px;font-weight:700;margin-top:4px;font-variant-numeric:tabular-nums}
.stat.good .v{color:var(--good)} .stat.bad .v{color:var(--bad)}

/* analytics */
.grid-2{display:grid;grid-template-columns:1.3fr 1fr;gap:20px}
.months{display:flex;align-items:flex-end;gap:10px;height:190px;padding-top:10px;overflow-x:auto}
.m{flex:1;min-width:46px;display:flex;flex-direction:column;align-items:center;justify-content:flex-end;height:100%;gap:6px}
.m .col{width:100%;max-width:44px;border-radius:8px 8px 3px 3px;background:var(--line);position:relative;overflow:hidden;flex:1;display:flex;align-items:flex-end}
.m .fill{width:100%;background:var(--good);transition:height .8s ease}
.m .fill.low{background:var(--warn)} .m .fill.crit{background:var(--bad)}
.m .pc{font-size:12px;font-weight:700}
.m .nm{font-size:11px;color:var(--muted)}
.facts{display:grid;gap:12px;margin:0;padding:0;list-style:none}
.facts li{display:flex;justify-content:space-between;border-bottom:1px solid var(--line);padding-bottom:10px;font-size:14px}
.facts li:last-child{border:0;padding:0}
.facts span{color:var(--muted)}
.dots{display:flex;flex-wrap:wrap;gap:4px;margin-top:16px}
.dot{width:14px;height:14px;border-radius:4px;background:var(--good)}
.dot.a{background:var(--bad)}
.legend{font-size:12px;color:var(--muted);margin-top:8px}

/* history */
.tools{display:flex;flex-wrap:wrap;gap:10px;margin-bottom:14px;align-items:center}
.tools input,.tools select{border:1px solid var(--line);background:var(--surface);color:var(--ink);border-radius:10px;padding:9px 12px}
.tools input[type=search]{flex:1;min-width:160px}
.seg{display:inline-flex;border:1px solid var(--line);border-radius:10px;overflow:hidden}
.seg button{background:var(--surface);color:var(--muted);border:0;padding:9px 14px;cursor:pointer;font-weight:600}
.seg button[aria-pressed=true]{background:var(--brand);color:var(--on-brand)}
.table-wrap{overflow-x:auto;border:1px solid var(--line);border-radius:12px}
table{width:100%;border-collapse:collapse;min-width:360px}
th,td{padding:13px 16px;text-align:left;border-bottom:1px solid var(--line);font-size:14px}
th{background:var(--surface-2);color:var(--muted);font-size:13px;font-weight:600;cursor:pointer;user-select:none;white-space:nowrap}
tbody tr:last-child td{border-bottom:0}
tbody tr:hover{background:var(--surface-2)}
.badge{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:999px;font-weight:700;font-size:12px}
.badge::before{content:"";width:7px;height:7px;border-radius:50%;background:currentColor}
.badge.present{background:var(--good-bg);color:var(--good)}
.badge.absent{background:var(--bad-bg);color:var(--bad)}
.empty{text-align:center;color:var(--muted);padding:34px 16px}
.pager{display:flex;justify-content:space-between;align-items:center;gap:10px;margin-top:14px;flex-wrap:wrap;font-size:13px;color:var(--muted)}
.pager div{display:flex;gap:8px}
.pager button:disabled{opacity:.45;cursor:not-allowed}
.error-card{background:var(--bad-bg);color:var(--bad);font-weight:600}
footer{text-align:center;color:var(--muted);font-size:12px;padding:0 20px 30px}

@media (max-width:900px){.hero,.grid-2{grid-template-columns:1fr}.stats{grid-template-columns:repeat(2,1fr)}}
@media (max-width:480px){.topbar-in{padding:10px 12px}main{padding:0 12px}.card{padding:16px}.brand small{display:none}.btn .lbl{display:none}.id-main h1{font-size:22px}}
@media (prefers-reduced-motion:reduce){*{transition:none!important;scroll-behavior:auto!important}}
@media print{.topbar,.upload,.tools,.pager,.toast,.no-print{display:none!important}body{background:#fff;color:#000}.card{box-shadow:none;break-inside:avoid}.ring .bar{transition:none;stroke-dashoffset:<%= String.format(Locale.US, "%.2f", dashOffset) %>}}
</style>
</head>
<body>
<a class="skip" href="#content">Skip to content</a>

<header class="topbar">
  <div class="topbar-in">
    <div class="brand">
      <span class="brand-mark" aria-hidden="true">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 10 12 5 2 10l10 5 10-5z"/><path d="M6 12v5c3 2 9 2 12 0v-5"/></svg>
      </span>
      <span>Student Portal<small>Attendance dashboard</small></span>
    </div>
    <button type="button" class="icon-btn" id="themeBtn" aria-label="Toggle dark mode">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>
    </button>
    <form class="logout" action="<%= request.getContextPath() %>/studentLogout" method="post">
      <button type="submit" class="btn">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5M21 12H9"/></svg>
        <span class="lbl">Log out</span>
      </button>
    </form>
  </div>
</header>

<main id="content">
<% if (errorMessage != null) { %>

  <div class="card error-card" role="alert"><%= escapeHtml(errorMessage) %></div>

<% } else { %>

  <% if (photoMessage != null) { %>
  <div class="toast <%= "success".equals(photoMessageType) ? "success" : "error" %>" role="status">
    <span><%= escapeHtml(photoMessage) %></span>
    <button type="button" aria-label="Dismiss" onclick="this.parentNode.remove()">&times;</button>
  </div>
  <% } %>

  <section class="hero" aria-label="Profile and attendance summary">
    <div class="card">
      <div class="identity">
        <div class="avatar-wrap">
          <% if (hasPhoto) { %>
            <img id="avatar" class="avatar" src="<%= request.getContextPath() %>/studentProfilePhoto" alt="Profile photo of <%= escapeHtml(studentName) %>">
          <% } else { %>
            <div id="avatar" class="avatar" aria-hidden="true"><%= escapeHtml(initial) %></div>
          <% } %>
        </div>
        <div class="id-main">
          <p class="sub" style="margin:0">Welcome back</p>
          <h1><%= escapeHtml(studentName) %></h1>
          <div class="chips">
            <span class="chip">Roll no <b><%= escapeHtml(rollNo) %></b></span>
            <span class="chip">Course <b><%= escapeHtml(course) %></b></span>
            <span class="chip">Semester <b><%= semester %></b></span>
          </div>
          <form id="photoForm" class="upload" action="<%= request.getContextPath() %>/studentProfilePhoto" method="post" enctype="multipart/form-data">
            <input type="file" id="profilePhoto" name="profilePhoto" accept="image/jpeg,image/png,image/webp" required
                   aria-label="<%= hasPhoto ? "Choose a new profile photo" : "Choose a profile photo" %>">
            <button type="submit" class="btn btn-primary" id="photoBtn"><%= hasPhoto ? "Update photo" : "Upload photo" %></button>
            <p class="hint" id="photoHint">JPG, PNG or WEBP, up to 5 MB. You can also drop an image here.</p>
          </form>
        </div>
      </div>
    </div>

    <div class="card score lv-<%= level %>">
      <div class="ring" id="ring" role="img" aria-label="Attendance <%= pctText %> percent, status <%= levelText %>">
        <svg viewBox="0 0 120 120" aria-hidden="true">
          <circle class="track" cx="60" cy="60" r="52"/>
          <circle class="bar" cx="60" cy="60" r="52"/>
          <line class="mark" x1="60" y1="3" x2="60" y2="13" transform="rotate(<%= REQUIRED * 3.6 %> 60 60)"/>
        </svg>
        <div class="ring-label"><strong><%= pctText %>%</strong><span>of <%= REQUIRED %>% required</span></div>
      </div>
      <span class="pill <%= level %>"><%= levelText %></span>
      <p class="insight"><%= escapeHtml(insight) %></p>
    </div>
  </section>

  <section class="stats" aria-label="Attendance totals">
    <div class="card stat"><div class="k">Total classes</div><div class="v"><%= totalDays %></div></div>
    <div class="card stat good"><div class="k">Present</div><div class="v"><%= presentDays %></div></div>
    <div class="card stat bad"><div class="k">Absent</div><div class="v"><%= absentDays %></div></div>
    <div class="card stat"><div class="k">Attendance</div><div class="v"><%= pctText %>%</div></div>
  </section>

  <section class="grid-2" aria-label="Attendance analysis">
    <div class="card">
      <h2>Monthly attendance</h2>
      <p class="sub">Percentage present in each month</p>
      <div class="months" id="months"></div>
    </div>
    <div class="card">
      <h2>Highlights</h2>
      <p class="sub">Calculated from your records</p>
      <ul class="facts">
        <li><span>Current present streak</span><b id="fStreak">0 days</b></li>
        <li><span>Longest present streak</span><b id="fBest">0 days</b></li>
        <li><span>Last absent on</span><b id="fLastAbs">None</b></li>
        <li><span>Best month</span><b id="fBestM">-</b></li>
      </ul>
      <div class="dots" id="dots" aria-hidden="true"></div>
      <div class="legend" id="dotsLegend"></div>
    </div>
  </section>

  <section class="card" aria-labelledby="histTitle">
    <h2 id="histTitle">Attendance history</h2>
    <p class="sub">Search, filter and export your records</p>

    <div class="tools">
      <input type="search" id="q" placeholder="Search by date (e.g. 2026-09)" aria-label="Search by date">
      <select id="month" aria-label="Filter by month"><option value="">All months</option></select>
      <div class="seg" role="group" aria-label="Filter by status">
        <button type="button" data-f="" aria-pressed="true">All</button>
        <button type="button" data-f="Present" aria-pressed="false">Present</button>
        <button type="button" data-f="Absent" aria-pressed="false">Absent</button>
      </div>
      <button type="button" class="btn" id="csvBtn">Export CSV</button>
      <button type="button" class="btn no-print" onclick="window.print()">Print</button>
    </div>

    <div class="table-wrap">
      <table id="tbl">
        <thead><tr>
          <th scope="col" id="thDate" aria-sort="descending" tabindex="0">Date &#8645;</th>
          <th scope="col">Status</th>
        </tr></thead>
        <tbody id="tbody">
        <% for (String[] record : history) {
               String st = record[1];
               String cls = "Present".equals(st) ? "present" : "absent"; %>
          <tr data-date="<%= escapeHtml(record[0]) %>" data-status="<%= escapeHtml(st) %>">
            <td><%= escapeHtml(record[0]) %></td>
            <td><span class="badge <%= cls %>"><%= escapeHtml(st) %></span></td>
          </tr>
        <% } %>
        </tbody>
      </table>
      <div class="empty" id="empty" <%= history.isEmpty() ? "" : "hidden" %>>
        <%= history.isEmpty() ? "No attendance has been recorded yet. Your records will show up here after your first class." : "No records match your filters. Try clearing the search or month." %>
      </div>
    </div>

    <div class="pager">
      <span id="count"></span>
      <div>
        <button type="button" class="btn" id="prev">Previous</button>
        <button type="button" class="btn" id="next">Next</button>
      </div>
    </div>
  </section>

<% } %>
</main>

<footer>Student Attendance Management System</footer>

<script>
(function () {
  'use strict';
  var root = document.documentElement;
  var REQUIRED = <%= REQUIRED %>;

  /* theme */
  document.getElementById('themeBtn').addEventListener('click', function () {
    var next = root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    root.setAttribute('data-theme', next);
    try { localStorage.setItem('sp-theme', next); } catch (e) {}
  });

  var tbody = document.getElementById('tbody');
  if (!tbody) return;

  /* ring animation */
  var ring = document.getElementById('ring');
  if (ring) requestAnimationFrame(function () { setTimeout(function () { ring.classList.add('go'); }, 80); });

  /* read rows once */
  var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
  var data = rows.map(function (tr) {
    return { tr: tr, date: tr.getAttribute('data-date'), status: tr.getAttribute('data-status') };
  });
  var MN = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  function mLabel(k) { var p = k.split('-'); return MN[+p[1] - 1] + ' ' + p[0].slice(2); }

  /* monthly stats */
  var byMonth = {};
  data.forEach(function (d) {
    var k = d.date.slice(0, 7);
    byMonth[k] = byMonth[k] || { p: 0, t: 0 };
    byMonth[k].t++; if (d.status === 'Present') byMonth[k].p++;
  });
  var keys = Object.keys(byMonth).sort();
  var mBox = document.getElementById('months');
  if (!keys.length) { mBox.innerHTML = '<div class="empty" style="width:100%">Monthly chart will appear once classes are recorded.</div>'; }
  var bestKey = null, bestPct = -1;
  keys.slice(-8).forEach(function (k) {
    var m = byMonth[k], pc = Math.round(m.p * 100 / m.t);
    var el = document.createElement('div'); el.className = 'm';
    el.title = mLabel(k) + ': ' + m.p + ' of ' + m.t + ' classes present';
    el.innerHTML = '<span class="pc">' + pc + '%</span><div class="col"><div class="fill' +
      (pc < REQUIRED - 10 ? ' crit' : pc < REQUIRED ? ' low' : '') + '" style="height:0"></div></div><span class="nm">' + mLabel(k) + '</span>';
    mBox.appendChild(el);
    var f = el.querySelector('.fill');
    setTimeout(function () { f.style.height = pc + '%'; }, 120);
  });
  keys.forEach(function (k) { var pc = byMonth[k].p / byMonth[k].t; if (pc > bestPct) { bestPct = pc; bestKey = k; } });
  if (bestKey) document.getElementById('fBestM').textContent = mLabel(bestKey) + ' (' + Math.round(bestPct * 100) + '%)';

  /* streaks (data is newest first) */
  var cur = 0, best = 0, run = 0, counting = true, lastAbs = null;
  data.forEach(function (d) {
    if (d.status === 'Present') { run++; if (counting) cur++; best = Math.max(best, run); }
    else { counting = false; run = 0; if (!lastAbs) lastAbs = d.date; }
  });
  function days(n) { return n + (n === 1 ? ' day' : ' days'); }
  document.getElementById('fStreak').textContent = days(cur);
  document.getElementById('fBest').textContent = days(best);
  document.getElementById('fLastAbs').textContent = lastAbs || 'None';

  /* last 30 records dots (oldest to newest) */
  var dots = document.getElementById('dots');
  data.slice(0, 30).reverse().forEach(function (d) {
    var s = document.createElement('span'); s.className = 'dot' + (d.status === 'Absent' ? ' a' : ''); s.title = d.date + ' - ' + d.status; dots.appendChild(s);
  });
  document.getElementById('dotsLegend').textContent = data.length ? 'Last ' + Math.min(30, data.length) + ' classes: green is present, red is absent.' : '';

  /* month filter options */
  var sel = document.getElementById('month');
  keys.slice().reverse().forEach(function (k) { var o = document.createElement('option'); o.value = k; o.textContent = mLabel(k); sel.appendChild(o); });

  /* filter + sort + paginate */
  var state = { f: '', q: '', m: '', page: 1, size: 10, desc: true };
  var empty = document.getElementById('empty'), count = document.getElementById('count');
  var prev = document.getElementById('prev'), next = document.getElementById('next');
  var filtered = [];

  function render() {
    filtered = data.filter(function (d) {
      return (!state.f || d.status === state.f) && (!state.m || d.date.indexOf(state.m) === 0) && (!state.q || d.date.indexOf(state.q) !== -1);
    });
    filtered.sort(function (a, b) { return state.desc ? (a.date < b.date ? 1 : a.date > b.date ? -1 : 0) : (a.date > b.date ? 1 : a.date < b.date ? -1 : 0); });
    var pages = Math.max(1, Math.ceil(filtered.length / state.size));
    if (state.page > pages) state.page = pages;
    var start = (state.page - 1) * state.size;
    data.forEach(function (d) { d.tr.hidden = true; });
    filtered.slice(start, start + state.size).forEach(function (d) { d.tr.hidden = false; tbody.appendChild(d.tr); });
    if (data.length) empty.hidden = filtered.length > 0;
    count.textContent = filtered.length ? 'Showing ' + (start + 1) + '-' + Math.min(start + state.size, filtered.length) + ' of ' + filtered.length + ' records' : '0 records';
    prev.disabled = state.page <= 1; next.disabled = state.page >= pages;
  }
  document.getElementById('q').addEventListener('input', function (e) { state.q = e.target.value.trim(); state.page = 1; render(); });
  sel.addEventListener('change', function () { state.m = sel.value; state.page = 1; render(); });
  Array.prototype.forEach.call(document.querySelectorAll('.seg button'), function (b) {
    b.addEventListener('click', function () {
      state.f = b.getAttribute('data-f'); state.page = 1;
      Array.prototype.forEach.call(document.querySelectorAll('.seg button'), function (x) { x.setAttribute('aria-pressed', x === b ? 'true' : 'false'); });
      render();
    });
  });
  var th = document.getElementById('thDate');
  function toggleSort() { state.desc = !state.desc; th.setAttribute('aria-sort', state.desc ? 'descending' : 'ascending'); render(); }
  th.addEventListener('click', toggleSort);
  th.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggleSort(); } });
  prev.addEventListener('click', function () { state.page--; render(); });
  next.addEventListener('click', function () { state.page++; render(); });
  render();

  /* CSV export of current filter */
  document.getElementById('csvBtn').addEventListener('click', function () {
    var out = ['Date,Status'].concat(filtered.map(function (d) { return d.date + ',' + d.status; })).join('\r\n');
    var a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([out], { type: 'text/csv;charset=utf-8' }));
    a.download = 'my-attendance.csv'; document.body.appendChild(a); a.click(); a.remove();
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 1000);
  });

  /* photo: validate, preview, drag and drop */
  var input = document.getElementById('profilePhoto'), hint = document.getElementById('photoHint');
  var box = document.getElementById('photoForm'), btn = document.getElementById('photoBtn');
  var MAX = 5 * 1024 * 1024, OK = ['image/jpeg', 'image/png', 'image/webp'];
  function check() {
    var f = input.files && input.files[0]; hint.className = 'hint'; btn.disabled = false;
    if (!f) return;
    if (OK.indexOf(f.type) === -1) { hint.textContent = 'This file type is not supported. Choose a JPG, PNG or WEBP image.'; hint.className = 'hint err'; btn.disabled = true; input.value = ''; return; }
    if (f.size > MAX) { hint.textContent = 'This image is ' + (f.size / 1048576).toFixed(1) + ' MB. Choose one under 5 MB.'; hint.className = 'hint err'; btn.disabled = true; input.value = ''; return; }
    hint.textContent = f.name + ' is ready to upload.';
    var url = URL.createObjectURL(f), av = document.getElementById('avatar');
    if (av.tagName === 'IMG') { av.src = url; }
    else { var img = document.createElement('img'); img.id = 'avatar'; img.className = 'avatar'; img.alt = 'Preview of new profile photo'; img.src = url; av.replaceWith(img); }
  }
  input.addEventListener('change', check);
  ['dragenter', 'dragover'].forEach(function (ev) { box.addEventListener(ev, function (e) { e.preventDefault(); box.classList.add('drag'); }); });
  ['dragleave', 'drop'].forEach(function (ev) { box.addEventListener(ev, function (e) { e.preventDefault(); box.classList.remove('drag'); }); });
  box.addEventListener('drop', function (e) { if (e.dataTransfer.files.length) { input.files = e.dataTransfer.files; check(); } });
  box.addEventListener('submit', function () { btn.disabled = true; btn.textContent = 'Uploading...'; });
})();
</script>
</body>
</html>