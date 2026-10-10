package com.etms.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

import com.etms.util.AttendanceTaskService;
import com.etms.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/attendance")
public class AttendanceServlet extends HttpServlet {

    private static final LocalTime OFFICE_START =
            LocalTime.of(9, 0);

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("employeeId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        String role = (String) session.getAttribute("userRole");

        if (!"HR".equals(role) && !"EMPLOYEE".equals(role)) {
            response.sendRedirect("index.jsp");
            return;
        }

        int employeeId = (Integer) session.getAttribute("employeeId");

        String dashboard = "HR".equals(role)
                ? "hr-dashboard.jsp"
                : "employee-dashboard.jsp";

        String action = request.getParameter("action");

        LocalDate today = LocalDate.now();
        LocalDateTime now = LocalDateTime.now();

        try (Connection con = DBConnection.getConnection()) {

            if ("checkin".equals(action)) {

                String checkExisting =
                        "SELECT log_id FROM time_logs "
                        + "WHERE employee_id = ? AND work_date = ?";

                try (PreparedStatement ps =
                             con.prepareStatement(checkExisting)) {

                    ps.setInt(1, employeeId);
                    ps.setDate(2, java.sql.Date.valueOf(today));

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            response.sendRedirect(
                                    dashboard + "?attendance=already");
                            return;
                        }
                    }
                }

                String insert =
                        "INSERT INTO time_logs "
                        + "(employee_id, work_date, start_time, check_in, "
                        + "status, attendance_status, attendance_count) "
                        + "VALUES (?, ?, ?, ?, 'SUBMITTED', 'ABSENT', 0.0)";

                try (PreparedStatement ps =
                             con.prepareStatement(insert)) {

                    ps.setInt(1, employeeId);
                    ps.setDate(2, java.sql.Date.valueOf(today));
                    ps.setTime(3,
                            java.sql.Time.valueOf(now.toLocalTime()));
                    ps.setTimestamp(4, Timestamp.valueOf(now));

                    ps.executeUpdate();
                }

                AttendanceTaskService.submitAuditEvent(
                        employeeId,
                        "CHECK_IN",
                        "Attendance check-in for " + today
                );

                response.sendRedirect(
                        dashboard + "?attendance=checkedin");

            } else if ("checkout".equals(action)) {

                Timestamp checkInTimestamp;

                String findCheckIn =
                        "SELECT check_in FROM time_logs "
                        + "WHERE employee_id = ? AND work_date = ? "
                        + "AND check_in IS NOT NULL AND check_out IS NULL";

                try (PreparedStatement ps =
                             con.prepareStatement(findCheckIn)) {

                    ps.setInt(1, employeeId);
                    ps.setDate(2, java.sql.Date.valueOf(today));

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            response.sendRedirect(
                                    dashboard + "?attendance=noactive");
                            return;
                        }

                        checkInTimestamp = rs.getTimestamp("check_in");
                    }
                }

                LocalDateTime checkInDateTime =
                        checkInTimestamp.toLocalDateTime();

                if (now.isBefore(checkInDateTime)) {
                    response.sendRedirect(
                            dashboard + "?attendance=invalidtime");
                    return;
                }

                double workingHours =
                        Duration.between(checkInDateTime, now).toMinutes()
                        / 60.0;

                boolean lateCheckIn =
                        !checkInDateTime.toLocalTime()
                                .isBefore(OFFICE_START.plusHours(4));

                String attendanceStatus;
                double attendanceCount;

                if (workingHours < 4.0) {
                    attendanceStatus = "ABSENT";
                    attendanceCount = 0.0;
                } else if (workingHours < 8.0 || lateCheckIn) {
                    attendanceStatus = "HALF_DAY";
                    attendanceCount = 0.5;
                } else {
                    attendanceStatus = "FULL_DAY";
                    attendanceCount = 1.0;
                }

                String update =
                        "UPDATE time_logs "
                        + "SET end_time = ?, check_out = ?, "
                        + "attendance_status = ?, attendance_count = ? "
                        + "WHERE employee_id = ? AND work_date = ? "
                        + "AND check_in IS NOT NULL AND check_out IS NULL";

                int updated;

                try (PreparedStatement ps =
                             con.prepareStatement(update)) {

                    ps.setTime(1,
                            java.sql.Time.valueOf(now.toLocalTime()));
                    ps.setTimestamp(2, Timestamp.valueOf(now));
                    ps.setString(3, attendanceStatus);
                    ps.setDouble(4, attendanceCount);
                    ps.setInt(5, employeeId);
                    ps.setDate(6, java.sql.Date.valueOf(today));

                    updated = ps.executeUpdate();
                }

                if (updated > 0) {

                    AttendanceTaskService.submitAuditEvent(
                            employeeId,
                            "CHECK_OUT",
                            "Attendance check-out for " + today
                                    + ", status=" + attendanceStatus
                    );

                    response.sendRedirect(
                            dashboard + "?attendance=checkedout");

                } else {
                    response.sendRedirect(
                            dashboard + "?attendance=noactive");
                }

            } else {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Invalid attendance action.");
            }

        } catch (SQLException e) {
            getServletContext().log(
                    "Attendance operation failed", e);

            throw new ServletException(
                    "Attendance operation failed.", e);
        }
    }
}