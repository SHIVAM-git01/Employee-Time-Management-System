
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>

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
%>

<%
    if (session.getAttribute("employeeId") == null
            || !"HR".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("index.jsp");
        return;
    }

    List<Map<String, Object>> employees =
            (List<Map<String, Object>>) request.getAttribute("employees");

    String search = (String) request.getAttribute("search");

    if (employees == null) {
        response.sendRedirect("manage-employees");
        return;
    }

    if (search == null) {
        search = "";
    }

    String statusMessage = request.getParameter("status");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ETMS | Manage Employees</title>

    <style>
        * { box-sizing: border-box; }

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

        header h2 { margin: 0; }

        header a {
            color: white;
            text-decoration: none;
            font-weight: bold;
        }

        main { padding: 30px 6%; }

        .card {
            background: white;
            padding: 24px;
            border-radius: 14px;
            margin-bottom: 22px;
            box-shadow: 0 5px 20px #0000000d;
        }

        .actions {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }

        .btn {
            display: inline-block;
            background: #2563eb;
            color: white;
            text-decoration: none;
            padding: 11px 16px;
            border: none;
            border-radius: 7px;
            cursor: pointer;
            font-size: 14px;
        }

        .search-form {
            display: flex;
            gap: 10px;
            margin: 20px 0;
        }

        .search-form input {
            flex: 1;
            min-width: 0;
            padding: 12px;
            border: 1px solid #cbd5e1;
            border-radius: 7px;
            font-size: 15px;
        }

        .table-wrap { overflow-x: auto; }

        table {
            width: 100%;
            min-width: 850px;
            border-collapse: collapse;
        }

        th, td {
            text-align: left;
            padding: 14px 12px;
            border-bottom: 1px solid #e2e8f0;
        }

        th { background: #eff6ff; color: #1d4ed8; }

        .status {
            display: inline-block;
            padding: 6px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
        }

        .active { background: #dcfce7; color: #166534; }
        .inactive { background: #fee2e2; color: #991b1b; }
        .empty { text-align: center; padding: 25px; color: #64748b; }

        .message {
            padding: 12px;
            border-radius: 8px;
            margin: 15px 0;
        }

        .success { background: #dcfce7; color: #166534; }
        .error { background: #fee2e2; color: #991b1b; }

        .status-form { margin: 0; }

        .status-btn {
            padding: 9px 12px;
            border: none;
            border-radius: 7px;
            color: white;
            cursor: pointer;
            font-weight: bold;
        }

        .deactivate-btn { background: #dc2626; }
        .activate-btn { background: #16a34a; }

        footer {
            text-align: center;
            padding: 22px;
            color: #64748b;
        }

        @media (max-width: 600px) {
            header { padding: 18px 5%; }
            main { padding: 22px 4%; }
            .card { padding: 17px; }
            .search-form { flex-direction: column; }
        }
    </style>
</head>

<body>

<header>
    <h2>ETMS | Manage Employees</h2>
    <a href="logout">Logout</a>
</header>

<main>
    <section class="card">
        <h1>Manage Employees</h1>
        <p>Search employees by their name or email address.</p>

        <% if ("activated".equals(statusMessage)) { %>
            <div class="message success">
                Employee account activated successfully!
            </div>
        <% } else if ("deactivated".equals(statusMessage)) { %>
            <div class="message success">
                Employee account deactivated successfully!
            </div>
        <% } else if ("self".equals(statusMessage)) { %>
            <div class="message error">
                You cannot deactivate your own HR account.
            </div>
        <% } else if ("notfound".equals(statusMessage)) { %>
            <div class="message error">Employee not found.</div>
        <% } else if ("invalid".equals(statusMessage)) { %>
            <div class="message error">Invalid employee request.</div>
        <% } %>

        <div class="actions">
            <a class="btn" href="hr-dashboard.jsp">Back to HR Dashboard</a>
            <a class="btn" href="hr-dashboard.jsp#add-employee">Add Employee</a>
        </div>

        <form class="search-form" action="manage-employees" method="get">
            <input
                type="search"
                name="q"
                placeholder="Enter employee name or email..."
                value="<%= esc(search) %>"
                maxlength="150">

            <button class="btn" type="submit">Search</button>
            <a class="btn" href="manage-employees">Clear</a>
        </form>

        <p>Employees found: <strong><%= employees.size() %></strong></p>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Employee ID</th>
                        <th>Full Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Account Status</th>
                        <th>Action</th>
                    </tr>
                </thead>

                <tbody>
                <% for (Map<String, Object> employee : employees) {
                    boolean isActive = Boolean.TRUE.equals(
                            employee.get("active"));

                    int employeeId = (Integer) employee.get("id");
                    int currentEmployeeId =
                            (Integer) session.getAttribute("employeeId");

                    boolean isCurrentUser = employeeId == currentEmployeeId;
                %>
                    <tr>
                        <td><%= employeeId %></td>
                        <td><%= esc(employee.get("name")) %></td>
                        <td><%= esc(employee.get("email")) %></td>
                        <td><%= esc(employee.get("role")) %></td>

                        <td>
                            <% if (isActive) { %>
                                <span class="status active">ACTIVE</span>
                            <% } else { %>
                                <span class="status inactive">INACTIVE</span>
                            <% } %>
                        </td>

                        <td>
                            <% if (isCurrentUser) { %>
                                <span>Current HR account</span>
                            <% } else { %>
                                <form class="status-form"
                                      action="employee-status"
                                      method="post"
                                      onsubmit="return confirm('Are you sure you want to <%= isActive ? "deactivate" : "activate" %> this employee account?');">

                                    <input type="hidden"
                                           name="employeeId"
                                           value="<%= employeeId %>">

                                    <% if (isActive) { %>
                                        <button type="submit"
                                                name="action"
                                                value="deactivate"
                                                class="status-btn deactivate-btn">
                                            Deactivate
                                        </button>
                                    <% } else { %>
                                        <button type="submit"
                                                name="action"
                                                value="activate"
                                                class="status-btn activate-btn">
                                            Activate
                                        </button>
                                    <% } %>
                                </form>
                            <% } %>
                        </td>
                    </tr>
                <% } %>

                <% if (employees.isEmpty()) { %>
                    <tr>
                        <td colspan="6" class="empty">
                            No employees found. Try another search.
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </section>
</main>

<footer>© 2026 ETMS | Employee Time Management System</footer>

</body>
</html>
