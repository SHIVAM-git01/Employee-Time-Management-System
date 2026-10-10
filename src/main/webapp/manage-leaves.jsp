<%@ page import="java.sql.*" %>
<%@ page import="com.etms.util.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>

<%
    Integer employeeId = (Integer) session.getAttribute("employeeId");
    String role = (String) session.getAttribute("userRole");

    if (employeeId == null || !"HR".equals(role)) {
        response.sendRedirect("index.jsp");
        return;
    }

    String message = request.getParameter("message");

    String sql =
        "SELECT l.leave_id, l.employee_id, e.full_name, e.email, " +
        "l.start_date, l.end_date, l.reason, l.status, " +
        "l.leave_type, l.half_day_period, l.applied_at " +
        "FROM leave_requests l " +
        "JOIN employees e ON l.employee_id = e.employee_id " +
        "ORDER BY CASE WHEN l.status = 'PENDING' THEN 0 ELSE 1 END, " +
        "l.applied_at DESC";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Manage Leaves | ETMS</title>
<style>
*{box-sizing:border-box}
body{margin:0;font-family:Arial,sans-serif;background:#f3f6fb;color:#1e293b}
header{background:#172554;color:white;padding:20px 7%;display:flex;justify-content:space-between;align-items:center;gap:12px}
header a{color:white;text-decoration:none}
main{max-width:1250px;margin:30px auto;padding:0 18px}
.card{background:white;padding:24px;border-radius:12px;box-shadow:0 3px 14px #0000000d}
.notice{padding:12px;border-radius:7px;margin-bottom:18px;background:#dbeafe}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;min-width:1000px}
th,td{text-align:left;padding:12px;border-bottom:1px solid #e2e8f0;vertical-align:top}
th{background:#eff6ff}
.status{font-weight:bold}
form{display:inline-block;margin:3px}
button{padding:9px 12px;border:0;border-radius:6px;color:white;cursor:pointer;font-weight:bold}
.approve{background:#15803d}
.reject{background:#b91c1c}
.pending{color:#a16207}
.approved{color:#15803d}
.rejected{color:#b91c1c}
@media(max-width:600px){header{padding:18px;gap:12px}.card{padding:15px}}
</style>
</head>
<body>
<header>
    <strong>ETMS | Leave Approvals</strong>
    <a href="hr-dashboard.jsp">← HR Dashboard</a>
</header>

<main>
    <h2>Employee Leave Requests</h2>

    <% if ("approved".equals(message)) { %>
        <div class="notice">Leave request approved successfully.</div>
    <% } else if ("rejected".equals(message)) { %>
        <div class="notice">Leave request rejected.</div>
    <% } else if ("alreadyreviewed".equals(message)) { %>
        <div class="notice">This request was already reviewed or no longer exists.</div>
    <% } else if ("invalid".equals(message)) { %>
        <div class="notice">Invalid request details.</div>
    <% } %>

    <section class="card">
        <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Employee</th>
                    <th>Leave Type</th>
                    <th>Dates</th>
                    <th>Period</th>
                    <th>Reason</th>
                    <th>Applied At</th>
                    <th>Status / Action</th>
                </tr>
            </thead>
            <tbody>
            <%
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(sql);
                     ResultSet rs = ps.executeQuery()) {

                    boolean found = false;

                    while (rs.next()) {
                        found = true;
                        String status = rs.getString("status");
                        String type = rs.getString("leave_type");
                        String period = rs.getString("half_day_period");
                        int leaveId = rs.getInt("leave_id");
                        String statusClass = status == null ? "" : status.toLowerCase();
            %>
                <tr>
                    <td><%= leaveId %></td>
                    <td>
                        <strong><%= esc(rs.getString("full_name")) %></strong><br>
                        <%= esc(rs.getString("email")) %><br>
                        Employee ID: <%= rs.getInt("employee_id") %>
                    </td>
                    <td><%= "HALF_DAY".equals(type) ? "Half Day" : "Full Day" %></td>
                    <td>
                        <%= rs.getDate("start_date") %><br>
                        to <%= rs.getDate("end_date") %>
                    </td>
                    <td><%= esc(period == null ? "—" : period) %></td>
                    <td><%= esc(rs.getString("reason")) %></td>
                    <td><%= rs.getTimestamp("applied_at") %></td>
                    <td>
                        <span class="status <%= esc(statusClass) %>"><%= esc(status) %></span>

                        <% if ("PENDING".equals(status)) { %>
                            <form action="leaves" method="post"
                                  onsubmit="return confirm('Approve this leave request?');">
                                <input type="hidden" name="action" value="review">
                                <input type="hidden" name="leaveId" value="<%= leaveId %>">
                                <input type="hidden" name="decision" value="APPROVED">
                                <button class="approve" type="submit">Approve</button>
                            </form>

                            <form action="leaves" method="post"
                                  onsubmit="return confirm('Reject this leave request?');">
                                <input type="hidden" name="action" value="review">
                                <input type="hidden" name="leaveId" value="<%= leaveId %>">
                                <input type="hidden" name="decision" value="REJECTED">
                                <button class="reject" type="submit">Reject</button>
                            </form>
                        <% } %>
                    </td>
                </tr>
            <%
                    }

                    if (!found) {
            %>
                <tr><td colspan="8">No leave requests found.</td></tr>
            <%
                    }
                } catch (SQLException e) {
                    application.log("Unable to load leave requests", e);
            %>
                <tr><td colspan="8">Unable to load requests. Check the server log.</td></tr>
            <%
                }
            %>
            </tbody>
        </table>
        </div>
    </section>
</main>
</body>
</html>
