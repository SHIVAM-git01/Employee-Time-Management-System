
package com.etms.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.mindrot.jbcrypt.BCrypt;

import com.etms.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/employees")
public class EmployeeServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // Only HR can add employees
        if (session == null
                || !"HR".equals(session.getAttribute("userRole"))) {
            response.sendRedirect("index.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String role = request.getParameter("role");

        if (fullName == null || email == null
                || password == null || role == null
                || fullName.isBlank() || email.isBlank()
                || password.isBlank()
                || !("HR".equals(role) || "EMPLOYEE".equals(role))) {

            response.sendRedirect("hr-dashboard.jsp?employee=invalid");
            return;
        }

        fullName = fullName.trim();
        email = email.trim().toLowerCase();

        if (!email.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")) {
            response.sendRedirect("hr-dashboard.jsp?employee=invalidemail");
            return;
        }

        if (password.length() < 8) {
            response.sendRedirect("hr-dashboard.jsp?employee=weakpassword");
            return;
        }

        String passwordHash = BCrypt.hashpw(
                password, BCrypt.gensalt(12));

        String sql = "INSERT INTO employees "
                + "(full_name, email, password_hash, role, is_active) "
                + "VALUES (?, ?, ?, ?, TRUE)";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {

            statement.setString(1, fullName);
            statement.setString(2, email);
            statement.setString(3, passwordHash);
            statement.setString(4, role);

            statement.executeUpdate();

            response.sendRedirect("hr-dashboard.jsp?employee=added");

        } catch (SQLException e) {

            // Duplicate email
            if ("23000".equals(e.getSQLState())) {
                response.sendRedirect(
                        "hr-dashboard.jsp?employee=duplicate");
                return;
            }

            getServletContext().log("Employee creation failed", e);
            throw new ServletException("Unable to add employee.", e);
        }
    }
}
