# Test Credentials for Role-Based Authentication APIs

## Base URL
```
http://localhost:8081/api
```

## Test Users for Registration and Login

### 1. Employee User
**Registration Request:**
```json
{
    "username": "employee_test",
    "email": "employee@example.com",
    "password": "Password123!",
    "role": "EMPLOYEE"
}
```

**Login Credentials:**
- Username: `employee_test`
- Password: `Password123!`

### 2. Admin User
**Registration Request:**
```json
{
    "username": "admin_test",
    "email": "admin@example.com",
    "password": "Password123!",
    "role": "ADMIN"
}
```

**Login Credentials:**
- Username: `admin_test`
- Password: `Password123!`

### 3. SuperAdmin User
**Registration Request:**
```json
{
    "username": "superadmin_test",
    "email": "superadmin@example.com",
    "password": "Password123!",
    "role": "SUPERADMIN"
}
```

**Login Credentials:**
- Username: `superadmin_test`
- Password: `Password123!`

## API Endpoints to Test

### 1. User Registration
- **URL:** `POST http://localhost:8081/api/users/register`
- **Headers:** 
  - `Content-Type: application/json`
- **Body:** Use any of the registration requests above

### 2. User Login
- **URL:** `POST http://localhost:8081/api/users/login`
- **Headers:** 
  - `Content-Type: application/json`
- **Body:**
```json
{
    "username": "employee_test",
    "password": "Password123!"
}
```

### 3. Get User Profile (Protected Endpoint)
- **URL:** `GET http://localhost:8081/api/users/profile`
- **Headers:** 
  - `Content-Type: application/json`
  - `Authorization: Bearer {{token}}`

### 4. Get All Users (Admin Only)
- **URL:** `GET http://localhost:8081/api/users/all`
- **Headers:** 
  - `Content-Type: application/json`
  - `Authorization: Bearer {{token}}`

## Expected Login Response Format
```json
{
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "userId": 1,
    "username": "employee_test",
    "email": "employee@example.com",
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

## Test Scenarios

### Scenario 1: Employee Access
1. Register employee user
2. Login as employee
3. Access profile (should succeed)
4. Try to access admin endpoint (should fail with 403)

### Scenario 2: Admin Access
1. Register admin user
2. Login as admin
3. Access profile (should succeed)
4. Access admin endpoints (should succeed)

### Scenario 3: SuperAdmin Access
1. Register superadmin user
2. Login as superadmin
3. Access all endpoints (should succeed)

### Scenario 4: Invalid Cases
1. Try to register with invalid role
2. Try to login with wrong credentials
3. Try to access protected endpoints without token
