# GET /api/users/all - Complete API Documentation

## Overview
The `/api/users/all` endpoint retrieves all users from the database with optional filtering, pagination, and role-based access control. This endpoint is designed for admin users to manage and view all system users.

---

## 🔗 Endpoint Details

| Property | Value |
|----------|-------|
| **URL** | `http://localhost:8081/api/users/all` |
| **Method** | `GET` |
| **Authentication** | Required (JWT Token) |
| **Authorization** | ADMIN or SUPERADMIN roles only |
| **Content-Type** | `application/json` |

---

## 🔐 Security Configuration

### Required Roles
- **SUPERADMIN** ✅
- **ADMIN** ✅  
- **EMPLOYEE** ❌ (403 Forbidden)

### Security Implementation
```java
// From SecurityConfig.java
.requestMatchers("/api/users/all", "/api/users/{id}").hasAnyRole("SUPERADMIN", "ADMIN")
```

---

## 📝 Request Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `role` | String | No | null | Filter users by role (EMPLOYEE, ADMIN, SUPERADMIN) |
| `active` | Boolean | No | null | Filter users by active status (true/false) |
| `page` | Integer | No | 0 | Page number for pagination (0-based) |
| `size` | Integer | No | 20 | Number of users per page |

### Example Request URLs
```bash
# Get all users (default pagination)
GET http://localhost:8081/api/users/all

# Get only active users
GET http://localhost:8081/api/users/all?active=true

# Get only EMPLOYEE users
GET http://localhost:8081/api/users/all?role=EMPLOYEE

# Get inactive ADMIN users with pagination
GET http://localhost:8081/api/users/all?role=ADMIN&active=false&page=0&size=10

# Get second page of users
GET http://localhost:8081/api/users/all?page=1&size=5
```

---

## 🔑 Authentication Headers

### Required Headers
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsInJvbGUiOiJTVVBFUkFETUlOIiwidXNlcklkIjoxLCJpYXQiOjE3MTg3MDAwMDAsImV4cCI6MTcxODc4NjQwMH0.signature
Content-Type: application/json
```

### How to Get JWT Token
1. Login first using `/api/users/login`
2. Extract the token from the login response
3. Include it in the Authorization header

---

## 📤 Response Format

### Success Response (200 OK)
```json
{
  "users": [
    {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "role": "SUPERADMIN",
      "active": true,
      "createdAt": "2025-06-18T08:00:00"
    },
    {
      "id": 2,
      "username": "john_doe",
      "email": "john@example.com",
      "role": "EMPLOYEE",
      "active": true,
      "createdAt": "2025-06-18T09:30:00"
    }
  ],
  "totalUsers": 15,
  "currentPage": 0,
  "totalPages": 3
}
```

### Response Fields Explanation
| Field | Type | Description |
|-------|------|-------------|
| `users` | Array | List of user objects |
| `users[].id` | Integer | Unique user identifier |
| `users[].username` | String | User's username |
| `users[].email` | String | User's email address |
| `users[].role` | String | User's role (normalized without ROLE_ prefix) |
| `users[].active` | Boolean | Whether user account is active |
| `users[].createdAt` | String | Account creation timestamp (ISO format) |
| `totalUsers` | Integer | Total number of users matching filters |
| `currentPage` | Integer | Current page number (0-based) |
| `totalPages` | Integer | Total number of pages available |

---

## ❌ Error Responses

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "JWT token is missing or invalid"
}
```

**Causes:**
- Missing Authorization header
- Invalid JWT token
- Expired JWT token
- Malformed token

### 403 Forbidden
```json
{
  "error": "Forbidden",
  "message": "Access denied"
}
```

**Causes:**
- User has EMPLOYEE role (not authorized)
- User account is deactivated
- Token doesn't contain required role claims

### 500 Internal Server Error
```json
{
  "error": "Failed to retrieve users: Database connection failed"
}
```

**Causes:**
- Database connectivity issues
- Server internal errors
- Unexpected exceptions

---

## 🧪 Testing Examples

### 1. PowerShell Testing
```powershell
# First, get a token by logging in
$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.data.token

# Test the /users/all endpoint
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$response = Invoke-RestMethod -Uri "http://localhost:8081/api/users/all" -Method GET -Headers $headers
$response | ConvertTo-Json -Depth 3
```

### 2. cURL Testing
```bash
# Get token first
TOKEN=$(curl -s -X POST http://localhost:8081/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | \
  jq -r '.data.token')

# Test the endpoint
curl -X GET "http://localhost:8081/api/users/all" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### 3. JavaScript/Fetch Testing
```javascript
// Login first
const loginResponse = await fetch('http://localhost:8081/api/users/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    username: 'admin',
    password: 'admin123'
  })
});

const loginData = await loginResponse.json();
const token = loginData.data.token;

// Test the /users/all endpoint
const response = await fetch('http://localhost:8081/api/users/all', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});

const userData = await response.json();
console.log(userData);
```

---

## 🐛 Troubleshooting Guide

### Issue: Getting 403 Forbidden despite being logged in as SUPERADMIN

#### Possible Causes & Solutions:

1. **JWT Token Role Claims Issue**
   ```java
   // Check if your JWT token contains the correct role
   // The role should be "SUPERADMIN" not "ROLE_SUPERADMIN" in the token
   ```

2. **Token Format Issue**
   - ✅ Correct: `Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...`
   - ❌ Wrong: `Authorization: eyJhbGciOiJIUzI1NiJ9...`
   - ❌ Wrong: `Bearer: eyJhbGciOiJIUzI1NiJ9...`

3. **Role Normalization Issue**
   Check your user's role in the database:
   ```sql
   SELECT id, username, role FROM users WHERE username = 'your_admin_username';
   ```
   
   The role should be either:
   - `SUPERADMIN` or 
   - `ROLE_SUPERADMIN`

4. **JWT Token Expiry**
   - Check if your token has expired
   - Login again to get a fresh token

5. **Database User Status**
   ```sql
   SELECT id, username, role, active FROM users WHERE username = 'your_admin_username';
   ```
   Ensure `active` = 1 (true)

#### Debug Steps:

1. **Verify Login Response**
   ```json
   {
     "success": true,
     "message": "Login successful",
     "data": {
       "token": "eyJhbGciOiJIUzI1NiJ9...",
       "user": {
         "id": 1,
         "username": "admin",
         "email": "admin@example.com",
         "role": "SUPERADMIN"  // ← Should be SUPERADMIN
       }
     }
   }
   ```

2. **Check JWT Token Claims**
   Decode your JWT token at [jwt.io](https://jwt.io) and verify:
   ```json
   {
     "sub": "admin",
     "role": "SUPERADMIN",  // ← Should match
     "userId": 1,
     "iat": 1718700000,
     "exp": 1718786400
   }
   ```

3. **Test with Simple Request**
   ```bash
   # Test a simple authenticated endpoint first
   curl -X GET "http://localhost:8081/api/users/profile" \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

---

## 🔄 Integration Examples

### React Frontend Integration
```javascript
import { useState, useEffect } from 'react';

const UsersList = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const token = localStorage.getItem('authToken');
        
        const response = await fetch('http://localhost:8081/api/users/all', {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        setUsers(data.users);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchUsers();
  }, []);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      <h2>All Users ({users.length})</h2>
      <ul>
        {users.map(user => (
          <li key={user.id}>
            {user.username} - {user.role} - {user.active ? 'Active' : 'Inactive'}
          </li>
        ))}
      </ul>
    </div>
  );
};
```

### Vue.js Frontend Integration
```javascript
<template>
  <div>
    <h2>All Users</h2>
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">Error: {{ error }}</div>
    <div v-else>
      <p>Total Users: {{ totalUsers }}</p>
      <ul>
        <li v-for="user in users" :key="user.id">
          {{ user.username }} - {{ user.role }} - 
          <span :class="user.active ? 'active' : 'inactive'">
            {{ user.active ? 'Active' : 'Inactive' }}
          </span>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      users: [],
      totalUsers: 0,
      loading: true,
      error: null
    };
  },
  async mounted() {
    try {
      const token = localStorage.getItem('authToken');
      
      const response = await fetch('http://localhost:8081/api/users/all', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      this.users = data.users;
      this.totalUsers = data.totalUsers;
    } catch (err) {
      this.error = err.message;
    } finally {
      this.loading = false;
    }
  }
};
</script>
```

---

## 📊 Implementation Details

### Backend Code Location
- **Controller**: `src/main/java/com/example/backendapp/controller/UserController.java` (line 201)
- **Service**: `src/main/java/com/example/backendapp/service/UserService.java`
- **Security Config**: `src/main/java/com/example/backendapp/config/SecurityConfig.java` (line 45)

### Key Features
1. **Role-based Access Control**: Only ADMIN and SUPERADMIN can access
2. **Filtering**: Filter by role and active status
3. **Pagination**: Supports page-based pagination
4. **Data Sanitization**: Removes sensitive information (passwords)
5. **Role Normalization**: Removes "ROLE_" prefix for frontend display
6. **Error Handling**: Comprehensive error responses

### Performance Considerations
- **Pagination**: Prevents large data transfers
- **Filtering**: Reduces unnecessary data processing
- **DTO Mapping**: Excludes sensitive fields like passwords
- **Exception Handling**: Graceful error responses

---

## 🚀 Quick Start Checklist

1. ✅ Ensure your user has SUPERADMIN or ADMIN role
2. ✅ Login and get a valid JWT token
3. ✅ Include `Authorization: Bearer <token>` header
4. ✅ Set `Content-Type: application/json` header
5. ✅ Use correct URL: `http://localhost:8081/api/users/all`
6. ✅ Handle both success and error responses in your frontend

---

This documentation should help you successfully integrate the `/users/all` API with your frontend application. If you're still getting 403 errors, please check the troubleshooting section and verify your JWT token claims.
