
package com.etms.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.mindrot.jbcrypt.BCrypt;

import com.etms.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String role = request.getParameter("role");

        if (email == null || password == null || role == null
                || email.isBlank() || password.isBlank()
                || role.isBlank()) {
            response.sendRedirect("index.jsp?error=missing");
            return;
        }

        email = email.trim().toLowerCase();

        if (!"HR".equals(role) && !"EMPLOYEE".equals(role)) {
            response.sendRedirect("index.jsp?error=invalid");
            return;
        }

        String sql = "SELECT employee_id, full_name, email, "
                + "password_hash, role FROM employees "
                + "WHERE email = ? AND role = ? AND is_active = TRUE";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql)) {

            statement.setString(1, email);
            statement.setString(2, role);

            try (ResultSet result = statement.executeQuery()) {

                if (result.next()) {
                    String storedPassword =
                            result.getString("password_hash");

                    boolean passwordMatches = false;

                    if (storedPassword != null
                            && (storedPassword.startsWith("$2a$")
                            || storedPassword.startsWith("$2b$")
                            || storedPassword.startsWith("$2y$"))) {
                        try {
                            passwordMatches =
                                    BCrypt.checkpw(password, storedPassword);
                        } catch (IllegalArgumentException e) {
                            passwordMatches = false;
                        }
                    }

                    if (passwordMatches) {
                        HttpSession oldSession =
                                request.getSession(false);

                        if (oldSession != null) {
                            oldSession.invalidate();
                        }

                        HttpSession session =
                                request.getSession(true);

                        session.setAttribute(
                                "employeeId",
                                result.getInt("employee_id"));

                        session.setAttribute(
                                "fullName",
                                result.getString("full_name"));

                        session.setAttribute(
                                "userRole",
                                result.getString("role"));

                        if ("HR".equals(role)) {
                            response.sendRedirect("hr-dashboard.jsp");
                        } else {
                            response.sendRedirect("employee-dashboard.jsp");
                        }
                        return;
                    }
                }
            }

            response.sendRedirect("index.jsp?error=invalid");

        } catch (SQLException e) {
            getServletContext().log("Login database error", e);
            throw new ServletException(
                    "Database error during login.", e);
        }
    }
}
