# Postman Setup Guide for Role-Based Authentication Testing

## Quick Setup Instructions

### 1. Import Collection and Environment
1. Open Postman
2. Click "Import" button
3. Import these files:
   - `Role-Based-Auth-Collection.json` (the test collection)
   - `Role-Based-Auth-Environment.json` (environment variables)

### 2. Set Environment
1. In Postman, select "Role-Based Auth Environment" from the environment dropdown (top right)
2. Make sure your Spring Boot server is running on `http://localhost:8081`

### 3. Run Tests in Order

#### Step 1: Register Users
Run these requests first to create test users:
1. **Register Employee User**
2. **Register Admin User** 
3. **Register SuperAdmin User**

#### Step 2: Login and Get Tokens
Run these to get authentication tokens (tokens are automatically saved to environment):
1. **Login as Employee**
2. **Login as Admin**
3. **Login as SuperAdmin**

#### Step 3: Test Role-Based Access
Now test the different access levels:

**Employee Tests:**
- ✅ Employee - Get Profile (Should Succeed)
- ❌ Employee - Get All Users (Should Fail with 403)

**Admin Tests:**
- ✅ Admin - Get Profile (Should Succeed)
- ✅ Admin - Get All Users (Should Succeed)

**SuperAdmin Tests:**
- ✅ SuperAdmin - Get Profile (Should Succeed)
- ✅ SuperAdmin - Get All Users (Should Succeed)

#### Step 4: Test Security
- ❌ Access Protected Endpoint Without Token (Should Fail with 401)
- ❌ Access with Invalid Token (Should Fail with 401)
- ❌ Register Invalid Role (Should Fail with 409)
- ❌ Login with Invalid Credentials (Should Fail with 401)

## Manual Test Credentials

If you prefer to test manually without the collection:

### Employee User
```
Username: employee_test
Email: employee@example.com
Password: Password123!
Role: EMPLOYEE
```

### Admin User
```
Username: admin_test
Email: admin@example.com
Password: Password123!
Role: ADMIN
```

### SuperAdmin User
```
Username: superadmin_test
Email: superadmin@example.com
Password: Password123!
Role: SUPERADMIN
```

## Key API Endpoints

### Registration
```
POST http://localhost:8081/api/users/register
Content-Type: application/json

{
    "username": "your_username",
    "email": "your_email@example.com",
    "password": "Password123!",
    "role": "EMPLOYEE|ADMIN|SUPERADMIN"
}
```

### Login
```
POST http://localhost:8081/api/users/login
Content-Type: application/json

{
    "username": "your_username",
    "password": "Password123!"
}
```

### Access Profile (Protected)
```
GET http://localhost:8081/api/users/profile
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json
```

### Get All Users (Admin Only)
```
GET http://localhost:8081/api/users/all
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json
```

## Expected Responses

### Successful Login Response
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

### Error Response (401 Unauthorized)
```json
{
    "error": "Invalid credentials"
}
```

### Error Response (403 Forbidden)
```json
{
    "error": "Access denied"
}
```

## Testing Tips

1. **Run registration requests first** - Each role needs to be registered before login
2. **Check response status codes**:
   - 200: Success
   - 401: Unauthorized (invalid credentials or no token)
   - 403: Forbidden (valid token but insufficient permissions)
   - 409: Conflict (user already exists)
3. **Tokens are automatically saved** when you use the login requests in the collection
4. **Check permissions object** in login responses to understand what each role can do
5. **Test boundary cases** like invalid roles, wrong passwords, missing tokens

## Troubleshooting

- **"Connection refused"**: Make sure your Spring Boot server is running
- **"User already exists"**: Try different usernames or delete existing test users
- **"Invalid token"**: Re-run the login request to get a fresh token
- **403 errors**: Check that you're using the correct token for the role being tested
