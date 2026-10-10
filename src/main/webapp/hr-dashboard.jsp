<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="java.sql.Connection" %>

<%@ page import="java.sql.PreparedStatement" %>

<%@ page import="java.sql.ResultSet" %>

<%@ page import="java.sql.Timestamp" %>

<%@ page import="java.sql.SQLException" %>

<%@ page import="java.time.Duration" %>

<%@ page import="java.time.LocalDate" %>

<%@ page import="java.time.LocalDateTime" %>

<%@ page import="java.time.format.DateTimeFormatter" %>

<%@ page import="java.util.ArrayList" %>

<%@ page import="java.util.HashMap" %>

<%@ page import="java.util.List" %>

<%@ page import="java.util.Map" %>

<%@ page import="com.etms.util.DBConnection" %>



<%!

    private String esc(Object value) {

        if (value == null) return "";



        return value.toString()

                .replace("&", "&amp;")

                .replace("<", "&lt;")

                .replace(">", "&gt;")

                .replace("\"", "&quot;")

                .replace("'", "&#39;");

    }



    private String formatHours(Timestamp in, Timestamp out) {

        if (in == null) return "-";



        LocalDateTime start = in.toLocalDateTime();

        LocalDateTime end = out == null

                ? LocalDateTime.now()

                : out.toLocalDateTime();



        long minutes = Math.max(

                0, Duration.between(start, end).toMinutes());



        return (minutes / 60) + "h " + (minutes % 60) + "m";

    }



    private String formatTime(Timestamp timestamp) {

        if (timestamp == null) return "-";



        return timestamp.toLocalDateTime()

                .toLocalTime()

                .format(DateTimeFormatter.ofPattern("hh:mm a"));

    }

%>



<%

    if (session.getAttribute("employeeId") == null

            || !"HR".equals(session.getAttribute("userRole"))) {

        response.sendRedirect("index.jsp");

        return;

    }



    int pendingLeaveCount = 0;
    try (Connection leaveCon = DBConnection.getConnection();
         PreparedStatement leavePs = leaveCon.prepareStatement(
                 "SELECT COUNT(*) FROM leave_requests WHERE status = 'PENDING'");
         ResultSet leaveRs = leavePs.executeQuery()) {
        if (leaveRs.next()) pendingLeaveCount = leaveRs.getInt(1);
    } catch (SQLException e) {
        application.log("Unable to count pending leave requests", e);
    }

    String fullName = (String) session.getAttribute("fullName");

    int currentEmployeeId = (Integer) session.getAttribute("employeeId");

    LocalDate today = LocalDate.now();



    int totalEmployees = 0;

    int fullDays = 0;

    int halfDays = 0;

    int absentDays = 0;

    int inProgress = 0;

    int deactivatedEmployees = 0;

    double attendanceTotal = 0.0;



    List<Map<String, Object>> rows = new ArrayList<>();



    String sql =

        "SELECT e.employee_id, e.full_name, e.email, e.role, e.is_active, " +

        "t.work_date, t.check_in, t.check_out, " +

        "t.attendance_status, t.attendance_count " +

        "FROM employees e " +

        "LEFT JOIN time_logs t " +

        "ON e.employee_id = t.employee_id AND t.work_date = ? " +

        "ORDER BY e.employee_id";



    try (Connection con = DBConnection.getConnection();

         PreparedStatement ps = con.prepareStatement(sql)) {



        ps.setDate(1, java.sql.Date.valueOf(today));



        try (ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {

                Map<String, Object> row = new HashMap<>();



                int id = rs.getInt("employee_id");

                String role = rs.getString("role");

                boolean active = rs.getBoolean("is_active");



                row.put("id", id);

                row.put("name", rs.getString("full_name"));

                row.put("email", rs.getString("email"));

                row.put("role", role);

                row.put("active", active);



                if (!active) {

                    deactivatedEmployees++;

                }



                Timestamp checkIn = rs.getTimestamp("check_in");

                Timestamp checkOut = rs.getTimestamp("check_out");

                String dbStatus = rs.getString("attendance_status");



                double count = rs.getDouble("attendance_count");

                boolean hasRecord = rs.getDate("work_date") != null;

                boolean ongoing = checkIn != null && checkOut == null;



                String displayStatus;

                double displayCount = count;



                if (!hasRecord || checkIn == null) {

                    if ("HR".equals(role)) {

                        displayStatus = "NOT MARKED";

                    } else {

                        displayStatus = "ABSENT";

                        absentDays++;

                    }



                    displayCount = 0.0;



                } else if (ongoing) {

                    displayStatus = "IN PROGRESS";

                    displayCount = 0.0;

                    inProgress++;



                } else {

                    displayStatus = dbStatus == null

                            ? "ABSENT" : dbStatus;



                    if ("FULL_DAY".equals(displayStatus)) {

                        fullDays++;

                    } else if ("HALF_DAY".equals(displayStatus)) {

                        halfDays++;

                    } else if (!"ON_LEAVE".equals(displayStatus)) {

                        absentDays++;

                    }

                }



                if (hasRecord && checkIn != null && !ongoing) {

                    attendanceTotal += displayCount;

                }



                row.put("checkIn", checkIn);

                row.put("checkOut", checkOut);

                row.put("status", displayStatus);

                row.put("count", displayCount);

                row.put("hours", formatHours(checkIn, checkOut));



                rows.add(row);

                totalEmployees++;

            }

        }



    } catch (SQLException e) {

        application.log("Unable to load HR dashboard", e);

        response.sendError(

                jakarta.servlet.http.HttpServletResponse.SC_INTERNAL_SERVER_ERROR,

                "Unable to load dashboard data. Check server logs.");

        return;

    }



    String employeeMessage = request.getParameter("employee");

    String attendanceMessage = request.getParameter("attendance");

%>



<!DOCTYPE html>

<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta name="viewport" content="width=device-width, initial-scale=1.0">



    <title>ETMS | HR Dashboard</title>



    <style>

        \* {

            box-sizing: border-box;

        }



        body {

            margin: 0;

            font-family: Arial, sans-serif;

            background: #f1f5f9;

            color: #0f172a;

        }



        header {

            background: #1d4ed8;

            color: white;

            padding: 22px 6%;

            display: flex;

            justify-content: space-between;

            align-items: center;

            gap: 15px;

        }



        header h2 {

            margin: 0;

        }



        header a {

            color: white;

            text-decoration: none;

            font-weight: bold;

        }



        main {

            padding: 30px 6%;

        }



        .card {

            background: white;

            padding: 24px;

            border-radius: 14px;

            margin-bottom: 22px;

            box-shadow: 0 5px 20px #0000000d;

        }



        .stats {

            display: grid;

            grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));

            gap: 18px;

        }



        .stats .card {

            margin: 0;

        }



        .stats h3 {

            margin-top: 0;

            font-size: 16px;

        }



        .value {

            font-size: 30px;

            font-weight: bold;

            color: #2563eb;

        }



        .table-wrap {

            overflow-x: auto;

        }



        table {

            width: 100%;

            min-width: 1150px;

            border-collapse: collapse;

            margin-top: 20px;

        }



        th, td {

            text-align: left;

            padding: 14px 12px;

            border-bottom: 1px solid #e2e8f0;

            white-space: nowrap;

        }



        th {

            background: #eff6ff;

            color: #1d4ed8;

        }



        .badge {

            display: inline-block;

            padding: 6px 10px;

            border-radius: 20px;

            font-size: 12px;

            font-weight: bold;

        }



        .full, .active-badge {

            background: #dcfce7;

            color: #166534;

        }



        .half {

            background: #fef3c7;

            color: #92400e;

        }



        .absent, .deactivated-badge {

            background: #fee2e2;

            color: #991b1b;

        }



        .progress {

            background: #dbeafe;

            color: #1d4ed8;

        }



        .leave {

            background: #f3e8ff;

            color: #6b21a8;

        }



        .not-marked {

            background: #e2e8f0;

            color: #334155;

        }



        .refresh, .submit-btn {

            display: inline-block;

            margin-top: 10px;

            background: #2563eb;

            color: white;

            padding: 11px 16px;

            border: none;

            border-radius: 8px;

            text-decoration: none;

            font-weight: bold;

            cursor: pointer;

            font-size: 14px;

        }



        .checkout-btn {

            background: #15803d;

        }



        .refresh:hover, .submit-btn:hover {

            opacity: 0.9;

        }



        .form-grid {

            display: grid;

            grid-template-columns: 1fr 1fr;

            gap: 18px;

        }



        .field label {

            display: block;

            margin-bottom: 8px;

            font-weight: bold;

        }



        .field input, .field select {

            width: 100%;

            padding: 12px;

            border: 1px solid #cbd5e1;

            border-radius: 7px;

            font-size: 15px;

        }



        .message {

            padding: 12px;

            border-radius: 8px;

            margin: 12px 0;

        }



        .success {

            background: #dcfce7;

            color: #166534;

        }



        .error {

            background: #fee2e2;

            color: #991b1b;

        }



        .attendance-panel {

            margin-top: 20px;

            padding: 20px;

            background: #eff6ff;

            border: 1px solid #bfdbfe;

            border-radius: 12px;

        }



        footer {

            text-align: center;

            padding: 22px;

            color: #64748b;

        }



        @media (max-width: 600px) {

            header {

                padding: 18px 5%;

            }



            main {

                padding: 22px 4%;

            }



            .card {

                padding: 17px;

            }



            .form-grid {

                grid-template-columns: 1fr;

            }

        }

    
        /* ETMS visual polish: consistent cards, actions, tables and responsive layout */
        body {
            background: linear-gradient(135deg, #f8fafc 0%, #eef2ff 100%);
            color: #0f172a;
        }
        header {
            background: linear-gradient(120deg, #172554 0%, #1d4ed8 60%, #4f46e5 100%);
            box-shadow: 0 8px 24px rgba(30, 64, 175, .18);
        }
        main { max-width: 1500px; margin: 0 auto; }
        .card {
            border: 1px solid #e2e8f0;
            box-shadow: 0 8px 24px rgba(15, 23, 42, .055);
            transition: box-shadow .18s ease, transform .18s ease;
        }
        .stats .card:hover { transform: translateY(-2px); box-shadow: 0 12px 28px rgba(15, 23, 42, .09); }
        .refresh, .submit-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 7px;
            border-radius: 9px;
            padding: 11px 15px;
            font-weight: 700;
            border: 1px solid transparent;
            text-decoration: none;
            transition: transform .15s ease, filter .15s ease;
        }
        .refresh {
            background: #eef2ff;
            color: #3730a3;
            border-color: #c7d2fe;
            margin: 6px 8px 6px 0 !important;
        }
        .refresh:hover, .submit-btn:hover { filter: brightness(.97); transform: translateY(-1px); }
        .submit-btn { background: #2563eb; color: #fff; }
        .checkout-btn { background: #dc2626; }
        table { border-radius: 12px; overflow: hidden; }
        tbody tr:hover { background: #f8fafc; }
        th { letter-spacing: .02em; }
        input, select { border: 1px solid #cbd5e1; border-radius: 8px; padding: 10px 12px; }
        .attendance-panel {
            background: linear-gradient(135deg, #f8fafc, #eff6ff);
            border: 1px solid #dbeafe;
            border-radius: 12px;
            padding: 20px;
            margin-top: 24px;
        }
        @media (max-width: 700px) {
            header { padding: 18px 5%; }
            main { padding: 20px 5%; }
            .card { padding: 18px; }
            .refresh, .submit-btn { width: 100%; margin: 6px 0 !important; }
            .stats { grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); }
        }

    </style>

</head>



<body>



<header>

    <h2>ETMS | HR Dashboard</h2>

    <a href="logout">Logout</a>

</header>



<main>



    <section class="card">

        <h1>Welcome, <%= esc(fullName) %>!</h1>

        <p>Employee Time Management System — HR Control Panel</p>

        <p>Attendance date: <strong><%= today %></strong></p>



        <a class="refresh" href="hr-dashboard.jsp">Refresh Dashboard</a>



        <a class="refresh" href="manage-employees" style="margin-left:10px;">

            Manage Employees &amp; Search

        </a>

        <a class="refresh" href="schedules" style="margin-left:10px;">
            Manage Schedules
        </a>

        <a class="refresh" href="manage-leaves.jsp" style="margin-left:10px;">
            Manage Leave Requests
        </a>

        <a class="refresh" href="attendance-correction" style="margin-left:10px;">
            Correct Attendance
        </a>
        <span class="refresh" style="cursor:default;">
            Pending Leaves
            <strong style="display:inline-block; margin-left:7px; min-width:26px;
                           padding:4px 8px; border-radius:20px;
                           background:#dc2626; color:#fff; text-align:center;">
                <%= pendingLeaveCount %>
            </strong>
        </span>
        <a class="refresh" href="reports.jsp" style="margin-left:10px;">
            Attendance &amp; Leave Reports
        </a>

        <div class="attendance-panel">

            <h2>My Attendance</h2>

            <p>Mark your own attendance for today.</p>






            <% if ("checkedin".equals(attendanceMessage)) { %>

                <div class="message success">Check-in successful!</div>

            <% } else if ("checkedout".equals(attendanceMessage)) { %>

                <div class="message success">Check-out successful!</div>

            <% } else if ("already".equals(attendanceMessage)) { %>

                <div class="message error">Today's attendance has already been started or marked.</div>

            <% } else if ("noactive".equals(attendanceMessage)) { %>

                <div class="message error">No active check-in found. Please check in first.</div>

            <% } else if ("invalidtime".equals(attendanceMessage)) { %>

                <div class="message error">Invalid check-out time.</div>

            <% } %>



            <form action="attendance" method="post" style="display:inline-block; margin-right:10px;">

                <button class="submit-btn" type="submit" name="action" value="checkin">

                    Check In

                </button>

            </form>



            <form action="attendance" method="post" style="display:inline-block;">

                <button class="submit-btn checkout-btn" type="submit" name="action" value="checkout">

                    Check Out

                </button>

            </form>

        </div>

    </section>



    <section class="stats">



        <div class="card">

            <h3>Total Accounts</h3>

            <div class="value"><%= totalEmployees %></div>

        </div>



        <div class="card">

            <h3>Full Days</h3>

            <div class="value"><%= fullDays %></div>

        </div>



        <div class="card">

            <h3>Half Days</h3>

            <div class="value"><%= halfDays %></div>

        </div>



        <div class="card">

            <h3>Absent Employees</h3>

            <div class="value"><%= absentDays %></div>

        </div>



        <div class="card">

            <h3>In Progress</h3>

            <div class="value"><%= inProgress %></div>

        </div>



        <div class="card">

            <h3>Deactivated Accounts</h3>

            <div class="value"><%= deactivatedEmployees %></div>

        </div>



        <div class="card">

            <h3>Attendance Count</h3>

            <div class="value"><%= String.format("%.1f", attendanceTotal) %></div>

        </div>



    </section>



    <section class="card" style="margin-top:22px">

        <h2>Today's Employee Attendance</h2>

        <p>Attendance and working duration are loaded from MySQL.</p>



        <div class="table-wrap">

            <table>

                <thead>

                    <tr>

                        <th>ID</th>

                        <th>Employee Name</th>

                        <th>Email</th>

                        <th>Role</th>

                        <th>Account Status</th>

                        <th>Check-in</th>

                        <th>Check-out</th>

                        <th>Working Hours</th>

                        <th>Attendance Status</th>

                        <th>Count</th>

                    </tr>

                </thead>



                <tbody>

                <% for (Map<String, Object> row : rows) {

                    String status = (String) row.get("status");

                    String badgeClass = "absent";



                    if ("FULL_DAY".equals(status)) {

                        badgeClass = "full";

                    } else if ("HALF_DAY".equals(status)) {

                        badgeClass = "half";

                    } else if ("IN PROGRESS".equals(status)) {

                        badgeClass = "progress";

                    } else if ("ON_LEAVE".equals(status)) {

                        badgeClass = "leave";

                    } else if ("NOT MARKED".equals(status)) {

                        badgeClass = "not-marked";

                    }



                    boolean active = Boolean.TRUE.equals(row.get("active"));

                %>

                    <tr>

                        <td><%= row.get("id") %></td>

                        <td><%= esc(row.get("name")) %></td>

                        <td><%= esc(row.get("email")) %></td>

                        <td><%= esc(row.get("role")) %></td>



                        <td>

                            <% if (active) { %>

                                <span class="badge active-badge">ACTIVE</span>

                            <% } else { %>

                                <span class="badge deactivated-badge">DEACTIVATED</span>

                            <% } %>

                        </td>



                        <td><%= formatTime((Timestamp) row.get("checkIn")) %></td>

                        <td><%= formatTime((Timestamp) row.get("checkOut")) %></td>

                        <td><%= esc(row.get("hours")) %></td>



                        <td>

                            <span class="badge <%= badgeClass %>">

                                <%= esc(status) %>

                            </span>

                        </td>



                        <td>

                            <strong><%= String.format("%.1f", (Double) row.get("count")) %></strong>

                        </td>

                    </tr>

                <% } %>



                <% if (rows.isEmpty()) { %>

                    <tr>

                        <td colspan="10">No employee records found.</td>

                    </tr>

                <% } %>

                </tbody>

            </table>

        </div>

    </section>



    <section class="card" id="add-employee">

        <h2>Add New Employee</h2>

        <p>Create an employee or HR account.</p>



        <% if ("added".equals(employeeMessage)) { %>

            <div class="message success">Employee added successfully!</div>

        <% } else if ("duplicate".equals(employeeMessage)) { %>

            <div class="message error">This email is already registered.</div>

        <% } else if ("weakpassword".equals(employeeMessage)) { %>

            <div class="message error">Password must contain at least 8 characters.</div>

        <% } else if ("invalidemail".equals(employeeMessage)) { %>

            <div class="message error">Please enter a valid email address.</div>

        <% } else if ("invalid".equals(employeeMessage)) { %>

            <div class="message error">Please fill all fields and select a valid role.</div>

        <% } else if ("setuprequired".equals(employeeMessage)) { %>

            <div class="message error">Employee setup is incomplete.</div>

        <% } %>



        <form action="employees" method="post">

            <div class="form-grid">



                <div class="field">

                    <label for="fullName">Full Name</label>

                    <input id="fullName" type="text" name="fullName"

                           maxlength="100" required>

                </div>



                <div class="field">

                    <label for="email">Email Address</label>

                    <input id="email" type="email" name="email"

                           maxlength="150" required>

                </div>



                <div class="field">

                    <label for="password">Temporary Password</label>

                    <input id="password" type="password" name="password"

                           minlength="8" required autocomplete="new-password">

                </div>



                <div class="field">

                    <label for="role">Account Role</label>

                    <select id="role" name="role" required>

                        <option value="EMPLOYEE">Employee</option>

                        <option value="HR">HR</option>

                    </select>

                </div>



            </div>



            <button class="submit-btn" type="submit">Add Employee</button>

        </form>

    </section>



</main>



<footer>© 2026 ETMS | Employee Time Management System</footer>



</body>

</html>
