# Complete Backend API Documentation

## Overview
This document provides comprehensive documentation for the Backend Application API, including all endpoints for user management, authentication, activity tracking, process monitoring, analytics, and system administration.

## Base URL
```
http://localhost:8080/api
```

## Authentication
Most endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

## Response Format
All API responses follow a consistent JSON format:
```json
{
  "data": {},
  "message": "Success message",
  "error": "Error message (if applicable)",
  "timestamp": "2024-01-01T12:00:00"
}
```

---

## 1. User Management & Authentication

### 1.1 User Registration
**POST** `/users/register`

Register a new user in the system.

**Request Body:**
```json
{
  "username": "employee123",
  "email": "employee@company.com",
  "password": "securePassword123",
  "role": "EMPLOYEE"
}
```

**Response:**
```json
{
  "id": 1,
  "username": "employee123",
  "email": "employee@company.com",
  "role": "EMPLOYEE",
  "active": true
}
```

**Possible Roles:**
- `EMPLOYEE` - Regular employee user
- `ADMIN` - Administrator user
- `SUPERADMIN` - Super administrator user

### 1.2 User Login
**POST** `/users/login`

Authenticate user and receive JWT token.

**Request Body:**
```json
{
  "username": "employee123",
  "password": "securePassword123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": 1,
  "role": "EMPLOYEE",
  "username": "employee123",
  "email": "employee@company.com",
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

### 1.3 Get User Profile
**GET** `/users/profile`

Get current user's profile information.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "id": 1,
  "username": "employee123",
  "email": "employee@company.com",
  "role": "EMPLOYEE",
  "active": true,
  "createdAt": "2024-01-01T12:00:00"
}
```

### 1.4 Update User Profile
**PUT** `/users/profile`

Update current user's profile information.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "username": "newUsername",
  "email": "newemail@company.com"
}
```

**Response:**
```json
{
  "id": 1,
  "username": "newUsername",
  "email": "newemail@company.com",
  "role": "EMPLOYEE",
  "active": true,
  "message": "Profile updated successfully"
}
```

**Note:** Email uniqueness is validated. The system will prevent duplicate emails.

### 1.5 List All Users (Admin Only)
**GET** `/users/all`

Get paginated list of all users with filtering options.

**Query Parameters:**
- `role` (optional): Filter by role (EMPLOYEE, ADMIN, SUPERADMIN)
- `active` (optional): Filter by active status (true/false)
- `page` (optional): Page number (default: 0)
- `size` (optional): Page size (default: 20)

**Example:** `/users/all?role=EMPLOYEE&active=true&page=0&size=10`

**Response:**
```json
{
  "users": [
    {
      "id": 1,
      "username": "employee123",
      "email": "employee@company.com",
      "role": "EMPLOYEE",
      "active": true,
      "createdAt": "2024-01-01T12:00:00"
    }
  ],
  "totalUsers": 1,
  "currentPage": 0,
  "totalPages": 1
}
```

### 1.6 Find User by Email
**GET** `/users/email/{email}`

Find a user by their email address.

**Response:**
```json
{
  "id": 1,
  "username": "employee123",
  "email": "employee@company.com",
  "role": "EMPLOYEE",
  "active": true,
  "createdAt": "2024-01-01T12:00:00"
}
```

### 1.7 Update User (Admin Only)
**PUT** `/users/{id}`

Update user details by ID.

**Request Body:**
```json
{
  "username": "updatedUsername",
  "email": "updated@company.com",
  "role": "ADMIN",
  "active": true
}
```

### 1.8 Change User Password
**PUT** `/users/{id}/change-password`

Change user's password.

**Request Body:**
```json
{
  "newPassword": "newSecurePassword123"
}
```

### 1.9 Deactivate User (Admin Only)
**POST** `/users/deactivate/{id}`

Deactivate a user account.

**Response:**
```json
{
  "message": "User deactivated successfully"
}
```

### 1.10 Delete User (Admin Only)
**DELETE** `/users/{id}`

Permanently delete a user.

**Response:**
```json
{
  "message": "User deleted successfully"
}
```

---

## 2. Activity Tracking & Monitoring

### 2.1 Log Activity
**POST** `/activities/log`

Log a new activity for a user.

**Request Body:**
```json
{
  "userId": 1,
  "activityType": "APPLICATION_USAGE",
  "description": "Working on documents",
  "applicationName": "Microsoft Word",
  "processName": "WINWORD.EXE",
  "windowTitle": "Document1 - Word",
  "startTime": "2024-01-01T09:00:00",
  "endTime": "2024-01-01T10:00:00",
  "durationSeconds": 3600,
  "status": "ACTIVE",
  "workspaceType": "OFFICE",
  "applicationCategory": "PRODUCTIVITY"
}
```

### 2.2 Get Today's Activities
**GET** `/activities/today`

Get all activities for today for a specific user.

**Query Parameters:**
- `userId`: User ID (required)

**Response:**
```json
[
  {
    "id": 1,
    "userId": 1,
    "activityType": "APPLICATION_USAGE",
    "description": "Working on documents",
    "applicationName": "Microsoft Word",
    "processName": "WINWORD.EXE",
    "windowTitle": "Document1 - Word",
    "startTime": "2024-01-01T09:00:00",
    "endTime": "2024-01-01T10:00:00",
    "durationSeconds": 3600,
    "status": "COMPLETED",
    "workspaceType": "OFFICE",
    "applicationCategory": "PRODUCTIVITY",
    "createdAt": "2024-01-01T09:00:00"
  }
]
```

### 2.3 Get Application Usage
**GET** `/activities/application-usage`

Get daily application usage statistics for a user.

**Query Parameters:**
- `userId`: User ID (required)

**Response:**
```json
{
  "totalApplications": 5,
  "totalDuration": 28800,
  "applications": [
    {
      "applicationName": "Microsoft Word",
      "totalDuration": 7200,
      "percentage": 25.0,
      "category": "PRODUCTIVITY"
    },
    {
      "applicationName": "Google Chrome",
      "totalDuration": 10800,
      "percentage": 37.5,
      "category": "BROWSER"
    }
  ]
}
```

### 2.4 Get Productive Time
**GET** `/activities/productive-time`

Get productive time statistics for today.

**Query Parameters:**
- `userId`: User ID (required)

**Response:**
```json
{
  "totalTimeMinutes": 480,
  "productiveTimeMinutes": 360,
  "productivityPercentage": 75.0,
  "categories": {
    "PRODUCTIVITY": 180,
    "COMMUNICATION": 120,
    "DEVELOPMENT": 60,
    "OTHER": 120
  }
}
```

### 2.5 Get All Activities (with Filtering & Pagination)
**GET** `/activities/all`

Get paginated list of activities with filtering options.

**Query Parameters:**
- `userId` (optional): Filter by user ID
- `activityType` (optional): Filter by activity type
- `applicationCategory` (optional): Filter by application category
- `page` (optional): Page number (default: 0)
- `size` (optional): Page size (default: 10)
- `sortBy` (optional): Sort field (default: "createdAt")
- `sortDirection` (optional): Sort direction (asc/desc, default: "desc")

**Example:** `/activities/all?userId=1&applicationCategory=PRODUCTIVITY&page=0&size=20`

**Response:**
```json
{
  "activities": [
    {
      "id": 1,
      "userId": 1,
      "activityType": "APPLICATION_USAGE",
      "description": "Working on documents",
      "applicationName": "Microsoft Word",
      "processName": "WINWORD.EXE",
      "windowTitle": "Document1 - Word",
      "startTime": "2024-01-01T09:00:00",
      "endTime": "2024-01-01T10:00:00",
      "durationSeconds": 3600,
      "status": "COMPLETED",
      "workspaceType": "OFFICE",
      "applicationCategory": "PRODUCTIVITY",
      "createdAt": "2024-01-01T09:00:00"
    }
  ],
  "currentPage": 0,
  "totalItems": 1,
  "totalPages": 1,
  "timestamp": "2024-01-01T12:00:00"
}
```

### 2.6 Get Activity Details
**GET** `/activities/details/{id}`

Get detailed information about a specific activity by its ID.

**Path Parameters:**
- `id`: Activity ID (required) - The unique identifier of the activity

**Headers:** `Authorization: Bearer <token>` (required)

**Example Request:**
```
GET /api/activities/details/20047
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200 OK):**
```json
{
  "id": 20047,
  "userId": 1,
  "activityType": "APPLICATION_USAGE",
  "description": "Working on documents",
  "applicationName": "Microsoft Word",
  "processName": "WINWORD.EXE",
  "windowTitle": "Document1 - Word",
  "startTime": "2024-01-01T09:00:00",
  "endTime": "2024-01-01T10:00:00",
  "durationSeconds": 3600,
  "status": "COMPLETED",
  "workspaceType": "OFFICE",
  "applicationCategory": "PRODUCTIVITY"
}
```

**Error Responses:**

**404 Not Found:**
```json
{
  "error": "Activity not found"
}
```

**403 Forbidden:**
```json
{
  "error": "Access denied - Authentication required"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Failed to retrieve activity details: <error_message>"
}
```

**Notes:**
- This endpoint requires authentication via JWT token
- Users can only access activities they have permission to view
- Admin users can access all activities
- The activity ID must be a valid Long integer

### 2.7 Get Activity Summary
**GET** `/activities/summary`

Get activity summary for a date range.

**Query Parameters:**
- `userId`: User ID (required)
- `startDate`: Start date (ISO format, required)
- `endDate`: End date (ISO format, required)

**Example:** `/activities/summary?userId=1&startDate=2024-01-01T00:00:00&endDate=2024-01-31T23:59:59`

**Response:**
```json
{
  "totalActivities": 150,
  "totalDuration": 432000,
  "averageDurationPerActivity": 2880,
  "productivityScore": 78.5,
  "categoryBreakdown": {
    "PRODUCTIVITY": 45,
    "COMMUNICATION": 30,
    "DEVELOPMENT": 25,
    "OTHER": 50
  },
  "dailyAverages": {
    "activitiesPerDay": 5,
    "durationPerDay": 14400
  }
}
```

### 2.8 Get Activity Statistics
**GET** `/activities/stats`

Get comprehensive activity statistics for a date range.

**Query Parameters:**
- `userId`: User ID (required)
- `startDate`: Start date (ISO format, required)
- `endDate`: End date (ISO format, required)

**Response:**
```json
{
  "totalActivities": 150,
  "byCategory": {
    "PRODUCTIVITY": 45,
    "COMMUNICATION": 30,
    "DEVELOPMENT": 25,
    "OTHER": 50
  },
  "byStatus": {
    "COMPLETED": 120,
    "ACTIVE": 20,
    "PAUSED": 10
  },
  "totalDuration": 432000,
  "timeRange": {
    "start": "2024-01-01T00:00:00",
    "end": "2024-01-31T23:59:59"
  }
}
```

### 2.9 Get Application Categories
**GET** `/activities/categories`

Get application usage grouped by categories.

**Query Parameters:**
- `userId`: User ID (required)

**Response:**
```json
{
  "categories": [
    {
      "category": "PRODUCTIVITY",
      "applications": [
        {
          "name": "Microsoft Word",
          "duration": 7200,
          "percentage": 25.0
        },
        {
          "name": "Microsoft Excel",
          "duration": 3600,
          "percentage": 12.5
        }
      ],
      "totalDuration": 10800,
      "percentage": 37.5
    }
  ]
}
```

### 2.10 Get Current Status
**GET** `/activities/status`

Get current activity status for a user.

**Query Parameters:**
- `userId`: User ID (required)

**Response:**
```json
{
  "status": "ACTIVE",
  "lastActive": "2024-01-01T12:00:00"
}
```

### 2.11 Get Security Tamper Report (Admin Only)
**GET** `/activities/security/tamper-report`

Get detailed security and tamper report for a user.

**Query Parameters:**
- `userId`: User ID (required)
- `startDate`: Start date (ISO format, required)
- `endDate`: End date (ISO format, required)

**Response:**
```json
{
  "userId": 1,
  "reportPeriod": {
    "start": "2024-01-01T00:00:00",
    "end": "2024-01-31T23:59:59"
  },
  "totalActivities": 150,
  "suspiciousActivities": 5,
  "securityFlags": [
    {
      "type": "UNUSUAL_ACTIVITY_PATTERN",
      "description": "Unusual late-night activity detected",
      "timestamp": "2024-01-15T23:30:00"
    }
  ],
  "productivityScore": 78.5,
  "complianceScore": 92.0
}
```

### 2.12 Clear Activities (Admin Only)
**DELETE** `/activities/clear`

Clear all activities for a specific user.

**Query Parameters:**
- `userId`: User ID (required)

**Response:**
```json
{
  "message": "Activities cleared successfully"
}
```

---

## 3. Process Tracking

### 3.1 Log Process
**POST** `/process-tracking/log`

Log a new process tracking entry.

**Request Body:**
```json
{
  "userId": 1,
  "processName": "WINWORD.EXE",
  "windowTitle": "Document1 - Word",
  "processId": "1234",
  "applicationPath": "C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE",
  "startTime": "2024-01-01T09:00:00",
  "endTime": "2024-01-01T10:00:00",
  "durationSeconds": 3600,
  "category": "PRODUCTIVITY",
  "isProductiveApp": true
}
```

**Response:**
```json
{
  "id": 1,
  "userId": 1,
  "processName": "WINWORD.EXE",
  "windowTitle": "Document1 - Word",
  "processId": "1234",
  "applicationPath": "C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE",
  "startTime": "2024-01-01T09:00:00",
  "endTime": "2024-01-01T10:00:00",
  "durationSeconds": 3600,
  "category": "PRODUCTIVITY",
  "isProductiveApp": true,
  "createdAt": "2024-01-01T09:00:00"
}
```

### 3.2 Get Process Analytics
**GET** `/process-tracking/analytics`

Get process analytics for a user within a date range.

**Query Parameters:**
- `userId`: User ID (required)
- `startDate`: Start date (ISO format, required)
- `endDate`: End date (ISO format, required)

**Example:** `/process-tracking/analytics?userId=1&startDate=2024-01-01T00:00:00&endDate=2024-01-31T23:59:59`

**Response:**
```json
{
  "userId": 1,
  "timeRange": {
    "start": "2024-01-01T00:00:00",
    "end": "2024-01-31T23:59:59"
  },
  "totalProcesses": 50,
  "uniqueProcesses": 15,
  "totalDuration": 720000,
  "productiveTime": 540000,
  "productivityRatio": 75.0,
  "topProcesses": [
    {
      "processName": "WINWORD.EXE",
      "totalDuration": 180000,
      "percentage": 25.0,
      "category": "PRODUCTIVITY"
    },
    {
      "processName": "chrome.exe",
      "totalDuration": 144000,
      "percentage": 20.0,
      "category": "BROWSER"
    }
  ],
  "categoryBreakdown": {
    "PRODUCTIVITY": 45.0,
    "BROWSER": 30.0,
    "COMMUNICATION": 15.0,
    "OTHER": 10.0
  },
  "dailyAverages": {
    "processesPerDay": 1.6,
    "durationPerDay": 23226.0
  }
}
```

---

## 4. Analytics

### 4.1 Get Productivity Analytics
**GET** `/analytics/productivity`

Get comprehensive productivity analytics for a user.

**Query Parameters:**
- `userId`: User ID (required)
- `startDate`: Start date (ISO format, required)
- `endDate`: End date (ISO format, required)

**Response:**
```json
{
  "userId": 1,
  "timeRange": {
    "start": "2024-01-01T00:00:00",
    "end": "2024-01-31T23:59:59"
  },
  "overallProductivity": {
    "score": 78.5,
    "grade": "B+",
    "trend": "IMPROVING"
  },
  "timeDistribution": {
    "productiveTime": 432000,
    "neutralTime": 86400,
    "distractiveTime": 43200,
    "totalTime": 561600
  },
  "dailyPatterns": [
    {
      "date": "2024-01-01",
      "productivityScore": 85.0,
      "totalWorkTime": 28800,
      "productiveTime": 24480
    }
  ],
  "recommendations": [
    "Consider taking more breaks during long work sessions",
    "Focus time is highest between 9 AM - 12 PM"
  ]
}
```

### 4.2 Get Task Completion Analytics
**GET** `/analytics/task-completion`

Get task completion analytics for a user.

**Query Parameters:**
- `userId`: User ID (required)
- `startDate`: Start date (ISO format, required)
- `endDate`: End date (ISO format, required)

**Response:**
```json
{
  "userId": 1,
  "timeRange": {
    "start": "2024-01-01T00:00:00",
    "end": "2024-01-31T23:59:59"
  },
  "taskMetrics": {
    "totalTasks": 45,
    "completedTasks": 38,
    "completionRate": 84.4,
    "averageTaskDuration": 3600,
    "onTimeCompletion": 85.0
  },
  "categoryPerformance": [
    {
      "category": "PRODUCTIVITY",
      "completionRate": 90.0,
      "averageDuration": 4200
    },
    {
      "category": "COMMUNICATION",
      "completionRate": 78.0,
      "averageDuration": 1800
    }
  ],
  "trends": {
    "weeklyCompletion": [85.0, 88.0, 82.0, 90.0],
    "peakPerformanceHours": ["09:00", "10:00", "14:00", "15:00"]
  }
}
```

### 4.3 Get Workspace Analytics
**GET** `/analytics/workspace-comparison`

Get workspace usage analytics for a user.

**Query Parameters:**
- `userId`: User ID (required)
- `startDate`: Start date (ISO format, required)
- `endDate`: End date (ISO format, required)

**Response:**
```json
{
  "userId": 1,
  "timeRange": {
    "start": "2024-01-01T00:00:00",
    "end": "2024-01-31T23:59:59"
  },
  "workspaceUsage": [
    {
      "workspace": "OFFICE",
      "totalTime": 432000,
      "percentage": 75.0,
      "productivityScore": 85.0
    },
    {
      "workspace": "HOME",
      "totalTime": 144000,
      "percentage": 25.0,
      "productivityScore": 70.0
    }
  ],
  "comparison": {
    "mostProductiveWorkspace": "OFFICE",
    "preferredWorkspace": "OFFICE",
    "recommendations": [
      "Office environment shows higher productivity",
      "Consider optimizing home workspace setup"
    ]
  }
}
```

### 4.4 Get Efficiency Metrics
**GET** `/analytics/efficiency-metrics`

Get comprehensive efficiency metrics combining all analytics.

**Query Parameters:**
- `userId`: User ID (required)
- `startDate`: Start date (ISO format, required)
- `endDate`: End date (ISO format, required)

**Response:**
```json
{
  "tasks": {
    "totalTasks": 45,
    "completedTasks": 38,
    "completionRate": 84.4,
    "averageTaskDuration": 3600
  },
  "workspaces": {
    "workspaceUsage": [
      {
        "workspace": "OFFICE",
        "totalTime": 432000,
        "percentage": 75.0,
        "productivityScore": 85.0
      }
    ]
  },
  "productivity": {
    "overallScore": 78.5,
    "grade": "B+",
    "trend": "IMPROVING"
  }
}
```

---

## 5. Log Collection

### 5.1 Batch Log Collection
**POST** `/logs/batch`

Collect batch logs from client applications for processing.

**Request Body:**
```json
[
  {
    "userId": 1,
    "processName": "WINWORD.EXE",
    "windowTitle": "Document1 - Word",
    "processId": "1234",
    "applicationPath": "C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE",
    "startTime": "2024-01-01T09:00:00",
    "endTime": "2024-01-01T10:00:00",
    "durationSeconds": 3600,
    "category": "PRODUCTIVITY",
    "isProductiveApp": true,
    "activityType": "APPLICATION_USAGE",
    "description": "Working on documents",
    "workspaceType": "OFFICE",
    "applicationCategory": "PRODUCTIVITY"
  }
]
```

**Response:**
```json
{
  "status": "success",
  "processTracksQueued": 1,
  "activitiesQueued": 1
}
```

---

## 6. Admin Operations

### 6.1 Initialize Admin
**POST** `/admin/init`

Initialize the first admin user in the system.

**Request Body:**
```json
{
  "username": "admin",
  "email": "admin@company.com",
  "password": "adminPassword123"
}
```

**Response:**
```json
{
  "id": 1,
  "username": "admin",
  "email": "admin@company.com",
  "role": "ROLE_ADMIN",
  "active": true,
  "createdAt": "2024-01-01T12:00:00"
}
```

### 6.2 Get System Status (Admin Only)
**GET** `/admin/system/status`

Get comprehensive system status information.

**Headers:** `Authorization: Bearer <admin_token>`

**Response:**
```json
{
  "activeUsers": 25,
  "systemHealth": "OK",
  "lastBackup": "2024-01-01T12:00:00",
  "totalActivities": 5000,
  "serverTime": "2024-01-01T12:00:00",
  "version": "1.0.0"
}
```

### 6.3 Perform System Maintenance (Admin Only)
**POST** `/admin/system/maintenance`

Perform system maintenance operations.

**Headers:** `Authorization: Bearer <admin_token>`

**Response:**
```json
{
  "message": "Maintenance completed"
}
```

### 6.4 Purge User Data (Admin Only)
**DELETE** `/admin/users/{userId}/purge`

Completely remove all user data from the system.

**Headers:** `Authorization: Bearer <admin_token>`

**Response:**
```json
{
  "message": "User data purged"
}
```

---

## 7. Error Handling

### Common HTTP Status Codes

- **200 OK**: Request successful
- **201 Created**: Resource created successfully
- **400 Bad Request**: Invalid request data
- **401 Unauthorized**: Authentication required or invalid
- **403 Forbidden**: Access denied
- **404 Not Found**: Resource not found
- **409 Conflict**: Resource already exists (e.g., duplicate email)
- **500 Internal Server Error**: Server error

### Error Response Format

```json
{
  "error": "Detailed error message",
  "timestamp": "2024-01-01T12:00:00",
  "status": 400,
  "path": "/api/users/register"
}
```

---

## 8. Security Features

### JWT Token Security
- Tokens expire after 24 hours
- Tokens include user role and permissions
- Refresh tokens available for extended sessions

### Role-Based Access Control
- **EMPLOYEE**: Basic access to own data and tracking
- **ADMIN**: Full user management and system monitoring
- **SUPERADMIN**: Complete system control and admin management

### Data Validation
- Email uniqueness validation
- Password strength requirements
- Input sanitization for all endpoints

### Rate Limiting
- API endpoints are rate-limited to prevent abuse
- Different limits for different user roles

---

## 9. Performance Considerations

### Pagination
- All list endpoints support pagination
- Default page size: 10-20 items
- Maximum page size: 100 items

### Caching
- Frequently accessed data is cached
- Cache invalidation on data updates
- Analytics results cached for 15 minutes

### Database Optimization
- Indexed queries for better performance
- Batch operations for bulk data processing
- Connection pooling for database efficiency

---

## 10. Integration Examples

### Frontend Integration Example (JavaScript)

```javascript
// Login and get token
const loginResponse = await fetch('/api/users/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    username: 'employee123',
    password: 'password123'
  })
});

const loginData = await loginResponse.json();
const token = loginData.token;

// Use token for authenticated requests
const profileResponse = await fetch('/api/users/profile', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  }
});

const profileData = await profileResponse.json();
```

### Process Tracking Integration

```javascript
// Log multiple activities
const activities = [
  {
    userId: 1,
    processName: 'WINWORD.EXE',
    windowTitle: 'Document1 - Word',
    processId: '1234',
    startTime: '2024-01-01T09:00:00',
    endTime: '2024-01-01T10:00:00',
    durationSeconds: 3600,
    category: 'PRODUCTIVITY',
    isProductiveApp: true
  }
];

const logResponse = await fetch('/api/logs/batch', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(activities)
});
```

---

## 11. Monitoring and Logging

### Application Logs
- All API calls are logged with timestamps
- Error logs include stack traces
- Performance metrics are tracked

### Audit Trail
- User authentication attempts
- Data modification operations
- Administrative actions
- System configuration changes

### Health Checks
- Database connectivity
- System resource usage
- API response times
- Error rates

---

## 12. Backup and Recovery

### Data Backup
- Automated daily backups
- Point-in-time recovery available
- Backup verification processes

### Disaster Recovery
- Database replication
- System state snapshots
- Recovery time objectives defined

---

## 13. API Versioning

### Current Version
- API Version: v1
- Base Path: `/api/`

### Future Versions
- Backward compatibility maintained
- Deprecation notices for old endpoints
- Migration guides provided

---

## 14. Support and Troubleshooting

### Common Issues

#### Authentication Issues
- **Problem**: "Invalid credentials" error
- **Solution**: Verify username/password, check account status

#### Permission Denied
- **Problem**: 403 Forbidden response
- **Solution**: Verify user role and permissions

#### Rate Limiting
- **Problem**: 429 Too Many Requests
- **Solution**: Implement request throttling, use appropriate delays

### Contact Information
- Technical Support: support@company.com
- Documentation: docs@company.com
- Emergency Contact: emergency@company.com

---

## 15. Changelog

### Version 1.0.0 (Current)
- Initial API release
- User management and authentication
- Activity tracking and analytics
- Process monitoring
- Admin operations
- Security features implemented

### Planned Features
- Real-time notifications
- Advanced analytics dashboards
- Mobile app support
- Third-party integrations
- Enhanced security features

---

*This documentation is maintained and updated regularly. For the latest version, please check the project repository or contact the development team.*
