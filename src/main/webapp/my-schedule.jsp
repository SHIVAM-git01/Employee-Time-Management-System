
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
            || !"EMPLOYEE".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("index.jsp");
        return;
    }
    List<Map<String,Object>> schedules =
            (List<Map<String,Object>>) request.getAttribute("schedules");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>My Schedule | ETMS</title>
<style>
body{margin:0;font-family:Arial,sans-serif;background:#f1f5f9;color:#0f172a}
header{background:#1d4ed8;color:white;padding:20px 6%;display:flex;justify-content:space-between}
header a{color:white;text-decoration:none}
main{max-width:950px;margin:auto;padding:30px 5%}
.card{background:white;padding:24px;border-radius:14px;box-shadow:0 5px 20px #0000000d}
table{width:100%;border-collapse:collapse}
th,td{text-align:left;padding:14px;border-bottom:1px solid #e2e8f0}
th{background:#eff6ff;color:#1d4ed8}
.wrap{overflow-x:auto}
</style>
</head>
<body>
<header><strong>ETMS | My Schedule</strong><a href="employee-dashboard.jsp">Employee Dashboard</a></header>
<main><section class="card">
<h1>My Weekly Schedule</h1>
<div class="wrap"><table><thead><tr><th>Day</th><th>Shift Start</th><th>Shift End</th></tr></thead>
<tbody>
<% if (schedules != null && !schedules.isEmpty()) {
for (Map<String,Object> item : schedules) { %>
<tr><td><%= esc(item.get("day")) %></td><td><%= esc(item.get("start") == null ? "" : item.get("start").toString().substring(0,5)) %></td><td><%= esc(item.get("end") == null ? "" : item.get("end").toString().substring(0,5)) %></td></tr>
<% } } else { %><tr><td colspan="3">No schedule assigned yet. Please contact HR.</td></tr><% } %>
</tbody></table></div>
</section></main>
</body>
</html>
