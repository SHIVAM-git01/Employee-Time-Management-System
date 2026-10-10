<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ETMS | Login</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #e0eaff, #f1f5f9);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
        }

        .login-card {
            width: 100%;
            max-width: 420px;
            background: white;
            padding: 35px;
            border-radius: 18px;
            box-shadow: 0 12px 35px #1e293b20;
        }

        .logo {
            text-align: center;
            color: #2563eb;
            font-size: 36px;
            font-weight: bold;
            margin-bottom: 8px;
        }

        h2 {
            text-align: center;
            margin-bottom: 8px;
            color: #0f172a;
        }

        .subtitle {
            text-align: center;
            color: #64748b;
            margin-bottom: 28px;
        }

        label {
            display: block;
            margin: 15px 0 7px;
            font-weight: bold;
            color: #334155;
        }

        input, select {
            width: 100%;
            padding: 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 15px;
        }

        input:focus, select:focus {
            outline: none;
            border-color: #2563eb;
        }

        button {
            width: 100%;
            padding: 13px;
            margin-top: 24px;
            background: #2563eb;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
        }

        button:hover {
            background: #1d4ed8;
        }

        .footer {
            text-align: center;
            color: #64748b;
            font-size: 12px;
            margin-top: 24px;
        }
    </style>
</head>

<body>
    <div class="login-card">
        <div class="logo">ETMS</div>

        <h2>Welcome Back</h2>
        <p class="subtitle">Employee Time Management System</p>
        
<%
    String error = request.getParameter("error");
    String logout = request.getParameter("logout");

    if ("invalid".equals(error)) {
%>
    <p style="color:#dc2626;text-align:center;">
        Invalid email, password or role.
    </p>
<%
    } else if ("missing".equals(error)) {
%>
    <p style="color:#dc2626;text-align:center;">
        Please fill in all fields.
    </p>
<%
    } else if ("success".equals(logout)) {
%>
    <p style="color:#16a34a;text-align:center;">
        You have logged out successfully.
    </p>
<%
    }
%>


        <form action="login" method="post">
            <label for="email">Email Address</label>
            <input type="email" id="email" name="email"
                   placeholder="Enter your email" required>

            <label for="password">Password</label>
            <input type="password" id="password" name="password"
                   placeholder="Enter your password" required>

            <label for="role">Login As</label>
            <select id="role" name="role" required>
                <option value="">Select your role</option>
                <option value="HR">HR Manager</option>
                <option value="EMPLOYEE">Employee</option>
            </select>

            <button type="submit">Sign In</button>
        </form>

        <div class="footer">
            © 2026 ETMS | Employee Time Management System
        </div>
    </div>
</body>
</html>