
package com.etms.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import com.etms.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/employee-status")
public class EmployeeStatusServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // Only logged-in HR can change employee status
        if (session == null
                || !"HR".equals(session.getAttribute("userRole"))) {
            response.sendRedirect("index.jsp");
            return;
        }

        String idValue = request.getParameter("employeeId");
        String action = request.getParameter("action");

        if (idValue == null || action == null
                || !("activate".equals(action)
                || "deactivate".equals(action))) {
            response.sendRedirect("manage-employees?status=invalid");
            return;
        }

        int employeeId;

        try {
            employeeId = Integer.parseInt(idValue);

            if (employeeId <= 0) {
                response.sendRedirect("manage-employees?status=invalid");
                return;
            }
        } catch (NumberFormatException e) {
            response.sendRedirect("manage-employees?status=invalid");
            return;
        }

        // Prevent HR from accidentally deactivating their own account
        Object currentId = session.getAttribute("employeeId");

        if ("deactivate".equals(action)
                && currentId instanceof Integer
                && ((Integer) currentId) == employeeId) {
            response.sendRedirect("manage-employees?status=self");
            return;
        }

        boolean activate = "activate".equals(action);

        String sql = "UPDATE employees SET is_active = ? "
                   + "WHERE employee_id = ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setBoolean(1, activate);
            ps.setInt(2, employeeId);

            int updated = ps.executeUpdate();

            if (updated == 0) {
                response.sendRedirect(
                        "manage-employees?status=notfound");
                return;
            }

            response.sendRedirect(
                    "manage-employees?status="
                    + (activate ? "activated" : "deactivated"));

        } catch (SQLException e) {
            getServletContext().log(
                    "Unable to change employee account status", e);

            throw new ServletException(
                    "Unable to update employee status.", e);
        }
    }
}
