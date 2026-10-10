<%@ page import="java.sql.*" %>
<%@ page import="com.etms.util.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    Integer employeeId = (Integer) session.getAttribute("employeeId");
    String role = (String) session.getAttribute("userRole");

    if (employeeId == null || !"EMPLOYEE".equals(role)) {
        response.sendRedirect("index.jsp");
        return;
    }

    String message = request.getParameter("message");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Apply for Leave | ETMS</title>
<style>
*{box-sizing:border-box}
body{margin:0;font-family:Arial,sans-serif;background:#f3f6fb;color:#1e293b}
header{background:#172554;color:white;padding:20px 7%;display:flex;justify-content:space-between;align-items:center;gap:12px}
header a{color:white;text-decoration:none;font-weight:bold}
main{max-width:900px;margin:30px auto;padding:0 18px}
.card{background:white;padding:24px;border-radius:12px;margin-bottom:24px;box-shadow:0 3px 14px #0000000d}
h2{margin-top:0;color:#172554}
.form-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}
label{display:block;font-weight:bold;margin-bottom:7px}
input,select,textarea{width:100%;padding:11px;border:1px solid #cbd5e1;border-radius:7px;font:inherit}
textarea{resize:vertical}
button{padding:11px 18px;background:#1d4ed8;color:white;border:0;border-radius:7px;cursor:pointer;font-weight:bold}
button:hover{background:#1e40af}
.notice{padding:12px;border-radius:7px;margin-bottom:18px;background:#dbeafe}
@media(max-width:600px){.form-grid{grid-template-columns:1fr}header{padding:18px;flex-wrap:wrap}.card{padding:18px}}
</style>
</head>
<body>
<header>
    <strong>ETMS | Apply for Leave</strong>
    <a href="employee-dashboard.jsp">← Employee Dashboard</a>
</header>

<main>
    <section class="card">
        <h2>Apply for Leave</h2>

        <% if ("applied".equals(message)) { %>
            <div class="notice">Leave request submitted successfully. You can check its status on your dashboard.</div>
        <% } else if ("invalid".equals(message)
                   || "invaliddates".equals(message)
                   || "invalidhalfday".equals(message)) { %>
            <div class="notice">Invalid details. Please check your dates and leave type.</div>
        <% } else if ("error".equals(message)) { %>
            <div class="notice">Could not submit your leave request. Please try again.</div>
        <% } %>

        <form action="leaves" method="post">
            <input type="hidden" name="action" value="apply">

            <div class="form-grid">
                <div>
                    <label for="leaveType">Leave Type</label>
                    <select id="leaveType" name="leaveType" required>
                        <option value="FULL_DAY">Full Day</option>
                        <option value="HALF_DAY">Half Day</option>
                    </select>
                </div>

                <div id="periodBox" style="display:none">
                    <label for="halfDayPeriod">Half-Day Period</label>
                    <select id="halfDayPeriod" name="halfDayPeriod">
                        <option value="MORNING">Morning</option>
                        <option value="AFTERNOON">Afternoon</option>
                    </select>
                </div>

                <div>
                    <label for="startDate">Start Date</label>
                    <input type="date" id="startDate" name="startDate" required>
                </div>

                <div>
                    <label for="endDate">End Date</label>
                    <input type="date" id="endDate" name="endDate" required>
                </div>

                <div style="grid-column:1/-1">
                    <label for="reason">Reason</label>
                    <textarea id="reason" name="reason" maxlength="255" rows="3" required></textarea>
                </div>
            </div>

            <p><button type="submit">Submit Leave Request</button></p>
        </form>
    </section>
</main>

<script>
const typeSelect = document.getElementById("leaveType");
const periodBox = document.getElementById("periodBox");
const periodSelect = document.getElementById("halfDayPeriod");
const startDate = document.getElementById("startDate");
const endDate = document.getElementById("endDate");

const today = new Date();
const localToday = [
    today.getFullYear(),
    String(today.getMonth() + 1).padStart(2, "0"),
    String(today.getDate()).padStart(2, "0")
].join("-");

startDate.min = localToday;
endDate.min = localToday;

startDate.addEventListener("change", () => {
    endDate.min = startDate.value || localToday;
    if (endDate.value && endDate.value < startDate.value) {
        endDate.value = startDate.value;
    }
    if (typeSelect.value === "HALF_DAY") {
        endDate.value = startDate.value;
    }
});

typeSelect.addEventListener("change", () => {
    const halfDay = typeSelect.value === "HALF_DAY";
    periodBox.style.display = halfDay ? "block" : "none";
    periodSelect.required = halfDay;
    endDate.required = true;
    if (halfDay && startDate.value) {
        endDate.value = startDate.value;
    }
});

endDate.addEventListener("change", () => {
    if (typeSelect.value === "HALF_DAY") {
        endDate.value = startDate.value;
    }
});
</script>
</body>
</html>
