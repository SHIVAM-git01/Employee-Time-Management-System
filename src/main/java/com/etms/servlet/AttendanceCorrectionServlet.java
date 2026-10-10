
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

@WebServlet("/attendance-correction")
public class AttendanceCorrectionServlet extends HttpServlet {

    // Display recent attendance records to HR.
    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("employeeId") == null
                || !"HR".equals(session.getAttribute("userRole"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Only HR can access this page.");
            return;
        }

        String sql =
                "SELECT t.log_id, t.employee_id, e.full_name, " +
                "t.work_date, t.check_in, t.check_out, " +
                "t.attendance_status " +
                "FROM time_logs t " +
                "JOIN employees e ON e.employee_id = t.employee_id " +
                "ORDER BY t.work_date DESC, t.log_id DESC LIMIT 100";

        List<Map<String, Object>> rows = new ArrayList<>();

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();

                row.put("logId", rs.getInt("log_id"));
                row.put("employeeId", rs.getInt("employee_id"));
                row.put("name", rs.getString("full_name"));
                row.put("date", rs.getDate("work_date"));
                row.put("checkIn", rs.getTimestamp("check_in"));
                row.put("checkOut", rs.getTimestamp("check_out"));
                row.put("status", rs.getString("attendance_status"));

                rows.add(row);
            }

        } catch (SQLException e) {
            throw new ServletException(
                    "Unable to load attendance records.", e);
        }

        request.setAttribute("attendanceRows", rows);
        request.getRequestDispatcher("/attendance-correction.jsp")
                .forward(request, response);
    }

    // Correct attendance and save a history record in one transaction.
    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("employeeId") == null
                || !"HR".equals(session.getAttribute("userRole"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Only HR can correct attendance.");
            return;
        }

        int hrId = (Integer) session.getAttribute("employeeId");

        int logId;
        try {
            logId = Integer.parseInt(request.getParameter("logId"));
        } catch (Exception e) {
            response.sendRedirect("attendance-correction?result=invalid");
            return;
        }

        String status = request.getParameter("status");
        String reason = request.getParameter("reason");

        if (logId <= 0
                || !("FULL_DAY".equals(status)
                || "HALF_DAY".equals(status)
                || "ABSENT".equals(status))
                || reason == null
                || reason.trim().isEmpty()
                || reason.trim().length() > 255) {

            response.sendRedirect("attendance-correction?result=invalid");
            return;
        }

        double attendanceCount;

        if ("FULL_DAY".equals(status)) {
            attendanceCount = 1.0;
        } else if ("HALF_DAY".equals(status)) {
            attendanceCount = 0.5;
        } else {
            attendanceCount = 0.0;
        }

        try (Connection con = DBConnection.getConnection()) {

            con.setAutoCommit(false);

            try {
                String oldStatus;

                // Lock the selected attendance row during correction.
                String selectSql =
                        "SELECT attendance_status, check_out " +
                        "FROM time_logs WHERE log_id = ? FOR UPDATE";

                try (PreparedStatement ps =
                             con.prepareStatement(selectSql)) {

                    ps.setInt(1, logId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            con.rollback();
                            response.sendRedirect(
                                    "attendance-correction?result=notfound");
                            return;
                        }

                        // Do not edit an attendance that is still in progress.
                        if (rs.getTimestamp("check_out") == null) {
                            con.rollback();
                            response.sendRedirect(
                                    "attendance-correction?result=active");
                            return;
                        }

                        oldStatus = rs.getString("attendance_status");
                    }
                }

                String updateSql =
                        "UPDATE time_logs " +
                        "SET attendance_status = ?, attendance_count = ? " +
                        "WHERE log_id = ?";

                try (PreparedStatement ps =
                             con.prepareStatement(updateSql)) {

                    ps.setString(1, status);
                    ps.setDouble(2, attendanceCount);
                    ps.setInt(3, logId);

                    if (ps.executeUpdate() != 1) {
                        throw new SQLException(
                                "Attendance record could not be updated.");
                    }
                }

                String historySql =
                        "INSERT INTO attendance_corrections " +
                        "(log_id, corrected_by, old_status, new_status, reason) " +
                        "VALUES (?, ?, ?, ?, ?)";

                try (PreparedStatement ps =
                             con.prepareStatement(historySql)) {

                    ps.setInt(1, logId);
                    ps.setInt(2, hrId);
                    ps.setString(3, oldStatus);
                    ps.setString(4, status);
                    ps.setString(5, reason.trim());

                    ps.executeUpdate();
                }

                // Both the attendance update and history insert succeeded.
                con.commit();

            } catch (Exception e) {
                try {
                    con.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;
            }

        } catch (Exception e) {
            throw new ServletException(
                    "Attendance correction failed.", e);
        }

        response.sendRedirect("attendance-correction?result=success");
    }
}
