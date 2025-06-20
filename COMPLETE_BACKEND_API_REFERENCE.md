# Complete Backend API Reference

## 📋 Table of Contents
1. [Authentication APIs](#authentication-apis)
2. [User Management APIs](#user-management-apis)
3. [Activity Tracking APIs](#activity-tracking-apis)
4. [Task Management APIs](#task-management-apis)
5. [Admin APIs](#admin-apis)
6. [Process Tracking APIs](#process-tracking-apis)
7. [Analytics APIs](#analytics-apis)
8. [API Response Formats](#api-response-formats)
9. [Error Handling](#error-handling)
10. [Authentication & Authorization](#authentication--authorization)

---

## 🔐 Authentication APIs

### Login
**POST** `/api/auth/login`

**Description**: Authenticate user and return JWT token

**Request Body**:
```json
{
    "username": "string",
    "password": "string"
}
```

**Response**:
```json
{
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 1,
        "username": "admin",
        "email": "admin@company.com",
        "role": "ROLE_ADMIN",
        "active": true
    }
}
```

**Status Codes**:
- `200 OK`: Login successful
- `401 Unauthorized`: Invalid credentials
- `400 Bad Request`: Missing required fields

---

### Logout
**POST** `/api/auth/logout`

**Description**: Invalidate current JWT token

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
    "message": "Logout successful"
}
```

**Status Codes**:
- `200 OK`: Logout successful
- `401 Unauthorized`: Invalid or expired token

---

## 👥 User Management APIs

### Get Current User Profile
**GET** `/api/users/profile`

**Description**: Get current authenticated user's profile

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
    "id": 1,
    "username": "john_doe",
    "email": "john@company.com",
    "role": "ROLE_EMPLOYEE",
    "active": true,
    "createdAt": "2025-01-15T10:30:00Z"
}
```

---

### Update User Profile
**PUT** `/api/users/profile`

**Description**: Update current user's profile information

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
    "email": "newemail@company.com",
    "currentPassword": "oldpassword",
    "newPassword": "newpassword" // Optional
}
```

**Response**:
```json
{
    "id": 1,
    "username": "john_doe",
    "email": "newemail@company.com",
    "role": "ROLE_EMPLOYEE",
    "active": true,
    "updatedAt": "2025-06-20T14:30:00Z"
}
```

**Status Codes**:
- `200 OK`: Profile updated successfully
- `400 Bad Request`: Invalid input data
- `401 Unauthorized`: Invalid current password
- `409 Conflict`: Email already exists

---

### Get All Users (Admin Only)
**GET** `/api/users/all`

**Description**: Get list of all users in the system

**Headers**: `Authorization: Bearer <admin_token>`

**Query Parameters**:
- `page` (optional): Page number (default: 0)
- `size` (optional): Page size (default: 20)
- `role` (optional): Filter by role
- `active` (optional): Filter by active status

**Response**:
```json
{
    "content": [
        {
            "id": 1,
            "username": "admin",
            "email": "admin@company.com",
            "role": "ROLE_ADMIN",
            "active": true,
            "createdAt": "2025-01-01T00:00:00Z"
        },
        {
            "id": 2,
            "username": "john_doe",
            "email": "john@company.com",
            "role": "ROLE_EMPLOYEE",
            "active": true,
            "createdAt": "2025-01-15T10:30:00Z"
        }
    ],
    "totalElements": 67,
    "totalPages": 4,
    "size": 20,
    "number": 0
}
```

---

### Create User (Admin Only)
**POST** `/api/users`

**Description**: Create a new user account

**Headers**: `Authorization: Bearer <admin_token>`

**Request Body**:
```json
{
    "username": "new_employee",
    "email": "employee@company.com",
    "password": "temporaryPassword123",
    "role": "ROLE_EMPLOYEE"
}
```

**Response**:
```json
{
    "id": 68,
    "username": "new_employee",
    "email": "employee@company.com",
    "role": "ROLE_EMPLOYEE",
    "active": true,
    "createdAt": "2025-06-20T15:00:00Z"
}
```

---

### Update User (Admin Only)
**PUT** `/api/users/{userId}`

**Description**: Update user account information

**Headers**: `Authorization: Bearer <admin_token>`

**Path Parameters**:
- `userId`: User ID to update

**Request Body**:
```json
{
    "email": "updated@company.com",
    "role": "ROLE_MANAGER",
    "active": true
}
```

---

### Delete User (Admin Only)
**DELETE** `/api/users/{userId}`

**Description**: Deactivate or delete user account

**Headers**: `Authorization: Bearer <admin_token>`

**Path Parameters**:
- `userId`: User ID to delete

**Response**:
```json
{
    "message": "User deleted successfully"
}
```

---

## 📊 Activity Tracking APIs

### Log Activity
**POST** `/api/activities/log`

**Description**: Log a new activity for the current user

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
    "activityType": "APPLICATION_USAGE",
    "applicationName": "Microsoft Word",
    "applicationCategory": "Productivity",
    "processName": "WINWORD.EXE",
    "processId": "1234",
    "machineId": "DESKTOP-ABC123",
    "windowTitle": "Document1 - Microsoft Word",
    "description": "Working on project documentation",
    "startTime": "2025-06-20T09:00:00Z",
    "endTime": "2025-06-20T09:30:00Z",
    "durationSeconds": 1800,
    "idleTimeSeconds": 120,
    "workspaceType": "OFFICE",
    "ipAddress": "192.168.1.100"
}
```

**Response**:
```json
{
    "id": 25253,
    "userId": 1,
    "activityType": "APPLICATION_USAGE",
    "applicationName": "Microsoft Word",
    "applicationCategory": "Productivity",
    "processName": "WINWORD.EXE",
    "processId": "1234",
    "machineId": "DESKTOP-ABC123",
    "windowTitle": "Document1 - Microsoft Word",
    "description": "Working on project documentation",
    "startTime": "2025-06-20T09:00:00Z",
    "endTime": "2025-06-20T09:30:00Z",
    "durationSeconds": 1800,
    "idleTimeSeconds": 120,
    "activityStatus": "COMPLETED",
    "workspaceType": "OFFICE",
    "ipAddress": "192.168.1.100",
    "createdAt": "2025-06-20T15:30:00Z",
    "version": 1,
    "hashValue": "abc123def456",
    "tamperAttempt": false,
    "tamperDetails": null
}
```

---

### Get User Activities
**GET** `/api/activities/user/{userId}`

**Description**: Get activities for a specific user

**Headers**: `Authorization: Bearer <token>`

**Path Parameters**:
- `userId`: User ID (employees can only access their own activities)

**Query Parameters**:
- `page` (optional): Page number (default: 0)
- `size` (optional): Page size (default: 20)
- `startDate` (optional): Filter from date (YYYY-MM-DD)
- `endDate` (optional): Filter to date (YYYY-MM-DD)
- `activityType` (optional): Filter by activity type
- `applicationName` (optional): Filter by application name

**Response**:
```json
{
    "content": [
        {
            "id": 25253,
            "userId": 1,
            "activityType": "APPLICATION_USAGE",
            "applicationName": "Microsoft Word",
            "startTime": "2025-06-20T09:00:00Z",
            "endTime": "2025-06-20T09:30:00Z",
            "durationSeconds": 1800,
            "activityStatus": "COMPLETED"
        }
    ],
    "totalElements": 156,
    "totalPages": 8,
    "size": 20,
    "number": 0
}
```

---

### Get My Activities
**GET** `/api/activities/my`

**Description**: Get activities for the current authenticated user

**Headers**: `Authorization: Bearer <token>`

**Query Parameters**: Same as above

---

### Get Activity Details
**GET** `/api/activities/{activityId}`

**Description**: Get detailed information about a specific activity

**Headers**: `Authorization: Bearer <token>`

**Path Parameters**:
- `activityId`: Activity ID

**Response**:
```json
{
    "id": 25253,
    "userId": 1,
    "activityType": "APPLICATION_USAGE",
    "applicationName": "Microsoft Word",
    "applicationCategory": "Productivity",
    "processName": "WINWORD.EXE",
    "processId": "1234",
    "machineId": "DESKTOP-ABC123",
    "windowTitle": "Document1 - Microsoft Word",
    "description": "Working on project documentation",
    "startTime": "2025-06-20T09:00:00Z",
    "endTime": "2025-06-20T09:30:00Z",
    "durationSeconds": 1800,
    "idleTimeSeconds": 120,
    "activityStatus": "COMPLETED",
    "workspaceType": "OFFICE",
    "ipAddress": "192.168.1.100",
    "createdAt": "2025-06-20T15:30:00Z",
    "version": 1,
    "hashValue": "abc123def456",
    "tamperAttempt": false,
    "tamperDetails": null
}
```

---

### Update Activity
**PUT** `/api/activities/{activityId}`

**Description**: Update activity information (limited fields)

**Headers**: `Authorization: Bearer <token>`

**Path Parameters**:
- `activityId`: Activity ID

**Request Body**:
```json
{
    "description": "Updated description",
    "activityStatus": "COMPLETED"
}
```

---

### Delete Activity
**DELETE** `/api/activities/{activityId}`

**Description**: Delete an activity (admin only or own activities)

**Headers**: `Authorization: Bearer <token>`

**Path Parameters**:
- `activityId`: Activity ID

---

## 📋 Task Management APIs

### Get Tasks
**GET** `/api/tasks`

**Description**: Get list of tasks

**Headers**: `Authorization: Bearer <token>`

**Query Parameters**:
- `page` (optional): Page number (default: 0)
- `size` (optional): Page size (default: 20)
- `assignedTo` (optional): Filter by assigned user ID
- `status` (optional): Filter by task status
- `priority` (optional): Filter by priority

**Response**:
```json
{
    "content": [
        {
            "id": 1,
            "title": "Complete Project Documentation",
            "description": "Write comprehensive documentation for the new feature",
            "assignedTo": 2,
            "assignedBy": 1,
            "status": "IN_PROGRESS",
            "priority": "HIGH",
            "dueDate": "2025-06-25T17:00:00Z",
            "createdAt": "2025-06-20T10:00:00Z",
            "updatedAt": "2025-06-20T14:30:00Z"
        }
    ],
    "totalElements": 45,
    "totalPages": 3,
    "size": 20,
    "number": 0
}
```

---

### Create Task
**POST** `/api/tasks`

**Description**: Create a new task

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
    "title": "New Task",
    "description": "Task description",
    "assignedTo": 2,
    "priority": "MEDIUM",
    "dueDate": "2025-06-30T17:00:00Z"
}
```

---

### Update Task
**PUT** `/api/tasks/{taskId}`

**Description**: Update task information

**Headers**: `Authorization: Bearer <token>`

**Path Parameters**:
- `taskId`: Task ID

**Request Body**:
```json
{
    "title": "Updated Task Title",
    "description": "Updated description",
    "status": "COMPLETED",
    "priority": "HIGH"
}
```

---

### Delete Task
**DELETE** `/api/tasks/{taskId}`

**Description**: Delete a task

**Headers**: `Authorization: Bearer <token>`

**Path Parameters**:
- `taskId`: Task ID

---

## 🔧 Admin APIs

### System Statistics
**GET** `/api/admin/stats`

**Description**: Get system-wide statistics

**Headers**: `Authorization: Bearer <admin_token>`

**Response**:
```json
{
    "totalUsers": 67,
    "activeUsers": 65,
    "totalActivities": 12469,
    "activitiesToday": 245,
    "totalTasks": 45,
    "completedTasks": 23,
    "systemUptime": "15 days, 4 hours",
    "databaseHealth": "HEALTHY",
    "lastBackup": "2025-06-20T02:00:00Z"
}
```

---

### Get Orphaned Activities
**GET** `/api/admin/orphaned-activities`

**Description**: Check for orphaned activities (should be 0 after fix)

**Headers**: `Authorization: Bearer <admin_token>`

**Response**:
```json
{
    "count": 0,
    "activities": []
}
```

---

### Clean Orphaned Activities
**DELETE** `/api/admin/orphaned-activities`

**Description**: Remove any orphaned activities found

**Headers**: `Authorization: Bearer <admin_token>`

**Response**:
```json
{
    "message": "No orphaned activities found",
    "deletedCount": 0
}
```

---

### System Health Check
**GET** `/api/admin/health`

**Description**: Check system health status

**Headers**: `Authorization: Bearer <admin_token>`

**Response**:
```json
{
    "status": "HEALTHY",
    "database": "CONNECTED",
    "memoryUsage": "512MB / 2GB",
    "diskSpace": "45GB / 100GB",
    "activeConnections": 15,
    "uptime": "15 days, 4 hours, 23 minutes"
}
```

---

## 🔄 Process Tracking APIs

### Log Process
**POST** `/api/process-tracks`

**Description**: Log process tracking information

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
    "processName": "chrome.exe",
    "processId": "5678",
    "machineId": "DESKTOP-ABC123",
    "startTime": "2025-06-20T09:00:00Z",
    "endTime": "2025-06-20T17:00:00Z",
    "memoryUsage": 512000,
    "cpuUsage": 25.5
}
```

---

### Get Process Tracks
**GET** `/api/process-tracks`

**Description**: Get process tracking data

**Headers**: `Authorization: Bearer <token>`

**Query Parameters**:
- `page`, `size`: Pagination
- `processName`: Filter by process name
- `startDate`, `endDate`: Date range filter

---

## 📈 Analytics APIs

### User Activity Summary
**GET** `/api/analytics/user-summary/{userId}`

**Description**: Get activity summary for a user

**Headers**: `Authorization: Bearer <token>`

**Path Parameters**:
- `userId`: User ID

**Query Parameters**:
- `period`: TIME_PERIOD (DAY, WEEK, MONTH, YEAR)
- `startDate`, `endDate`: Custom date range

**Response**:
```json
{
    "userId": 1,
    "period": "WEEK",
    "totalActivities": 156,
    "totalDuration": 28800,
    "averageDailyDuration": 4114,
    "topApplications": [
        {
            "name": "Microsoft Word",
            "duration": 7200,
            "percentage": 25.0
        },
        {
            "name": "Google Chrome",
            "duration": 5400,
            "percentage": 18.75
        }
    ],
    "activityByDay": [
        {
            "date": "2025-06-14",
            "activities": 23,
            "duration": 4200
        }
    ]
}
```

---

### Team Productivity Report
**GET** `/api/analytics/team-productivity`

**Description**: Get team-wide productivity metrics

**Headers**: `Authorization: Bearer <admin_token>`

**Query Parameters**:
- `period`: TIME_PERIOD
- `teamId` (optional): Filter by team

**Response**:
```json
{
    "period": "MONTH",
    "totalTeamMembers": 10,
    "totalActivities": 2340,
    "averageProductivityScore": 78.5,
    "topPerformers": [
        {
            "userId": 5,
            "username": "alice_smith",
            "productivityScore": 92.3,
            "totalDuration": 86400
        }
    ],
    "departmentBreakdown": [
        {
            "department": "Engineering",
            "members": 6,
            "avgProductivity": 85.2
        }
    ]
}
```

---

## 📋 API Response Formats

### Success Response
```json
{
    "success": true,
    "data": { /* actual response data */ },
    "message": "Operation completed successfully",
    "timestamp": "2025-06-20T15:30:00Z"
}
```

### Error Response
```json
{
    "success": false,
    "error": {
        "code": "USER_NOT_FOUND",
        "message": "User with ID 99999 not found",
        "details": "The specified user ID does not exist in the system"
    },
    "timestamp": "2025-06-20T15:30:00Z"
}
```

### Paginated Response
```json
{
    "content": [ /* array of items */ ],
    "pageable": {
        "sort": {
            "sorted": true,
            "empty": false
        },
        "pageNumber": 0,
        "pageSize": 20,
        "offset": 0,
        "paged": true,
        "unpaged": false
    },
    "totalElements": 156,
    "totalPages": 8,
    "last": false,
    "first": true,
    "numberOfElements": 20,
    "size": 20,
    "number": 0,
    "sort": {
        "sorted": true,
        "empty": false
    },
    "empty": false
}
```

---

## ⚠️ Error Handling

### HTTP Status Codes

| Status Code | Description | When Used |
|-------------|-------------|-----------|
| 200 OK | Success | Successful GET, PUT requests |
| 201 Created | Resource created | Successful POST requests |
| 204 No Content | Success, no content | Successful DELETE requests |
| 400 Bad Request | Invalid input | Validation errors, malformed requests |
| 401 Unauthorized | Authentication required | Missing or invalid token |
| 403 Forbidden | Access denied | Insufficient permissions |
| 404 Not Found | Resource not found | Non-existent resources |
| 409 Conflict | Conflict with current state | Duplicate entries, constraint violations |
| 422 Unprocessable Entity | Validation failed | Business logic validation errors |
| 500 Internal Server Error | Server error | Unexpected server errors |

### Common Error Codes

| Error Code | Description |
|------------|-------------|
| `INVALID_CREDENTIALS` | Login failed due to wrong username/password |
| `TOKEN_EXPIRED` | JWT token has expired |
| `TOKEN_INVALID` | JWT token is malformed or invalid |
| `USER_NOT_FOUND` | Specified user does not exist |
| `ACCESS_DENIED` | User doesn't have permission for this action |
| `VALIDATION_ERROR` | Input validation failed |
| `DUPLICATE_ENTRY` | Resource already exists |
| `ORPHANED_ACTIVITY` | Activity references non-existent user |
| `DATABASE_ERROR` | Database operation failed |
| `SYSTEM_ERROR` | Unexpected system error |

---

## 🔐 Authentication & Authorization

### JWT Token Structure
```
Header: {
    "alg": "HS256",
    "typ": "JWT"
}

Payload: {
    "sub": "username",
    "userId": 1,
    "role": "ROLE_ADMIN",
    "iat": 1718900000,
    "exp": 1718986400
}
```

### Authorization Levels

| Role | Permissions |
|------|-------------|
| `ROLE_ADMIN` | Full system access, user management, system stats |
| `ROLE_MANAGER` | Team management, team reports, task assignment |
| `ROLE_EMPLOYEE` | Own profile, own activities, assigned tasks |

### Protected Endpoints

- **Admin Only**: `/api/admin/*`, `/api/users/all`, user CRUD operations
- **Manager+**: Team reports, task management
- **Authenticated**: Activity logging, profile management, own data access

---

## 🌐 Base URL & Environment

- **Development**: `http://localhost:8080`
- **Production**: `https://api.company.com`

### Request Headers
```
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>
Accept: application/json
```

### Rate Limiting
- General APIs: 100 requests/minute per user
- Authentication: 10 requests/minute per IP
- Admin APIs: 200 requests/minute

---

*This documentation covers all available backend APIs as of June 20, 2025. For the latest updates and workflow information, see the companion document: BACKEND_SYSTEM_WORKFLOWS.md*
