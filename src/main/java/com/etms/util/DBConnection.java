package com.etms.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    private static final String URL =
            System.getenv().getOrDefault(
                    "ETMS_DB_URL",
                    "jdbc:mysql://localhost:3306/etms_db"
            );

    private static final String USER =
            System.getenv().getOrDefault("ETMS_DB_USER", "root");

    private static final String PASSWORD =
            System.getenv("ETMS_DB_PASSWORD");

    public static Connection getConnection() throws SQLException {
        if (PASSWORD == null || PASSWORD.isBlank()) {
            throw new SQLException(
                    "ETMS_DB_PASSWORD environment variable is not configured."
            );
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException(
                    "MySQL JDBC driver not found. Check the Maven dependency.",
                    e
            );
        }

        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
