
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List,java.util.Map" %>

<%!
private String esc(Object value) {
    if (value == null) return "";
    return String.valueOf(value)
        .replace("&","&amp;").replace("<","&lt;")
        .replace(">","&gt;").replace("\"","&quot;")
        .replace("'","&#39;");
}
%>

<%
if (!(session.getAttribute("teacherId") instanceof Integer)
        || !"TEACHER".equals(session.getAttribute("userRole"))) {
    response.sendRedirect(request.getContextPath()+"/teacherLogin.jsp");
    return;
}

List<Map<String,Object>> students =
    (List<Map<String,Object>>)request.getAttribute("students");

String search = (String)request.getAttribute("search");
String status = (String)request.getAttribute("status");
String csrf = (String)session.getAttribute("studentMgmtCsrf");
String message = (String)session.getAttribute("studentMgmtMessage");

if(search==null) search="";
if(status==null) status="active";
if(message!=null) session.removeAttribute("studentMgmtMessage");

String base=request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Student Management | AttendancePro</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#f3f6fb;color:#1d2939;font-family:"Segoe UI",Arial,sans-serif}
header{background:#17365d;color:white;padding:20px 5%;display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap}
header h1{font-size:22px;margin:0}
header a{color:white;text-decoration:none;border:1px solid #ffffff80;padding:9px 14px;border-radius:7px}
main{max-width:1450px;margin:30px auto;padding:0 18px}
.panel{background:white;padding:22px;border-radius:13px;box-shadow:0 4px 18px #172b4d0d;margin-bottom:20px}
h2{color:#17365d;margin-top:0}
p{color:#667085;line-height:1.6}
input,select{padding:10px;border:1px solid #d0d5dd;border-radius:7px;font:inherit;width:100%;min-width:90px}
.searchbar{display:flex;gap:10px;flex-wrap:wrap}
.searchbar input{flex:1;min-width:200px}
button,.btn{border:0;border-radius:7px;padding:10px 14px;font:inherit;font-weight:600;cursor:pointer;text-decoration:none;display:inline-block}
.primary{background:#2457a7;color:white}
.secondary{background:#e9eef7;color:#17365d}
.danger{background:#fee4e2;color:#b42318}
.success{background:#dcfae6;color:#067647}
.warning{background:#fff0c2;color:#854d0e}
.notice{background:#ecfdf3;color:#067647;border:1px solid #abefc6;padding:13px;border-radius:8px;margin-bottom:18px}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;min-width:1200px}
th,td{padding:12px 9px;border-bottom:1px solid #eaecf0;text-align:left;vertical-align:top}
th{background:#f8fafc;color:#475467;font-size:13px}
td label{display:block;font-size:12px;color:#667085;margin:7px 0 4px}
td form{margin:0}
.status{font-size:12px;font-weight:700;padding:5px 9px;border-radius:20px;display:inline-block}
.active{background:#dcfae6;color:#067647}
.archived{background:#fee4e2;color:#b42318}
.small{font-size:12px;color:#667085}
.empty{text-align:center;padding:35px;color:#667085}
.action-stack{display:flex;flex-direction:column;gap:9px;min-width:180px}
footer{text-align:center;color:#667085;padding:25px;font-size:12px}
@media(max-width:650px){header{padding:17px}main{padding:0 12px;margin:18px auto}.panel{padding:15px}header h1{font-size:18px}}
</style>
</head>
<body>

<header>
<h1>AttendancePro | Student Management</h1>
<a href="<%=base%>/teacherDashboard.jsp">Back to Dashboard</a>
</header>

<main>
<section class="panel">
<h2>Manage Students</h2>
<p>Search and update student details. Archiving preserves attendance and alert history.</p>

<% if(message!=null && !message.isBlank()){ %>
<div class="notice"><%=esc(message)%></div>
<% } %>

<form class="searchbar" method="get" action="<%=base%>/teacherStudents">
<input name="search" placeholder="Search roll number, name, email or phone" value="<%=esc(search)%>">
<select name="status">
<option value="active" <%= "active".equals(status)?"selected":"" %>>Active Students</option>
<option value="archived" <%= "archived".equals(status)?"selected":"" %>>Archived Students</option>
<option value="all" <%= "all".equals(status)?"selected":"" %>>All Students</option>
</select>
<button class="primary">Search</button>
<a class="btn secondary" href="<%=base%>/teacherStudents">Reset</a>
</form>
</section>

<section class="panel">
<h2>Student Records</h2>

<% if(students==null || students.isEmpty()){ %>
<div class="empty">No student records found.</div>
<% } else { %>

<div class="table-wrap">
<table>
<thead>
<tr>
<th>ID</th><th>Roll Number</th><th>Name</th><th>Course</th>
<th>Semester</th><th>Email</th><th>Phone</th>
<th>Account</th><th>Status</th><th>Actions</th>
</tr>
</thead>
<tbody>

<% for(Map<String,Object> s:students){
int id=(Integer)s.get("studentId");
boolean active=Boolean.TRUE.equals(s.get("active"));
boolean account=Boolean.TRUE.equals(s.get("hasAccount"));
%>

<tr>
<td><strong><%=id%></strong></td>

<td colspan="6">
<form method="post" action="<%=base%>/teacherStudents">
<input type="hidden" name="csrfToken" value="<%=esc(csrf)%>">
<input type="hidden" name="action" value="update">
<input type="hidden" name="studentId" value="<%=id%>">
<input type="hidden" name="search" value="<%=esc(search)%>">
<input type="hidden" name="status" value="<%=esc(status)%>">

<div style="display:grid;grid-template-columns:repeat(3,minmax(140px,1fr));gap:10px">
<div><label>Roll Number</label>
<input name="rollNo" type="text" inputmode="numeric" pattern="[0-9]{13}" minlength="13" maxlength="13" title="Roll number must contain exactly 13 digits" required value="<%=esc(s.get("rollNo"))%>"></div>

<div><label>Student Name</label>
<input name="name" maxlength="100" required value="<%=esc(s.get("name"))%>"></div>

<div><label>Course</label>
<input name="course" maxlength="50" value="<%=esc(s.get("course"))%>"></div>

<div><label>Semester</label>
<input name="semester" type="number" min="1" value="<%=esc(s.get("semester"))%>"></div>

<div><label>Email</label>
<input name="email" maxlength="150" value="<%=esc(s.get("email"))%>"></div>

<div><label>Phone</label>
<input name="phone" maxlength="10" value="<%=esc(s.get("phone"))%>"></div>
</div>
<button class="primary" type="submit" style="margin-top:10px">Save All Details</button>
</form>
</td>

<td>
<% if(account){ %><span class="status active">Registered</span>
<% }else{ %><span class="status archived">No Account</span><% } %>
</td>

<td>
<% if(active){ %><span class="status active">Active</span>
<% }else{ %><span class="status archived">Archived</span><% } %>
</td>

<td>
<div class="action-stack">

<% if(active){ %>
<form method="post" action="<%=base%>/teacherStudents"
onsubmit="return confirm('Archive this student? Attendance history will be preserved.');">
<input type="hidden" name="csrfToken" value="<%=esc(csrf)%>">
<input type="hidden" name="action" value="archive">
<input type="hidden" name="studentId" value="<%=id%>">
<input type="hidden" name="search" value="<%=esc(search)%>">
<input type="hidden" name="status" value="<%=esc(status)%>">
<button class="danger" type="submit">Archive Student</button>
</form>

<% }else{ %>
<form method="post" action="<%=base%>/teacherStudents"
onsubmit="return confirm('Restore this student?');">
<input type="hidden" name="csrfToken" value="<%=esc(csrf)%>">
<input type="hidden" name="action" value="restore">
<input type="hidden" name="studentId" value="<%=id%>">
<input type="hidden" name="search" value="<%=esc(search)%>">
<input type="hidden" name="status" value="<%=esc(status)%>">
<button class="success" type="submit">Restore Student</button>
</form>
<% } %>

</div>
</td>
</tr>
<% } %>

</tbody>
</table>
</div>
<% } %>
</section>
</main>

<footer>AttendancePro &copy; 2026 | Student Attendance Management System</footer>
</body>
</html>
