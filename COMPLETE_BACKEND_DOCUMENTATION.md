# Employee Productivity Tracking Backend System - Complete Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Database Schema](#database-schema)
5. [Authentication & Security](#authentication--security)
6. [API Endpoints](#api-endpoints)
7. [Data Models](#data-models)
8. [Services & Business Logic](#services--business-logic)
9. [Configuration](#configuration)
10. [Deployment](#deployment)
11. [Testing](#testing)
12. [Frontend Integration Guide](#frontend-integration-guide)

---

## System Overview

The Employee Productivity Tracking Backend is a Spring Boot REST API system designed to monitor and track employee activities, process usage, and productivity metrics. The system implements role-based authentication with three user roles: EMPLOYEE, ADMIN, and SUPERADMIN.

### Key Features
- **Role-based Authentication**: JWT-based authentication with three roles
- **Process Tracking**: Monitor running processes and applications
- **Activity Logging**: Track user activities and time spent
- **Analytics**: Generate productivity reports and insights
- **User Management**: Admin functions for managing users
- **Real-time Monitoring**: Live process and activity tracking
- **Security**: Anti-tampering measures and secure data handling

### Base Configuration
- **Server Port**: 8081
- **Base URL**: `http://localhost:8081/api`
- **Database**: Microsoft SQL Server
- **Authentication**: JWT Bearer tokens

---

## Technology Stack

### Core Technologies
- **Java**: 21
- **Spring Boot**: 3.4.1
- **Spring Framework**: Web, Data JPA, Security
- **Database**: Microsoft SQL Server
- **Authentication**: JWT (JSON Web Tokens)
- **Build Tool**: Maven
- **ORM**: Hibernate/JPA

### Key Dependencies
```xml
<dependencies>
    <!-- Core Spring Boot -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- Data Persistence -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    
    <!-- Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    
    <!-- JWT -->
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>0.11.5</version>
    </dependency>
    
    <!-- Database Driver -->
    <dependency>
        <groupId>com.microsoft.sqlserver</groupId>
        <artifactId>mssql-jdbc</artifactId>
    </dependency>
    
    <!-- Utilities -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
    </dependency>
</dependencies>
```

---

## Project Structure

```
src/main/java/com/example/backendapp/
├── BackendAppApplication.java          # Main application class
├── config/
│   └── SecurityConfig.java             # Security configuration
├── controller/                         # REST API controllers
│   ├── UserController.java            # User management endpoints
│   ├── ActivityController.java        # Activity tracking endpoints
│   ├── ProcessTrackingController.java # Process monitoring endpoints
│   ├── AnalyticsController.java       # Analytics and reporting
│   ├── AdminController.java           # Admin-only functions
│   ├── SecurityEndpointController.java # Security utilities
│   ├── LogCollectorController.java    # Log collection
│   ├── LoginController.java           # Authentication
│   └── TestTrackingController.java    # Testing utilities
├── entity/                            # JPA entities (database models)
│   ├── User.java                      # User entity
│   ├── Activity.java                  # Activity tracking entity
│   ├── ProcessTrack.java              # Process monitoring entity
│   ├── Task.java                      # Task management entity
│   └── Role.java                      # Role entity
├── repository/                        # Data access layer
│   ├── UserRepository.java            # User data access
│   ├── ActivityRepository.java        # Activity data access
│   ├── ProcessTrackRepository.java    # Process data access
│   └── TaskRepository.java            # Task data access
├── service/                           # Business logic layer
│   ├── UserService.java               # User business logic
│   ├── ActivityTrackingService.java   # Activity tracking logic
│   ├── ProcessTrackingService.java    # Process monitoring logic
│   ├── AnalyticsService.java          # Analytics calculations
│   ├── AntiTamperingService.java      # Security services
│   └── LogCollectorService.java       # Log collection services
├── security/                          # Security components
│   ├── JwtTokenProvider.java          # JWT token handling
│   └── JwtAuthenticationFilter.java   # Authentication filter
└── util/                             # Utility classes
    └── PasswordGenerator.java         # Password utilities

src/main/resources/
├── application.properties             # Application configuration
└── static/                           # Static resources (if any)
```

---

## Database Schema

### Database Configuration
- **Database Name**: `EmployeesProductivityData`
- **Server**: `localhost:1433` (SQL Server)
- **Authentication**: SQL Server Authentication

### Core Tables

#### 1. Users Table
```sql
CREATE TABLE users (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(255) NOT NULL UNIQUE,
    email NVARCHAR(255) NOT NULL UNIQUE,
    password NVARCHAR(255) NOT NULL,
    role NVARCHAR(50) NOT NULL,
    active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE()
);
```

#### 2. Activities Table
```sql
CREATE TABLE activities (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    activity_name NVARCHAR(255),
    start_time DATETIME2,
    end_time DATETIME2,
    duration_minutes INT,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 3. Process_Track Table
```sql
CREATE TABLE process_track (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    process_name NVARCHAR(255),
    process_id INT,
    start_time DATETIME2,
    end_time DATETIME2,
    cpu_usage DECIMAL(5,2),
    memory_usage DECIMAL(10,2),
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 4. Tasks Table
```sql
CREATE TABLE tasks (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title NVARCHAR(255) NOT NULL,
    description NTEXT,
    status NVARCHAR(50),
    priority NVARCHAR(20),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2,
    due_date DATETIME2,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## Authentication & Security

### Role-Based Access Control

#### User Roles
1. **EMPLOYEE**
   - Can track own processes and activities
   - Can view own profile and statistics
   - Cannot access admin functions

2. **ADMIN**
   - All employee permissions
   - Can view all users and activities
   - Can manage regular employees
   - Cannot manage other admins

3. **SUPERADMIN**
   - All admin permissions
   - Can manage admin users
   - Can access system settings
   - Full system access

### JWT Token Structure
```json
{
  "sub": "username",
  "userId": 123,
  "role": "ROLE_ADMIN",
  "iat": 1640995200,
  "exp": 1641081600
}
```

### Security Configuration
- **Token Expiration**: 24 hours (86400000 ms)
- **Algorithm**: HMAC SHA-256
- **Password Encoding**: BCrypt
- **Session Management**: Stateless (JWT-based)

### Protected Endpoints by Role

#### Public Endpoints (No Authentication)
- `POST /api/users/register`
- `POST /api/users/login`
- `GET /api/test/**`

#### Employee Level (All Authenticated Users)
- `GET /api/users/profile`
- `PUT /api/users/profile`
- `POST /api/process-tracking/**`
- `GET /api/activities/user/**`

#### Admin Level (ADMIN + SUPERADMIN)
- `GET /api/users/all`
- `GET /api/activities/all`
- `POST /api/users/deactivate/**`
- `GET /api/analytics/admin/**`

#### SuperAdmin Level (SUPERADMIN Only)
- `GET /api/system/**`
- `GET /api/analytics/system/**`

---

## API Endpoints

### Authentication Endpoints

#### Register User
```http
POST /api/users/register
Content-Type: application/json

{
    "username": "string",
    "email": "string",
    "password": "string",
    "role": "EMPLOYEE|ADMIN|SUPERADMIN"
}
```

**Response (200 OK):**
```json
{
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "role": "EMPLOYEE",
    "active": true
}
```

#### Login User
```http
POST /api/users/login
Content-Type: application/json

{
    "username": "string",
    "password": "string"
}
```

**Response (200 OK):**
```json
{
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "userId": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "role": "EMPLOYEE",
    "permissions": {
        "canTrackProcesses": true,
        "canViewOwnStats": true,
        "canViewAllUsers": false,
        "canViewAllActivities": false,
        "canManageUsers": false,
        "canManageAdmins": false,
        "canAccessSystemSettings": false
    }
}
```

### User Management Endpoints

#### Get User Profile
```http
GET /api/users/profile
Authorization: Bearer {token}
```

#### Get All Users (Admin Only)
```http
GET /api/users/all?role=EMPLOYEE&active=true&page=0&size=20
Authorization: Bearer {token}
```

#### Update User
```http
PUT /api/users/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
    "username": "string",
    "email": "string",
    "role": "string",
    "active": boolean
}
```

#### Deactivate User
```http
POST /api/users/deactivate/{id}
Authorization: Bearer {token}
```

### Activity Tracking Endpoints

#### Log Activity
```http
POST /api/activities/log
Authorization: Bearer {token}
Content-Type: application/json

{
    "activityName": "string",
    "startTime": "2025-06-17T10:00:00",
    "endTime": "2025-06-17T11:00:00",
    "userId": 1
}
```

#### Get User Activities
```http
GET /api/activities/user/{userId}?startDate=2025-06-17T00:00:00&endDate=2025-06-17T23:59:59
Authorization: Bearer {token}
```

#### Get All Activities (Admin Only)
```http
GET /api/activities/all?page=0&size=20
Authorization: Bearer {token}
```

### Process Tracking Endpoints

#### Log Process
```http
POST /api/process-tracking/log
Authorization: Bearer {token}
Content-Type: application/json

{
    "userId": 1,
    "processName": "notepad.exe",
    "processId": 1234,
    "startTime": "2025-06-17T10:00:00",
    "cpuUsage": 5.2,
    "memoryUsage": 1024.5
}
```

#### Get Process Analytics
```http
GET /api/process-tracking/analytics?userId=1&startDate=2025-06-17T00:00:00&endDate=2025-06-17T23:59:59
Authorization: Bearer {token}
```

### Analytics Endpoints

#### Get User Statistics
```http
GET /api/analytics/user/{userId}/stats
Authorization: Bearer {token}
```

**Response:**
```json
{
    "totalActivities": 150,
    "totalProcessTime": 480,
    "mostUsedProcesses": [
        {"processName": "chrome.exe", "totalTime": 120},
        {"processName": "notepad.exe", "totalTime": 60}
    ],
    "dailyProductivity": 85.5,
    "weeklyTrend": [75, 80, 85, 90, 85, 88, 85]
}
```

#### Get System Analytics (Admin Only)
```http
GET /api/analytics/system/overview
Authorization: Bearer {token}
```

### Security Endpoints

#### Validate Token
```http
POST /api/security/validate-token
Authorization: Bearer {token}
```

#### System Status
```http
GET /api/security/system-status
Authorization: Bearer {token}
```

---

## Data Models

### User Entity
```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true)
    private String username;
    
    @Column(nullable = false, unique = true)
    private String email;
    
    @Column(nullable = false)
    private String password;
    
    @Column(nullable = false)
    private String role; // ROLE_EMPLOYEE, ROLE_ADMIN, ROLE_SUPERADMIN
    
    @Column(nullable = false)
    private boolean active;
    
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
```

### Activity Entity
```java
@Entity
@Table(name = "activities")
public class Activity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id")
    private Long userId;
    
    private String activityName;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Integer durationMinutes;
    private LocalDateTime createdAt;
}
```

### ProcessTrack Entity
```java
@Entity
@Table(name = "process_track")
public class ProcessTrack {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id")
    private Long userId;
    
    private String processName;
    private Integer processId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Double cpuUsage;
    private Double memoryUsage;
    private LocalDateTime createdAt;
}
```

---

## Services & Business Logic

### UserService
- **User Registration**: Validates and creates new users
- **Authentication**: Handles login verification
- **Role Management**: Manages user roles and permissions
- **User Operations**: CRUD operations for user management

### ActivityTrackingService
- **Activity Logging**: Records user activities
- **Time Tracking**: Calculates activity durations
- **Activity Retrieval**: Fetches user activities with filtering

### ProcessTrackingService
- **Process Monitoring**: Tracks running processes
- **Resource Usage**: Monitors CPU and memory usage
- **Process Analytics**: Generates process usage statistics

### AnalyticsService
- **Productivity Metrics**: Calculates productivity scores
- **Trend Analysis**: Generates usage trends and patterns
- **Report Generation**: Creates detailed analytics reports

---

## Configuration

### Application Properties
```properties
# Server Configuration
server.port=8081
spring.application.name=Backend-app

# Database Configuration
spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=EmployeesProductivityData;trustServerCertificate=true;encrypt=true
spring.datasource.username=sa
spring.datasource.password=YourPassword
spring.datasource.driver-class-name=com.microsoft.sqlserver.jdbc.SQLServerDriver

# JPA Configuration
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.SQLServerDialect
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# JWT Configuration
jwt.secret=5367566B59703373367639792F423F4528482B4D6251655468576D5A71347437
jwt.expiration=86400000

# CORS Configuration
spring.mvc.cors.allowed-origins=*
spring.mvc.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS
spring.mvc.cors.allowed-headers=*

# Logging Configuration
logging.level.com.example.backendapp=DEBUG
logging.level.org.springframework.security=DEBUG
```

### Security Configuration
- **CORS**: Enabled for cross-origin requests
- **CSRF**: Disabled for REST API
- **Session Management**: Stateless
- **Password Encoding**: BCrypt with strength 12
- **JWT Filter**: Custom authentication filter

---

## Deployment

### Prerequisites
- Java 21 or higher
- Microsoft SQL Server
- Maven 3.6+

### Build and Run
```bash
# Clone repository
git clone <repository-url>
cd Backend-app

# Build application
mvn clean install

# Run application
mvn spring-boot:run

# Alternative: Run JAR file
java -jar target/Backend-app-0.0.1-SNAPSHOT.jar
```

### Database Setup
1. Install Microsoft SQL Server
2. Create database: `EmployeesProductivityData`
3. Update `application.properties` with your database credentials
4. Run application (tables will be created automatically)

### Environment Variables
```bash
export DB_URL=jdbc:sqlserver://localhost:1433;databaseName=EmployeesProductivityData
export DB_USERNAME=sa
export DB_PASSWORD=YourPassword
export JWT_SECRET=YourJWTSecret
export SERVER_PORT=8081
```

---

## Testing

### Test Credentials
```
Employee:    username: employee_test    | password: Password123!
Admin:       username: admin_test       | password: Password123!
SuperAdmin:  username: superadmin_test  | password: Password123!
```

### Testing Tools
- **Postman Collection**: `postman/Role-Based-Auth-Collection.json`
- **PowerShell Scripts**: Various test scripts in project root
- **Unit Tests**: Spring Boot Test framework (to be implemented)

### Test Scenarios
1. **Authentication Tests**: Registration, login, token validation
2. **Authorization Tests**: Role-based access control
3. **API Tests**: All endpoint functionality
4. **Security Tests**: Token expiration, invalid access attempts
5. **Data Tests**: CRUD operations, data integrity

---

## Frontend Integration Guide

### Authentication Flow
1. **Registration**: POST to `/api/users/register`
2. **Login**: POST to `/api/users/login` → Receive JWT token
3. **Store Token**: Save JWT in localStorage/sessionStorage
4. **API Calls**: Include `Authorization: Bearer {token}` header
5. **Token Refresh**: Handle token expiration (re-login)

### Key Integration Points

#### 1. User Authentication
```javascript
// Login API call
const login = async (username, password) => {
    const response = await fetch('http://localhost:8081/api/users/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ username, password })
    });
    
    if (response.ok) {
        const data = await response.json();
        localStorage.setItem('token', data.token);
        localStorage.setItem('userRole', data.role);
        localStorage.setItem('permissions', JSON.stringify(data.permissions));
        return data;
    }
    throw new Error('Login failed');
};
```

#### 2. Authenticated API Calls
```javascript
// Generic API call with authentication
const apiCall = async (endpoint, method = 'GET', body = null) => {
    const token = localStorage.getItem('token');
    const headers = {
        'Content-Type': 'application/json'
    };
    
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    
    const config = {
        method,
        headers
    };
    
    if (body) {
        config.body = JSON.stringify(body);
    }
    
    const response = await fetch(`http://localhost:8081/api${endpoint}`, config);
    
    if (response.status === 401) {
        // Token expired, redirect to login
        localStorage.clear();
        window.location.href = '/login';
        return;
    }
    
    return response.json();
};
```

#### 3. Role-based UI Components
```javascript
// Check user permissions
const hasPermission = (permission) => {
    const permissions = JSON.parse(localStorage.getItem('permissions') || '{}');
    return permissions[permission] === true;
};

// Example usage in React/Vue/Angular
const AdminPanel = () => {
    if (!hasPermission('canViewAllUsers')) {
        return <div>Access denied</div>;
    }
    
    return (
        <div>
            {/* Admin content */}
        </div>
    );
};
```

### Recommended Frontend Structure
```
frontend/
├── src/
│   ├── api/
│   │   ├── auth.js              # Authentication API calls
│   │   ├── users.js             # User management API calls
│   │   ├── activities.js        # Activity tracking API calls
│   │   └── analytics.js         # Analytics API calls
│   ├── components/
│   │   ├── auth/
│   │   │   ├── Login.jsx        # Login component
│   │   │   └── Register.jsx     # Registration component
│   │   ├── dashboard/
│   │   │   ├── Dashboard.jsx    # Main dashboard
│   │   │   └── Analytics.jsx    # Analytics view
│   │   └── admin/
│   │       ├── UserManagement.jsx
│   │       └── SystemSettings.jsx
│   ├── utils/
│   │   ├── auth.js              # Authentication utilities
│   │   ├── permissions.js       # Permission checking
│   │   └── api.js               # API utilities
│   └── store/                   # State management
```

### Error Handling
```javascript
// Standard error responses
const handleApiError = (error, response) => {
    if (response.status === 401) {
        return 'Authentication required';
    } else if (response.status === 403) {
        return 'Access denied';
    } else if (response.status === 404) {
        return 'Resource not found';
    } else if (response.status >= 500) {
        return 'Server error';
    }
    return 'Unknown error occurred';
};
```

### WebSocket Integration (Future Enhancement)
For real-time features:
```javascript
// WebSocket connection for real-time updates
const ws = new WebSocket('ws://localhost:8081/ws');
ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    // Handle real-time updates
};
```

---

## Additional Resources

### Documentation Files
- `api-documentation.md`: Detailed API documentation
- `POSTMAN_TEST_CREDENTIALS.md`: Test credentials and examples
- `postman/POSTMAN_SETUP_GUIDE.md`: Postman testing guide

### Scripts
- `test-role-authentication.ps1`: PowerShell authentication tests
- `simple-auth-test.ps1`: Simple API tests
- `curl-auth-test.ps1`: Curl-style API tests

### Postman Collection
- `postman/Role-Based-Auth-Collection.json`: Complete test collection
- `postman/Role-Based-Auth-Environment.json`: Environment variables

---

This documentation provides a comprehensive guide for developing a frontend application that integrates with the Employee Productivity Tracking Backend system. The system is designed to be RESTful, secure, and scalable, with clear separation of concerns and role-based access control.
