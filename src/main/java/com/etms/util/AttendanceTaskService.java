package com.etms.util;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.RejectedExecutionException;
import java.util.logging.Level;
import java.util.logging.Logger;

public final class AttendanceTaskService {

    private static final Logger LOGGER =
            Logger.getLogger(AttendanceTaskService.class.getName());

    private static final ExecutorService EXECUTOR =
            Executors.newFixedThreadPool(2);

    private AttendanceTaskService() {
        // Utility class
    }

    public static void submitAuditEvent(
            int employeeId, String action, String details) {

        try {
            EXECUTOR.submit(() -> {
                LOGGER.info(
                    "Attendance event | employeeId=" + employeeId
                    + " | action=" + action
                    + " | details=" + details
                );
            });
        } catch (RejectedExecutionException e) {
            LOGGER.log(
                Level.WARNING,
                "Attendance background task was rejected.",
                e
            );
        }
    }

    public static void shutdown() {
        EXECUTOR.shutdown();
    }
}