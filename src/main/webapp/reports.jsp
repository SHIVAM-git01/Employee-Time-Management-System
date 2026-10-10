<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="com.etms.util.DBConnection" %>

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

    LocalDate today = LocalDate.now();
    LocalDate defaultStart = today.withDayOfMonth(1);
    LocalDate startDate = defaultStart;
    LocalDate endDate = today;
    String startParam = request.getParameter("startDate");
    String endParam = request.getParameter("endDate");
    String errorMessage = "";

    try {
        if (startParam != null && !startParam.isBlank()) startDate = LocalDate.parse(startParam);
        if (endParam != null && !endParam.isBlank()) endDate = LocalDate.parse(endParam);
        if (startDate.isAfter(endDate)) {
            errorMessage = "Start date must be on or before end date.";
            startDate = defaultStart;
            endDate = today;
        }
    } catch (Exception ex) {
        errorMessage = "Invalid date range. Showing the current month's records.";
        startDate = defaultStart;
        endDate = today;
    }

    int attendanceRecords = 0;
    int fullDays = 0;
    int halfDays = 0;
    int absentDays = 0;
    int leaveDays = 0;
    int leaveRequests = 0;
    int pendingRequests = 0;
    int approvedRequests = 0;
    int rejectedRequests = 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ETMS | Attendance &amp; Leave Reports</title>
<style>
*{box-sizing:border-box}
:root{--navy:#172554;--blue:#2563eb;--muted:#64748b;--line:#e2e8f0}
body{margin:0;font-family:Inter,Segoe UI,Arial,sans-serif;background:linear-gradient(135deg,#f8fafc,#eef2ff);color:#0f172a}
header{background:linear-gradient(120deg,#172554,#1d4ed8 65%,#4f46e5);color:#fff;padding:20px 6%;display:flex;justify-content:space-between;align-items:center;gap:16px;box-shadow:0 8px 24px #1e40af20}
header h2{margin:0;font-size:21px}
header a{color:#fff;text-decoration:none;font-weight:700}
main{max-width:1450px;margin:auto;padding:30px 6%}
.intro{display:flex;justify-content:space-between;align-items:flex-start;gap:20px;flex-wrap:wrap}
h1{margin:0 0 8px;font-size:28px}
.sub{color:var(--muted);margin:0 0 20px}
.card{background:#fff;border:1px solid var(--line);border-radius:16px;padding:22px;margin-bottom:22px;box-shadow:0 8px 24px #0f172a0b}
.filters{display:grid;grid-template-columns:repeat(2,minmax(0,1fr)) auto;gap:14px;align-items:end}
label{display:block;font-weight:700;font-size:13px;margin-bottom:7px;color:#334155}
input{width:100%;padding:12px;border:1px solid #cbd5e1;border-radius:9px;font:inherit}
button,.link{display:inline-flex;align-items:center;justify-content:center;background:var(--blue);color:#fff;border:0;border-radius:9px;padding:12px 16px;font-weight:700;text-decoration:none;cursor:pointer}
.link{background:#eef2ff;color:#3730a3;border:1px solid #c7d2fe}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(155px,1fr));gap:14px;margin-bottom:22px}
.stat{background:#fff;border:1px solid var(--line);border-radius:14px;padding:19px;box-shadow:0 5px 18px #0f172a08}
.stat .label{font-size:13px;color:var(--muted);font-weight:700}
.stat .number{font-size:29px;font-weight:800;margin-top:8px;color:#1d4ed8}
.stat:nth-child(2) .number{color:#15803d}.stat:nth-child(3) .number{color:#b45309}.stat:nth-child(4) .number{color:#b91c1c}
.section-title{display:flex;justify-content:space-between;gap:12px;align-items:center;flex-wrap:wrap}
h2{color:var(--navy);margin:0 0 12px;font-size:20px}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;min-width:850px}
th,td{text-align:left;padding:12px;border-bottom:1px solid #e2e8f0;vertical-align:top}
th{background:#eff6ff;color:#1d4ed8;font-size:12px;text-transform:uppercase;letter-spacing:.04em}
tbody tr:hover{background:#f8fafc}
.badge{display:inline-block;padding:5px 9px;border-radius:999px;font-size:11px;font-weight:800;background:#e2e8f0;color:#334155}
.full_day,.present,.approved{background:#dcfce7;color:#166534}.half_day,.pending{background:#fef3c7;color:#92400e}.absent,.rejected{background:#fee2e2;color:#991b1b}.on_leave{background:#dbeafe;color:#1d4ed8}
.notice{background:#fff7ed;color:#9a3412;border:1px solid #fed7aa;padding:12px;border-radius:10px;margin-bottom:16px}
.empty{padding:20px;color:var(--muted);text-align:center}
footer{text-align:center;padding:20px;color:var(--muted)}
@media(max-width:700px){header{padding:18px 5%;align-items:flex-start;flex-wrap:wrap}main{padding:22px 5%}.card{padding:17px}.filters{grid-template-columns:1fr}.filters button{width:100%}.stats{grid-template-columns:repeat(2,minmax(0,1fr))}}
</style>
</head>
<body>
<header>
    <h2>ETMS | Reports &amp; Insights</h2>
    <a href="hr-dashboard.jsp">← HR Dashboard</a>
</header>
<main>
    <div class="intro">
        <div>
            <h1>Attendance &amp; Leave Reports</h1>
            <p class="sub">Filter records by date range and review attendance and leave activity.</p>
        </div>
        <a class="link" href="reports.jsp">Reset to current month</a>
    </div>

    <section class="card">
        <form class="filters" method="get" action="reports.jsp">
            <div>
                <label for="startDate">From date</label>
                <input id="startDate" name="startDate" type="date" required value="<%= startDate %>">
            </div>
            <div>
                <label for="endDate">To date</label>
                <input id="endDate" name="endDate" type="date" required value="<%= endDate %>">
            </div>
            <button type="submit">Generate Report</button>
        </form>
    </section>

    <% if (!errorMessage.isEmpty()) { %><div class="notice"><%= esc(errorMessage) %></div><% } %>

    <div class="stats">
        <div class="stat"><div class="label">Attendance Records</div><div class="number"><%
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM time_logs WHERE work_date BETWEEN ? AND ?")) {
                ps.setDate(1, java.sql.Date.valueOf(startDate)); ps.setDate(2, java.sql.Date.valueOf(endDate));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) attendanceRecords = rs.getInt(1); }
            } catch (SQLException e) { application.log("Report attendance count failed", e); }
        %><%= attendanceRecords %></div></div>
        <div class="stat"><div class="label">Full Days</div><div class="number"><%
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM time_logs WHERE work_date BETWEEN ? AND ? AND attendance_status = 'FULL_DAY'")) {
                ps.setDate(1, java.sql.Date.valueOf(startDate)); ps.setDate(2, java.sql.Date.valueOf(endDate));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) fullDays = rs.getInt(1); }
            } catch (SQLException e) { application.log("Report full-day count failed", e); }
        %><%= fullDays %></div></div>
        <div class="stat"><div class="label">Half Days</div><div class="number"><%
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM time_logs WHERE work_date BETWEEN ? AND ? AND attendance_status = 'HALF_DAY'")) {
                ps.setDate(1, java.sql.Date.valueOf(startDate)); ps.setDate(2, java.sql.Date.valueOf(endDate));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) halfDays = rs.getInt(1); }
            } catch (SQLException e) { application.log("Report half-day count failed", e); }
        %><%= halfDays %></div></div>
        <div class="stat"><div class="label">Absent</div><div class="number"><%
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM time_logs WHERE work_date BETWEEN ? AND ? AND attendance_status = 'ABSENT'")) {
                ps.setDate(1, java.sql.Date.valueOf(startDate)); ps.setDate(2, java.sql.Date.valueOf(endDate));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) absentDays = rs.getInt(1); }
            } catch (SQLException e) { application.log("Report absent count failed", e); }
        %><%= absentDays %></div></div>
        <div class="stat"><div class="label">Leave Requests Received</div><div class="number"><%
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM leave_requests WHERE start_date <= ? AND end_date >= ?")) {
                ps.setDate(1, java.sql.Date.valueOf(endDate)); ps.setDate(2, java.sql.Date.valueOf(startDate));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) leaveRequests = rs.getInt(1); }
            } catch (SQLException e) { application.log("Report leave count failed", e); }
        %><%= leaveRequests %></div></div>
        <div class="stat"><div class="label">Pending Leaves</div><div class="number"><%
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM leave_requests WHERE status='PENDING' AND start_date <= ? AND end_date >= ?")) {
                ps.setDate(1, java.sql.Date.valueOf(endDate)); ps.setDate(2, java.sql.Date.valueOf(startDate));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) pendingRequests = rs.getInt(1); }
            } catch (SQLException e) { application.log("Report pending leave count failed", e); }
        %><%= pendingRequests %></div></div>
        <div class="stat"><div class="label">Approved Leaves</div><div class="number"><%
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM leave_requests WHERE status='APPROVED' AND start_date <= ? AND end_date >= ?")) {
                ps.setDate(1, java.sql.Date.valueOf(endDate)); ps.setDate(2, java.sql.Date.valueOf(startDate));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) approvedRequests = rs.getInt(1); }
            } catch (SQLException e) { application.log("Report approved leave count failed", e); }
        %><%= approvedRequests %></div></div>
        <div class="stat"><div class="label">Rejected Leaves</div><div class="number"><%
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM leave_requests WHERE status='REJECTED' AND start_date <= ? AND end_date >= ?")) {
                ps.setDate(1, java.sql.Date.valueOf(endDate)); ps.setDate(2, java.sql.Date.valueOf(startDate));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) rejectedRequests = rs.getInt(1); }
            } catch (SQLException e) { application.log("Report rejected leave count failed", e); }
        %><%= rejectedRequests %></div></div>
    </div>

    <section class="card">
        <div class="section-title"><h2>Attendance Details</h2><span class="badge"><%= startDate %> to <%= endDate %></span></div>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Date</th><th>Employee</th><th>Email</th><th>Check In</th><th>Check Out</th><th>Status</th><th>Attendance Count</th></tr></thead>
                <tbody>
                <%
                    String attendanceSql = "SELECT e.full_name,e.email,t.work_date,t.check_in,t.check_out,t.attendance_status,t.attendance_count "
                                         + "FROM time_logs t JOIN employees e ON e.employee_id=t.employee_id "
                                         + "WHERE t.work_date BETWEEN ? AND ? ORDER BY t.work_date DESC,e.full_name";
                    try (Connection con = DBConnection.getConnection();
                         PreparedStatement ps = con.prepareStatement(attendanceSql)) {
                        ps.setDate(1, java.sql.Date.valueOf(startDate)); ps.setDate(2, java.sql.Date.valueOf(endDate));
                        try (ResultSet rs = ps.executeQuery()) {
                            boolean found = false;
                            while (rs.next()) {
                                found = true;
                                String status = rs.getString("attendance_status");
                                String statusClass = status == null ? "" : status.toLowerCase();
                %>
                    <tr>
                        <td><%= rs.getDate("work_date") %></td>
                        <td><strong><%= esc(rs.getString("full_name")) %></strong></td>
                        <td><%= esc(rs.getString("email")) %></td>
                        <td><%= rs.getTimestamp("check_in") == null ? "—" : rs.getTimestamp("check_in").toLocalDateTime().toLocalTime() %></td>
                        <td><%= rs.getTimestamp("check_out") == null ? "—" : rs.getTimestamp("check_out").toLocalDateTime().toLocalTime() %></td>
                        <td><span class="badge <%= esc(statusClass) %>"><%= esc(status == null ? "NOT MARKED" : status.replace('_',' ')) %></span></td>
                        <td><%= rs.getBigDecimal("attendance_count") == null ? "0" : rs.getBigDecimal("attendance_count") %></td>
                    </tr>
                <%
                            }
                            if (!found) {
                %>
                    <tr><td colspan="7" class="empty">No attendance records found for this date range.</td></tr>
                <%
                            }
                        }
                    } catch (SQLException e) {
                        application.log("Attendance report query failed", e);
                %>
                    <tr><td colspan="7" class="empty">Unable to load attendance details. Check the Tomcat log.</td></tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>
    </section>

    <section class="card">
        <div class="section-title"><h2>Leave Request Details</h2><span class="badge"><%= startDate %> to <%= endDate %></span></div>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Employee</th><th>Leave Type</th><th>Dates</th><th>Period</th><th>Reason</th><th>Applied At</th><th>Status</th></tr></thead>
                <tbody>
                <%
                    String leaveSql = "SELECT e.full_name,e.email,l.leave_type,l.start_date,l.end_date,l.half_day_period,l.reason,l.applied_at,l.status "
                                    + "FROM leave_requests l JOIN employees e ON e.employee_id=l.employee_id "
                                    + "WHERE l.start_date <= ? AND l.end_date >= ? "
                                    + "ORDER BY l.applied_at DESC";
                    try (Connection con = DBConnection.getConnection();
                         PreparedStatement ps = con.prepareStatement(leaveSql)) {
                        ps.setDate(1, java.sql.Date.valueOf(endDate)); ps.setDate(2, java.sql.Date.valueOf(startDate));
                        try (ResultSet rs = ps.executeQuery()) {
                            boolean found = false;
                            while (rs.next()) {
                                found = true;
                                String status = rs.getString("status");
                                String statusClass = status == null ? "" : status.toLowerCase();
                                String type = rs.getString("leave_type");
                %>
                    <tr>
                        <td><strong><%= esc(rs.getString("full_name")) %></strong><br><small><%= esc(rs.getString("email")) %></small></td>
                        <td><%= "HALF_DAY".equals(type) ? "Half Day" : "Full Day" %></td>
                        <td><%= rs.getDate("start_date") %> – <%= rs.getDate("end_date") %></td>
                        <td><%= esc(rs.getString("half_day_period") == null ? "—" : rs.getString("half_day_period")) %></td>
                        <td><%= esc(rs.getString("reason")) %></td>
                        <td><%= rs.getTimestamp("applied_at") == null ? "—" : rs.getTimestamp("applied_at") %></td>
                        <td><span class="badge <%= esc(statusClass) %>"><%= esc(status) %></span></td>
                    </tr>
                <%
                            }
                            if (!found) {
                %>
                    <tr><td colspan="7" class="empty">No leave requests overlap this date range.</td></tr>
                <%
                            }
                        }
                    } catch (SQLException e) {
                        application.log("Leave report query failed", e);
                %>
                    <tr><td colspan="7" class="empty">Unable to load leave details. Check the Tomcat log.</td></tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>
    </section>
</main>
<footer>ETMS · HR Reports · Filtered by selected date range</footer>
</body>
</html>
