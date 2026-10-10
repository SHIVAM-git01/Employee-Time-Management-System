
package com.etms.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.etms.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/manage-employees")
public class ManageEmployeesServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || !"HR".equals(session.getAttribute("userRole"))) {
            response.sendRedirect("index.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String search = request.getParameter("q");

        if (search == null) {
            search = "";
        }

        search = search.trim();

        List<Map<String, Object>> employees = new ArrayList<>();

        String sql =
                "SELECT employee_id, full_name, email, role, is_active "
                + "FROM employees "
                + "WHERE full_name LIKE ? OR email LIKE ? "
                + "ORDER BY employee_id";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            String searchPattern = "%" + search + "%";

            ps.setString(1, searchPattern);
            ps.setString(2, searchPattern);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> employee = new HashMap<>();

                    employee.put("id", rs.getInt("employee_id"));
                    employee.put("name", rs.getString("full_name"));
                    employee.put("email", rs.getString("email"));
                    employee.put("role", rs.getString("role"));
                    employee.put("active", rs.getBoolean("is_active"));

                    employees.add(employee);
                }
            }

        } catch (SQLException e) {
            getServletContext().log(
                    "Unable to load employee list", e);

            throw new ServletException(
                    "Unable to load employees from database.", e);
        }

        request.setAttribute("employees", employees);
        request.setAttribute("search", search);

        request.getRequestDispatcher("/manage-employees.jsp")
                .forward(request, response);
    }
}
