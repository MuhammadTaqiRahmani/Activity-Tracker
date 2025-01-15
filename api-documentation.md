# Backend API Documentation

Base URL: `http://localhost:8081/api`

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

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
    "role": "EMPLOYEE"
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
    "token": "string",
    "userId": "string",
    "role": "string"
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

### 4. Get All Users with Filters
- **URL**: `/api/users/all`
- **Method**: GET
- **Auth Required**: Yes (Admin)
- **Query Parameters**:
  - role (optional): Filter by user role
  - active (optional): Filter by user status (true/false)
- **Success Response**: 200 OK
```json
{
    "users": [
        {
            "id": "number",
            "username": "string",
            "email": "string",
            "role": "string",
            "active": "boolean",
            "createdAt": "datetime"
        }
    ],
    "count": "number",
    "timestamp": "datetime"
}
```

### 5. Get User Details
- **URL**: `/api/users/details/{id}`
- **Method**: GET
- **Auth Required**: Yes (Admin)
- **URL Parameters**: 
  - id: User ID
- **Success Response**: 200 OK
```json
{
    "id": "number",
    "username": "string",
    "email": "string",
    "role": "string",
    "active": "boolean",
    "createdAt": "datetime"
}
```
- **Error Response**: 404 Not Found
```json
{
    "error": "User not found"
}
```

### 6. Change User Password
- **URL**: `/api/users/{id}/change-password`
- **Method**: PUT
- **Auth Required**: Yes (Admin)
- **URL Parameters**:
  - id: User ID
- **Body**: 
```json
"newPassword"
```
- **Success Response**: 200 OK
```json
{
    "message": "Password changed successfully"
}
```

## Activity Tracking Endpoints

### 1. Get All Activities with Filters
- **URL**: `/api/activities/all`
- **Method**: GET
- **Auth Required**: Yes
- **Query Parameters**:
  - userId (optional): Filter by user ID
  - activityType (optional): Filter by activity type
  - applicationCategory (optional): Filter by application category
  - page (default: 0): Page number
  - size (default: 10): Page size
  - sortBy (default: "createdAt"): Sort field
  - sortDirection (default: "desc"): Sort direction
- **Success Response**: 200 OK
```json
{
    "activities": [
        {
            "id": "number",
            "userId": "number",
            "activityType": "string",
            "description": "string",
            "applicationName": "string",
            "processName": "string",
            "windowTitle": "string",
            "startTime": "datetime",
            "endTime": "datetime",
            "durationSeconds": "number",
            "status": "string",
            "workspaceType": "string",
            "applicationCategory": "string"
        }
    ],
    "currentPage": "number",
    "totalItems": "number",
    "totalPages": "number",
    "timestamp": "datetime"
}
```

### 2. Get Activity Details
- **URL**: `/api/activities/details/{id}`
- **Method**: GET
- **Auth Required**: Yes
- **URL Parameters**: 
  - id: Activity ID
- **Success Response**: 200 OK
```json
{
    "id": "number",
    "userId": "number",
    "activityType": "string",
    "description": "string",
    "applicationName": "string",
    "processName": "string",
    "windowTitle": "string",
    "startTime": "datetime",
    "endTime": "datetime",
    "durationSeconds": "number",
    "status": "string",
    "workspaceType": "string",
    "applicationCategory": "string"
}
```

### 3. Get Activity Statistics
- **URL**: `/api/activities/stats`
- **Method**: GET
- **Auth Required**: Yes
- **Query Parameters**:
  - userId: User ID
  - startDate: Start date (yyyy-MM-ddTHH:mm:ss)
  - endDate: End date (yyyy-MM-ddTHH:mm:ss)
- **Success Response**: 200 OK
```json
{
    "totalActivities": "number",
    "byCategory": {
        "categoryName": "count"
    },
    "byStatus": {
        "statusName": "count"
    },
    "totalDuration": "number",
    "timeRange": {
        "start": "datetime",
        "end": "datetime"
    }
}
```

### 4. Log Process Batch
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

### 5. Get Today's Activities
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

### 6. Get Activity Summary
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

### 7. Get Daily Application Usage
- **URL**: `/api/activities/application-usage`
- **Method**: GET
- **Auth Required**: Yes
- **Query Parameters**:
  - userId: Long (required)
- **Success Response**: 200 OK
```json
{
    "applicationName": "durationInSeconds"
}
```

### 8. Get Productive Time
- **URL**: `/api/activities/productive-time`
- **Method**: GET
- **Auth Required**: Yes
- **Query Parameters**:
  - userId: Long (required)
- **Success Response**: 200 OK
```json
{
    "productiveTimeSeconds": "number"
}
```

### 9. Get Activity Categories
- **URL**: `/api/activities/categories`
- **Method**: GET
- **Auth Required**: Yes
- **Query Parameters**:
  - userId: Long (required)
- **Success Response**: 200 OK
```json
{
    "categoryName": "durationInSeconds"
}
```

### 10. Get Activity Status
- **URL**: `/api/activities/status`
- **Method**: GET
- **Auth Required**: Yes
- **Query Parameters**:
  - userId: Long (required)
- **Success Response**: 200 OK
```json
{
    "status": "string",
    "lastActive": "datetime"
}
```

### 11. Clear Activities (Admin Only)
- **URL**: `/api/activities/clear`
- **Method**: DELETE
- **Auth Required**: Yes (Admin)
- **Query Parameters**:
  - userId: Long (required)
- **Success Response**: 200 OK
```json
{
    "message": "Activities cleared successfully"
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

## Notes

- All timestamps are in ISO 8601 format (yyyy-MM-ddTHH:mm:ss)
- Non-admin users can only access their own data
- Admin users can access all endpoints and all user data
- Boolean values should be sent as `true` or `false`
- JWT tokens must be included in the Authorization header as `Bearer <token>`
- Pagination is zero-based (page=0 is the first page)
- Sort direction can be "asc" or "desc"
- Response times may vary based on date range and data volume
- Rate limiting may apply to certain endpoints
