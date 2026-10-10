
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>

<%!
    private String esc(Object value) {
        if (value == null) return "";
        return value.toString().replace("&", "&amp;")
                .replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    if (session.getAttribute("employeeId") == null
            || !"HR".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("index.jsp");
        return;
    }

    List<Map<String, Object>> employees =
            (List<Map<String, Object>>) request.getAttribute("employees");
    List<Map<String, Object>> schedules =
            (List<Map<String, Object>>) request.getAttribute("schedules");

    String status = request.getParameter("status");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Manage Schedules | ETMS</title>
<style>
*{box-sizing:border-box}
body{margin:0;font-family:Arial,sans-serif;background:#f1f5f9;color:#0f172a}
header{background:#1d4ed8;color:white;padding:22px 6%;display:flex;justify-content:space-between}
header a{color:white;text-decoration:none}
main{max-width:1200px;margin:auto;padding:28px 5%}
.card{background:white;padding:24px;border-radius:14px;margin-bottom:22px;box-shadow:0 5px 20px #0000000d}
.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:15px}
label{display:block;font-weight:bold;margin-bottom:7px}
input,select{width:100%;padding:11px;border:1px solid #cbd5e1;border-radius:7px}
button,.btn{display:inline-block;padding:11px 16px;border:0;border-radius:7px;background:#2563eb;color:white;text-decoration:none;cursor:pointer;font-weight:bold}
.notice{padding:12px;border-radius:8px;background:#dcfce7;margin:15px 0}
.error{background:#fee2e2}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;min-width:650px}
th,td{text-align:left;padding:12px;border-bottom:1px solid #e2e8f0}
th{background:#eff6ff;color:#1d4ed8}
@media(max-width:600px){.grid{grid-template-columns:1fr}main{padding:20px 4%}.card{padding:17px}}
</style>
</head>
<body>
<header><strong>ETMS | Schedule Management</strong><a href="hr-dashboard.jsp">HR Dashboard</a></header>
<main>
<section class="card">
<h1>Manage Employee Schedules</h1>
<p>Assign or update a shift for an employee on a particular weekday.</p>
<% if ("saved".equals(status)) { %>
<div class="notice">Schedule saved successfully.</div>
<% } else if ("invalid".equals(status)) { %>
<div class="notice error">Invalid employee, day or shift time. End time must be after start time.</div>
<% } %>

<form action="schedules" method="post">
<div class="grid">
<div><label for="employeeId">Employee</label>
<select id="employeeId" name="employeeId" required>
<option value="">Select employee</option>
<% if (employees != null) for (Map<String,Object> employee : employees) { %>
<option value="<%= employee.get("id") %>"><%= esc(employee.get("name")) %> (ID <%= employee.get("id") %>)</option>
<% } %>
</select></div>
<div><label for="workDay">Working day</label>
<select id="workDay" name="workDay" required>
<option>Monday</option><option>Tuesday</option><option>Wednesday</option>
<option>Thursday</option><option>Friday</option><option>Saturday</option><option>Sunday</option>
</select></div>
<div><label for="shiftStart">Shift start</label><input id="shiftStart" name="shiftStart" type="time" required></div>
<div><label for="shiftEnd">Shift end</label><input id="shiftEnd" name="shiftEnd" type="time" required></div>
</div>
<p><button type="submit">Save / Update Schedule</button></p>
</form>
</section>

<section class="card">
<h2>Assigned Schedules</h2>
<div class="table-wrap"><table>
<thead><tr><th>Employee</th><th>Day</th><th>Shift Start</th><th>Shift End</th></tr></thead>
<tbody>
<% if (schedules != null && !schedules.isEmpty()) {
for (Map<String,Object> item : schedules) { %>
<tr><td><%= esc(item.get("name")) %> (ID <%= item.get("employeeId") %>)</td>
<td><%= esc(item.get("day")) %></td><td><%= esc(item.get("start")) %></td><td><%= esc(item.get("end")) %></td></tr>
<% } } else { %>
<tr><td colspan="4">No schedules assigned yet.</td></tr>
<% } %>
</tbody></table></div>
</section>
</main>
</body>
</html>
