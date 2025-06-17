# Backend API Documentation

Base URL: `http://localhost:8081/api`

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## Roles and Permissions

The system supports three user roles with different permission levels:

1. **SUPERADMIN**
   - Can manage all users (including admins)
   - Has full access to all system settings
   - Can access all analytics and activities data
   - Can manage system configuration

2. **ADMIN**
   - Can manage regular employees
   - Can access analytics across all users
   - Can view all activities
   - Cannot modify system settings or manage other admins

3. **EMPLOYEE**
   - Can only access their own profile and activity data
   - Can submit process tracking information
   - Cannot access admin features or other users' data

## User Management Endpoints

### 1. Register User
- **URL**: `/users/register`
- **Method**: POST
- **Auth Required**: No
- **Body**:
```json
{
    "username": "string",
    "email": "string",
    "password": "string",
    "role": "EMPLOYEE | ADMIN | SUPERADMIN"
}
```
- **Success Response**: 200 OK
```json
{
    "id": "number",
    "username": "string",
    "email": "string",
    "role": "string",
    "active": "boolean"
}
```

### 2. User Login
- **URL**: `/users/login`
- **Method**: POST
- **Auth Required**: No
- **Body**:
```json
{
    "username": "string",
    "password": "string"
}
```
- **Success Response**: 200 OK
```json
{
    "token": "jwt-token-string",
    "userId": "number",
    "username": "string",
    "email": "string",
    "role": "EMPLOYEE | ADMIN | SUPERADMIN",
    "permissions": {
        "canTrackProcesses": "boolean",
        "canViewOwnStats": "boolean",
        "canViewAllUsers": "boolean",
        "canViewAllActivities": "boolean", 
        "canManageUsers": "boolean",
        "canManageAdmins": "boolean",
        "canAccessSystemSettings": "boolean"
    }
}
```

### 3. Get User Profile
- **URL**: `/users/profile`
- **Method**: GET
- **Auth Required**: Yes
- **Headers**: Authorization Bearer Token
- **Success Response**: 200 OK
```json
{
    "id": "number",
    "username": "string",
    "email": "string",
    "role": "string",
    "active": "boolean"
}
```

## Activity Tracking Endpoints

### 1. Log Process Batch
- **URL**: `/logs/batch`
- **Method**: POST
- **Auth Required**: Yes
- **Body**:
```json
[
    {
        "userId": "number",
        "processName": "string",
        "windowTitle": "string",
        "processId": "string",
        "applicationPath": "string",
        "startTime": "yyyy-MM-ddTHH:mm:ss",
        "endTime": "yyyy-MM-ddTHH:mm:ss",
        "durationSeconds": "number",
        "category": "string",
        "isProductiveApp": "boolean",
        "activityType": "string",
        "description": "string",
        "workspaceType": "string",
        "applicationCategory": "string"
    }
]
```
- **Success Response**: 200 OK
```json
{
    "status": "success",
    "processTracksQueued": "number",
    "activitiesQueued": "number"
}
```

### 2. Get Today's Activities
- **URL**: `/activities/today`
- **Method**: GET
- **Auth Required**: Yes
- **Headers**: Authorization Bearer Token
- **Success Response**: 200 OK
```json
[
    {
        "id": "number",
        "userId": "number",
        "activityType": "string",
        "description": "string",
        "applicationName": "string",
        "startTime": "string",
        "endTime": "string",
        "durationSeconds": "number",
        "status": "string"
    }
]
```

### 3. Get Activity Summary
- **URL**: `/activities/summary`
- **Method**: GET
- **Auth Required**: Yes
- **Query Params**:
  - userId: number
  - startDate: yyyy-MM-ddTHH:mm:ss
  - endDate: yyyy-MM-ddTHH:mm:ss
- **Success Response**: 200 OK
```json
{
    "userId": "number",
    "applicationUsageDuration": {
        "appName": "durationInSeconds"
    },
    "totalProductiveTime": "number",
    "totalIdleTime": "number",
    "mostUsedApplication": "string"
}
```

## Admin Endpoints

### 1. List All Users (Admin Only)
- **URL**: `/users/list`
- **Method**: GET
- **Auth Required**: Yes (Admin)
- **Success Response**: 200 OK
```json
[
    {
        "id": "number",
        "username": "string",
        "email": "string",
        "role": "string",
        "active": "boolean"
    }
]
```

### 2. Deactivate User (Admin Only)
- **URL**: `/users/deactivate/{userId}`
- **Method**: DELETE
- **Auth Required**: Yes (Admin)
- **Success Response**: 200 OK
```json
{
    "message": "User deactivated successfully"
}
```

## Error Responses

All endpoints may return the following error responses:

### 401 Unauthorized
```json
{
    "error": "Invalid credentials"
}
```

### 403 Forbidden
```json
{
    "error": "Access denied"
}
```

### 404 Not Found
```json
{
    "error": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
    "error": "Internal server error message"
}
```
