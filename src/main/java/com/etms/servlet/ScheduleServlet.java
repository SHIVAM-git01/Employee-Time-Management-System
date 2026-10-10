
package com.etms.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalTime;
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

@WebServlet("/schedules")
public class ScheduleServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("employeeId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        String role = (String) session.getAttribute("userRole");

        if ("HR".equals(role)) {
            List<Map<String, Object>> schedules = new ArrayList<>();

            String sql = "SELECT s.schedule_id, s.employee_id, e.full_name, " +
                    "s.work_day, s.shift_start, s.shift_end " +
                    "FROM schedules s JOIN employees e " +
                    "ON s.employee_id = e.employee_id " +
                    "ORDER BY e.full_name, s.work_day";

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("scheduleId", rs.getInt("schedule_id"));
                    row.put("employeeId", rs.getInt("employee_id"));
                    row.put("name", rs.getString("full_name"));
                    row.put("day", rs.getString("work_day"));
                    row.put("start", rs.getString("shift_start"));
                    row.put("end", rs.getString("shift_end"));
                    schedules.add(row);
                }

            } catch (SQLException e) {
                throw new ServletException("Unable to load schedules", e);
            }

            List<Map<String, Object>> employees = new ArrayList<>();

            String employeeSql =
                    "SELECT employee_id, full_name FROM employees " +
                    "WHERE role = 'EMPLOYEE' AND is_active = 1 " +
                    "ORDER BY full_name";

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(employeeSql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("employee_id"));
                    row.put("name", rs.getString("full_name"));
                    employees.add(row);
                }

            } catch (SQLException e) {
                throw new ServletException("Unable to load employees", e);
            }

            request.setAttribute("schedules", schedules);
            request.setAttribute("employees", employees);
            request.getRequestDispatcher("/manage-schedules.jsp")
                    .forward(request, response);

        } else if ("EMPLOYEE".equals(role)) {
            List<Map<String, Object>> schedules = new ArrayList<>();

            String sql = "SELECT work_day, shift_start, shift_end " +
                    "FROM schedules WHERE employee_id = ? " +
                    "ORDER BY FIELD(work_day, 'Monday', 'Tuesday', " +
                    "'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')";

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(sql)) {

                ps.setInt(1, (Integer) session.getAttribute("employeeId"));

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> row = new HashMap<>();
                        row.put("day", rs.getString("work_day"));
                        row.put("start", rs.getString("shift_start"));
                        row.put("end", rs.getString("shift_end"));
                        schedules.add(row);
                    }
                }

            } catch (SQLException e) {
                throw new ServletException("Unable to load your schedule", e);
            }

            request.setAttribute("schedules", schedules);
            request.getRequestDispatcher("/my-schedule.jsp")
                    .forward(request, response);

        } else {
            response.sendRedirect("index.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("employeeId") == null
                || !"HR".equals(session.getAttribute("userRole"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String employeeValue = request.getParameter("employeeId");
        String day = request.getParameter("workDay");
        String start = request.getParameter("shiftStart");
        String end = request.getParameter("shiftEnd");

        try {
            int employeeId = Integer.parseInt(employeeValue);
            LocalTime startTime = LocalTime.parse(start);
            LocalTime endTime = LocalTime.parse(end);

            if (day == null ||
                    !day.matches("Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday")
                    || !startTime.isBefore(endTime)) {
                response.sendRedirect("schedules?status=invalid");
                return;
            }

            try (Connection con = DBConnection.getConnection()) {
                con.setAutoCommit(false);

                try {
                    String checkEmployee =
                            "SELECT employee_id FROM employees " +
                            "WHERE employee_id = ? AND role = 'EMPLOYEE' " +
                            "AND is_active = 1 FOR UPDATE";

                    boolean validEmployee;

                    try (PreparedStatement ps =
                                 con.prepareStatement(checkEmployee)) {
                        ps.setInt(1, employeeId);
                        try (ResultSet rs = ps.executeQuery()) {
                            validEmployee = rs.next();
                        }
                    }

                    if (!validEmployee) {
                        con.rollback();
                        response.sendRedirect("schedules?status=invalid");
                        return;
                    }

                    String checkSchedule =
                            "SELECT schedule_id FROM schedules " +
                            "WHERE employee_id = ? AND work_day = ?";

                    Integer scheduleId = null;

                    try (PreparedStatement ps =
                                 con.prepareStatement(checkSchedule)) {
                        ps.setInt(1, employeeId);
                        ps.setString(2, day);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                scheduleId = rs.getInt("schedule_id");
                            }
                        }
                    }

                    if (scheduleId == null) {
                        String insert =
                                "INSERT INTO schedules " +
                                "(employee_id, work_day, shift_start, shift_end) " +
                                "VALUES (?, ?, ?, ?)";

                        try (PreparedStatement ps =
                                     con.prepareStatement(insert)) {
                            ps.setInt(1, employeeId);
                            ps.setString(2, day);
                            ps.setTime(3, java.sql.Time.valueOf(startTime));
                            ps.setTime(4, java.sql.Time.valueOf(endTime));
                            ps.executeUpdate();
                        }
                    } else {
                        String update =
                                "UPDATE schedules SET shift_start = ?, shift_end = ? " +
                                "WHERE schedule_id = ?";

                        try (PreparedStatement ps =
                                     con.prepareStatement(update)) {
                            ps.setTime(1, java.sql.Time.valueOf(startTime));
                            ps.setTime(2, java.sql.Time.valueOf(endTime));
                            ps.setInt(3, scheduleId);
                            ps.executeUpdate();
                        }
                    }

                    con.commit();

                } catch (Exception e) {
                    try {
                        con.rollback();
                    } catch (SQLException rollbackError) {
                        e.addSuppressed(rollbackError);
                    }
                    throw e;
                } finally {
                    try {
                        con.setAutoCommit(true);
                    } catch (SQLException ignored) {
                        getServletContext().log(
                                "Could not restore auto-commit", ignored);
                    }
                }
            }

            response.sendRedirect("schedules?status=saved");

        } catch (NumberFormatException | java.time.format.DateTimeParseException e) {
            response.sendRedirect("schedules?status=invalid");
        } catch (Exception e) {
            getServletContext().log("Schedule save failed", e);
            throw new ServletException("Unable to save schedule", e);
        }
    }
}
