<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="com.etms.util.DBConnection" %>

<%
    if (session.getAttribute("employeeId") == null
            || !"EMPLOYEE".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("index.jsp");
        return;
    }

    int employeeId = (Integer) session.getAttribute("employeeId");
    String attendanceMessage = request.getParameter("attendance");

    String todayStatus = "Not checked in";
    String checkIn = "-";
    String checkOut = "-";

    boolean canCheckIn = true;
    boolean canCheckOut = false;

    String sql = "SELECT check_in, check_out FROM time_logs "
               + "WHERE employee_id = ? AND work_date = ?";

    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setInt(1, employeeId);
        ps.setDate(2, java.sql.Date.valueOf(LocalDate.now()));

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                java.sql.Timestamp in = rs.getTimestamp("check_in");
                java.sql.Timestamp checkOutTimestamp = rs.getTimestamp("check_out");

                if (in != null) {
                    checkIn = in.toLocalDateTime().toLocalTime().toString();
                    canCheckIn = false;
                    todayStatus = "Checked in";
                    canCheckOut = (checkOutTimestamp == null);
                }

                if (checkOutTimestamp != null) {
                    checkOut = checkOutTimestamp.toLocalDateTime().toLocalTime().toString();
                    canCheckIn = false;
                    canCheckOut = false;
                    todayStatus = "Checked out";
                }
            }
        }
    } catch (Exception e) {
        application.log("Could not load today's attendance", e);
        todayStatus = "Unable to load attendance";
    }

    int pendingLeaveCount = 0;
    int approvedLeaveCount = 0;
    int rejectedLeaveCount = 0;
    int totalLeaveCount = 0;

    String leaveCountSql = "SELECT status, COUNT(*) AS total "
                         + "FROM leave_requests WHERE employee_id = ? "
                         + "GROUP BY status";
    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(leaveCountSql)) {
        ps.setInt(1, employeeId);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String status = rs.getString("status");
                int count = rs.getInt("total");
                totalLeaveCount += count;
                if ("PENDING".equalsIgnoreCase(status)) {
                    pendingLeaveCount = count;
                } else if ("APPROVED".equalsIgnoreCase(status)) {
                    approvedLeaveCount = count;
                } else if ("REJECTED".equalsIgnoreCase(status)) {
                    rejectedLeaveCount = count;
                }
            }
        }
    } catch (Exception e) {
        application.log("Could not load employee leave summary", e);
    }

    String leaveSql = "SELECT leave_id, start_date, end_date, reason, status, "
                    + "leave_type, half_day_period, applied_at "
                    + "FROM leave_requests WHERE employee_id = ? "
                    + "ORDER BY applied_at DESC";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ETMS | Employee Dashboard</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; font-family: Arial, sans-serif; background: #f1f5f9; color: #0f172a; }
        header { background: #1d4ed8; color: white; padding: 22px 7%; display: flex; justify-content: space-between; align-items: center; gap: 15px; }
        header a { color: white; text-decoration: none; font-weight: bold; }
        main { padding: 35px 7%; }
        .card { background: white; padding: 25px; border-radius: 14px; margin-bottom: 24px; box-shadow: 0 5px 20px #0000000d; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 20px; }
        .value { color: #2563eb; font-size: 24px; font-weight: bold; overflow-wrap: anywhere; }
        button, .button-link { display: inline-block; padding: 13px 22px; border: none; border-radius: 8px; color: white; font-weight: bold; cursor: pointer; margin: 8px 8px 8px 0; text-decoration: none; font-size: 14px; }
        .checkin { background: #16a34a; }
        .checkout { background: #dc2626; }
        .leave-button { background: #2563eb; }
        button:disabled { background: #94a3b8; cursor: not-allowed; }
        .notice { padding: 12px; border-radius: 8px; background: #eff6ff; margin-bottom: 20px; }
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; min-width: 680px; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #e2e8f0; }
        th { background: #eff6ff; }
        .status { display: inline-block; padding: 5px 9px; border-radius: 20px; font-size: 12px; font-weight: bold; }
        .pending { background: #fef3c7; color: #92400e; }
        .approved { background: #dcfce7; color: #166534; }
        .rejected { background: #fee2e2; color: #991b1b; }
        .empty { color: #64748b; padding: 18px 0; }
        footer { text-align: center; padding: 20px; color: #64748b; }
        @media (max-width: 600px) {
            header { padding: 18px 5%; flex-wrap: wrap; }
            main { padding: 22px 5%; }
            .card { padding: 18px; }
        }
    </style>
</head>
<body>
<header>
    <h2>ETMS | Employee Dashboard</h2>
    <a href="logout">Logout</a>
</header>

<main>
    <div class="card">
        <h1>Welcome, <%= session.getAttribute("fullName") %>!</h1>
        <p>Employee Time Management System</p>
    </div>

    <% if ("checkedin".equals(attendanceMessage)) { %>
        <div class="notice">Check-in successful!</div>
    <% } else if ("checkedout".equals(attendanceMessage)) { %>
        <div class="notice">Check-out successful! Your workday is completed.</div>
    <% } else if ("already".equals(attendanceMessage)) { %>
        <div class="notice">A record already exists for today.</div>
    <% } else if ("noactive".equals(attendanceMessage)) { %>
        <div class="notice">No active check-in was found for today.</div>
    <% } %>

    <div class="stats">
        <div class="card">
            <h3>Today's Attendance</h3>
            <div class="value"><%= todayStatus %></div>
        </div>
        <div class="card">
            <h3>Check-in Time</h3>
            <div class="value"><%= checkIn %></div>
        </div>
        <div class="card">
            <h3>Check-out Time</h3>
            <div class="value"><%= checkOut %></div>
        </div>
    </div>

    <div class="card">
        <h2>Attendance Management</h2>
        <p>Record your check-in when you start work and check-out when you finish.</p>

        <form action="attendance" method="post" style="display:inline">
            <input type="hidden" name="action" value="checkin">
            <button class="checkin" type="submit" <%= canCheckIn ? "" : "disabled" %>>Check In</button>
        </form>

        <form action="attendance" method="post" style="display:inline">
            <input type="hidden" name="action" value="checkout">
            <button class="checkout" type="submit" <%= canCheckOut ? "" : "disabled" %>>Check Out</button>
        </form>
    </div>

    <div class="card">
        <h2>Leave Management</h2>
        <p>Apply for a new leave or review the status of your previous requests below.</p>
        <a class="button-link leave-button" href="leaves">Apply for Leave</a>
        <a class="button-link" href="schedules"
           style="background:#0f766e;">
            My Work Schedule
        </a>

        <div class="stats">
            <div>
                <h3>Total Requests</h3>
                <div class="value"><%= totalLeaveCount %></div>
            </div>
            <div>
                <h3>Pending</h3>
                <div class="value" style="color:#b45309"><%= pendingLeaveCount %></div>
            </div>
            <div>
                <h3>Approved</h3>
                <div class="value" style="color:#15803d"><%= approvedLeaveCount %></div>
            </div>
            <div>
                <h3>Rejected</h3>
                <div class="value" style="color:#b91c1c"><%= rejectedLeaveCount %></div>
            </div>
        </div>
    </div>

    <div class="card">
        <h2>My Leave History</h2>
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Type</th>
                        <th>Dates</th>
                        <th>Period</th>
                        <th>Reason</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    try (Connection con = DBConnection.getConnection();
                         PreparedStatement ps = con.prepareStatement(leaveSql)) {
                        ps.setInt(1, employeeId);
                        try (ResultSet rs = ps.executeQuery()) {
                            boolean found = false;
                            while (rs.next()) {
                                found = true;
                                String type = rs.getString("leave_type");
                                String period = rs.getString("half_day_period");
                                String status = rs.getString("status");
                                String statusClass = status == null ? "" : status.toLowerCase();
                %>
                    <tr>
                        <td><%= rs.getInt("leave_id") %></td>
                        <td><%= "HALF_DAY".equals(type) ? "Half Day" : "Full Day" %></td>
                        <td><%= rs.getDate("start_date") %> to <%= rs.getDate("end_date") %></td>
                        <td><%= period == null ? "—" : period %></td>
                        <td><%= rs.getString("reason") == null ? "" : rs.getString("reason") %></td>
                        <td><span class="status <%= statusClass %>"><%= status == null ? "" : status %></span></td>
                    </tr>
                <%
                            }
                            if (!found) {
                %>
                    <tr><td colspan="6" class="empty">No leave requests yet. Click “Apply for Leave” to submit one.</td></tr>
                <%
                            }
                        }
                    } catch (Exception e) {
                        application.log("Unable to load employee leave history", e);
                %>
                    <tr><td colspan="6" class="empty">Unable to load leave history right now.</td></tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>
    </div>
</main>

<footer>© 2026 ETMS | Employee Time Management System</footer>
</body>
</html>
