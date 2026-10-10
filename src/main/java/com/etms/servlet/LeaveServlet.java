
package com.etms.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDate;

import com.etms.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/leaves")
public class LeaveServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

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

        Integer employeeId =
                (Integer) session.getAttribute("employeeId");

        String action = request.getParameter("action");

        try (Connection con = DBConnection.getConnection()) {

            if ("apply".equals(action)) {

                String startDateText =
                        request.getParameter("startDate");
                String endDateText =
                        request.getParameter("endDate");
                String reason = request.getParameter("reason");
                String leaveType = request.getParameter("leaveType");
                String halfDayPeriod =
                        request.getParameter("halfDayPeriod");

                if (startDateText == null || endDateText == null
                        || reason == null || leaveType == null
                        || startDateText.isBlank()
                        || endDateText.isBlank()
                        || reason.isBlank()
                        || reason.trim().length() > 255
                        || !("FULL_DAY".equals(leaveType)
                             || "HALF_DAY".equals(leaveType))) {
                    response.sendRedirect(
                            "leave.jsp?message=invalid");
                    return;
                }

                LocalDate startDate;
                LocalDate endDate;

                try {
                    startDate = LocalDate.parse(startDateText);
                    endDate = LocalDate.parse(endDateText);
                } catch (Exception ex) {
                    response.sendRedirect(
                            "leave.jsp?message=invalid");
                    return;
                }

                if (endDate.isBefore(startDate)
                        || startDate.isBefore(LocalDate.now())) {
                    response.sendRedirect(
                            "leave.jsp?message=invaliddates");
                    return;
                }

                if ("HALF_DAY".equals(leaveType)) {
                    if (!startDate.equals(endDate)
                            || !("MORNING".equals(halfDayPeriod)
                                 || "AFTERNOON".equals(halfDayPeriod))) {
                        response.sendRedirect(
                                "leave.jsp?message=invalidhalfday");
                        return;
                    }
                } else {
                    halfDayPeriod = null;
                }

                String sql =
                        "INSERT INTO leave_requests "
                        + "(employee_id, start_date, end_date, reason, "
                        + "status, leave_type, half_day_period) "
                        + "VALUES (?, ?, ?, ?, 'PENDING', ?, ?)";

                try (PreparedStatement ps =
                             con.prepareStatement(sql)) {

                    ps.setInt(1, employeeId);
                    ps.setDate(2, Date.valueOf(startDate));
                    ps.setDate(3, Date.valueOf(endDate));
                    ps.setString(4, reason.trim());
                    ps.setString(5, leaveType);
                    ps.setString(6, halfDayPeriod);

                    ps.executeUpdate();
                }

                response.sendRedirect("leave.jsp?message=applied");

            } else if ("review".equals(action)) {

                if (!"HR".equals(role)) {
                    response.sendError(
                            HttpServletResponse.SC_FORBIDDEN,
                            "Only HR can review leave requests.");
                    return;
                }

                String leaveIdText = request.getParameter("leaveId");
                String decision = request.getParameter("decision");

                if (leaveIdText == null
                        || !leaveIdText.matches("\\d+")
                        || !("APPROVED".equals(decision)
                             || "REJECTED".equals(decision))) {
                    response.sendRedirect(
                            "manage-leaves.jsp?message=invalid");
                    return;
                }

                int leaveId = Integer.parseInt(leaveIdText);

                String sql =
                        "UPDATE leave_requests "
                        + "SET status = ? "
                        + "WHERE leave_id = ? AND status = 'PENDING'";

                int updated;

                try (PreparedStatement ps =
                             con.prepareStatement(sql)) {

                    ps.setString(1, decision);
                    ps.setInt(2, leaveId);
                    updated = ps.executeUpdate();
                }

                response.sendRedirect(
                        "manage-leaves.jsp?message="
                        + (updated > 0 ? decision.toLowerCase()
                                       : "alreadyreviewed"));

            } else {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Invalid leave action.");
            }

        } catch (SQLException e) {
            getServletContext().log("Leave operation failed", e);
            throw new ServletException(
                    "Unable to process leave request.", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("employeeId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        String role = (String) session.getAttribute("userRole");

        if ("HR".equals(role)) {
            response.sendRedirect("manage-leaves.jsp");
        } else if ("EMPLOYEE".equals(role)) {
            response.sendRedirect("leave.jsp");
        } else {
            response.sendRedirect("index.jsp");
        }
    }
}
