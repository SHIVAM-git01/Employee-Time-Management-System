# Employee Time Management System (ETMS)

A Java-based web application designed to manage employee attendance, work schedules, leave requests, and HR operations through role-based access.

## Overview

The Employee Time Management System provides a centralized platform for employees and HR administrators to manage daily workforce activities. Employees can record attendance, apply for leave, and view their schedules, while HR can manage employee records, review leave requests, correct attendance records, and generate reports.

## Features

### HR Module
- HR login with role-based access
- Dashboard with attendance summaries
- Add, search, activate, and deactivate employee accounts
- Review and manage leave requests
- Create and update employee work schedules
- Correct attendance records with correction history
- Generate attendance and leave reports with date filters

### Employee Module
- Secure employee login
- Attendance check-in and check-out
- View personal work schedules
- Apply for full-day and half-day leave
- View leave application history

### Technical Features
- Object-oriented Java backend
- Role-based authorization
- BCrypt password hashing
- MySQL database connectivity through JDBC
- SQL transactions for operations requiring consistent updates
- Background attendance audit logging using a thread pool
- Maven-based build and WAR packaging

## Technology Stack

| Technology | Purpose |
|---|---|
| Java | Backend programming |
| JSP | Web page rendering |
| Jakarta Servlets | Request handling |
| JDBC | Database connectivity |
| MySQL 8 | Relational database |
| Apache Tomcat 10.1 | Web application server |
| Maven | Dependency management and build |
| HTML/CSS | User interface |
| jBCrypt | Password hashing |
| Git and GitHub | Version control |

## Project Structure

```text
employee-time-management/
├── pom.xml
├── .gitignore
└── src/
    └── main/
        ├── java/com/etms/
        │   ├── servlet/
        │   │   ├── AttendanceServlet.java
        │   │   ├── AttendanceCorrectionServlet.java
        │   │   ├── EmployeeServlet.java
        │   │   ├── EmployeeStatusServlet.java
        │   │   ├── LeaveServlet.java
        │   │   ├── LoginServlet.java
        │   │   ├── LogoutServlet.java
        │   │   ├── ManageEmployeesServlet.java
        │   │   └── ScheduleServlet.java
        │   └── util/
        │       ├── AttendanceTaskService.java
        │       ├── DBConnection.java
        │       └── ETMSContextListener.java
        └── webapp/
            ├── WEB-INF/web.xml
            ├── index.jsp
            ├── hr-dashboard.jsp
            ├── employee-dashboard.jsp
            ├── attendance-correction.jsp
            ├── leave.jsp
            ├── manage-employees.jsp
            ├── manage-leaves.jsp
            ├── manage-schedules.jsp
            ├── my-schedule.jsp
            └── reports.jsp
```

## Prerequisites

Install the following software:

- JDK compatible with the project's Maven compiler configuration
- Apache Maven
- MySQL Server 8.0 or compatible version
- Apache Tomcat 10.1
- Visual Studio Code (optional)

## Database Configuration

1. Start MySQL Server.
2. Create or configure the `etms_db` database.
3. Configure the required tables and relationships for employees, attendance, leave requests, schedules, and attendance correction history.
4. Configure the database connection using environment variables.

The application supports these environment variables:

| Variable | Purpose |
|---|---|
| `ETMS_DB_URL` | JDBC connection URL |
| `ETMS_DB_USER` | MySQL username |
| `ETMS_DB_PASSWORD` | MySQL password |

Default database URL: `jdbc:mysql://localhost:3306/etms_db`

**Security:** Never commit real database passwords, tokens, or other secrets to GitHub.

## Build and Run

Open a terminal in the project root.

### 1. Configure database environment variables

For Windows CMD, set the values in the same terminal session used to start Tomcat:

```bat
set ETMS_DB_USER=root
set /p ETMS_DB_PASSWORD=Enter MySQL password:
set ETMS_DB_URL=jdbc:mysql://localhost:3306/etms_db
```

Enter your own MySQL password when prompted.

### 2. Build the project

```bat
mvn clean package
```

A successful build generates a WAR file in the `target/` directory.

### 3. Deploy to Apache Tomcat

Copy the generated WAR file to Tomcat's `webapps` directory:

```bat
copy /Y target\employee-time-management.war C:\apache-tomcat-10\apache-tomcat-10.1.60\webapps\employee-time-management.war
```

Start Tomcat with the required environment variables available to its process.

### 4. Open the application

```text
http://localhost:8080/employee-time-management/
```

Ensure MySQL and Tomcat are running and the database schema has been configured before signing in.

## Security Considerations

- Passwords are verified using BCrypt hashes.
- Database credentials are supplied through environment variables.
- SQL queries use prepared statements where applicable.
- HR-only operations should be accessible only to authorized HR users.
- Use unique, strong passwords and never publish real credentials or private employee information.

## Future Enhancements

- Email notifications for leave approvals
- Exportable PDF and Excel reports
- Employee profile management
- Automated attendance reminders
- Improved dashboard analytics
- Deployment to a cloud hosting platform

## Author

**Shivam Kumar**

B.Tech — Computer Science and Engineering

## Project Purpose

This project demonstrates Java web development concepts, database integration, session-based authentication, role-based workflows, and workforce management functionality as part of an academic software project.