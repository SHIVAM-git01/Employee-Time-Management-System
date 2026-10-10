<%@ page import="java.util.List,java.util.Map" %>
<%@ page import="java.sql.Timestamp" %>

<%
    if (session.getAttribute("employeeId") == null
            || !"HR".equals(session.getAttribute("userRole"))) {
        response.sendError(403, "HR access required.");
        return;
    }

    List<Map<String, Object>> rows =
        (List<Map<String, Object>>) request.getAttribute("attendanceRows");

    String result = request.getParameter("result");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>HR Attendance Correction | ETMS</title>

<style>
body {
    font-family: Arial, sans-serif;
    background: #f1f5f9;
    color: #172033;
    margin: 0;
}
header {
    background: #173b78;
    color: white;
    padding: 20px 5%;
    display: flex;
    justify-content: space-between;
    gap: 12px;
    flex-wrap: wrap;
}
header a {
    color: white;
}
main {
    max-width: 1200px;
    margin: 30px auto;
    padding: 0 18px;
}
.card {
    background: white;
    padding: 22px;
    border-radius: 12px;
    box-shadow: 0 3px 15px #0001;
}
.table-wrap {
    overflow-x: auto;
}
table {
    width: 100%;
    border-collapse: collapse;
    min-width: 850px;
}
th, td {
    text-align: left;
    padding: 12px;
    border-bottom: 1px solid #ddd;
}
th {
    background: #eff6ff;
    color: #1d4ed8;
}
input, select, button {
    padding: 9px;
    margin: 4px 0;
    box-sizing: border-box;
}
input, select {
    max-width: 180px;
    width: 100%;
}
button {
    background: #1d4ed8;
    color: white;
    border: 0;
    border-radius: 6px;
    cursor: pointer;
}
button:hover {
    background: #1e40af;
}
.notice {
    padding: 12px;
    margin-bottom: 15px;
    border-radius: 8px;
    background: #e0f2fe;
}
.error {
    background: #fee2e2;
    color: #991b1b;
}
.success {
    background: #dcfce7;
    color: #166534;
}
small {
    color: #64748b;
}
</style>
</head>

<body>

<header>
    <strong>ETMS | HR Attendance Correction</strong>
    <a href="hr-dashboard.jsp">Back to HR Dashboard</a>
</header>

<main>
<section class="card">

    <h1>Correct Attendance</h1>
    <p>Choose a corrected status and provide a reason. Active check-ins cannot be edited.</p>

    <% if ("success".equals(result)) { %>
        <div class="notice success">
            Attendance corrected and history saved successfully.
        </div>
    <% } else if ("invalid".equals(result)) { %>
        <div class="notice error">
            Invalid input. Please check the status, ID and reason.
        </div>
    <% } else if ("notfound".equals(result)) { %>
        <div class="notice error">
            Attendance record not found.
        </div>
    <% } else if ("active".equals(result)) { %>
        <div class="notice error">
            This employee has an active check-in. Correct it after checkout.
        </div>
    <% } %>

    <div class="table-wrap">
    <table>
        <thead>
        <tr>
            <th>Log ID</th>
            <th>Employee</th>
            <th>Date</th>
            <th>Check-in</th>
            <th>Check-out</th>
            <th>Current Status</th>
            <th>Correction</th>
        </tr>
        </thead>

        <tbody>
        <% if (rows != null && !rows.isEmpty()) {
            for (Map<String, Object> row : rows) {
                Timestamp in = (Timestamp) row.get("checkIn");
                Timestamp checkOutTime =
                    (Timestamp) row.get("checkOut");
        %>

        <tr>
            <td><%= row.get("logId") %></td>
            <td><%= row.get("name") %></td>
            <td><%= row.get("date") %></td>

            <td>
                <%= in == null ? "-" :
                    in.toLocalDateTime().toLocalTime() %>
            </td>

            <td>
                <%= checkOutTime == null ? "-" :
                    checkOutTime.toLocalDateTime().toLocalTime() %>
            </td>

            <td>
                <%= row.get("status") == null ? "-" :
                    row.get("status") %>
            </td>

            <td>
                <% if (checkOutTime != null) { %>

                <form method="post" action="attendance-correction">

                    <input type="hidden"
                           name="logId"
                           value="<%= row.get("logId") %>">

                    <select name="status" required>
                        <option value="FULL_DAY">FULL_DAY</option>
                        <option value="HALF_DAY">HALF_DAY</option>
                        <option value="ABSENT">ABSENT</option>
                    </select>

                    <input type="text"
                           name="reason"
                           maxlength="255"
                           placeholder="Reason for correction"
                           required>

                    <button type="submit">Save</button>

                </form>

                <% } else { %>
                    <small>Checkout required first</small>
                <% } %>
            </td>
        </tr>

        <% }
        } else { %>

        <tr>
            <td colspan="7">No attendance records found.</td>
        </tr>

        <% } %>
        </tbody>
    </table>
    </div>

</section>
</main>

</body>
</html>