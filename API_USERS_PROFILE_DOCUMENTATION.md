# GET/PUT /api/users/profile - Complete API Documentation

## Overview
The `/api/users/profile` endpoint provides functionality to retrieve and update the current user's profile information. This endpoint allows authenticated users to view and modify their own profile data.

---

## 🔗 Endpoint Details

| Property | Value |
|----------|-------|
| **Base URL** | `http://localhost:8081/api/users/profile` |
| **Methods** | `GET` (retrieve), `PUT` (update) |
| **Authentication** | Required (JWT Token) |
| **Authorization** | Any authenticated user (EMPLOYEE, ADMIN, SUPERADMIN) |
| **Content-Type** | `application/json` |

---

## 🔐 Security Configuration

### Required Authentication
- **JWT Token**: Required in Authorization header
- **Role Access**: Available to all authenticated users
  - **EMPLOYEE** ✅
  - **ADMIN** ✅  
  - **SUPERADMIN** ✅

### Security Implementation
```java
// From SecurityConfig.java - Falls under general authentication requirement
.anyRequest().authenticated()
```

---

## 📥 GET /api/users/profile - Retrieve Profile

### Request Details
| Property | Value |
|----------|-------|
| **Method** | `GET` |
| **URL** | `http://localhost:8081/api/users/profile` |
| **Parameters** | None |
| **Body** | None |

### Required Headers
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VybmFtZSIsInJvbGUiOiJFTVBMT1lFRSIsInVzZXJJZCI6MSwiZXhwIjoxNzE4Nzg2NDAwfQ.signature
Content-Type: application/json
```

### Success Response (200 OK)
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "EMPLOYEE",
  "active": true,
  "createdAt": "2025-06-18T08:00:00"
}
```

### Response Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Unique user identifier |
| `username` | String | User's username |
| `email` | String | User's email address |
| `role` | String | User's role (normalized without ROLE_ prefix) |
| `active` | Boolean | Whether user account is active |
| `createdAt` | String | Account creation timestamp (ISO format) |

### Error Responses

#### 401 Unauthorized
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

#### 404 Not Found
```json
{
  "error": "User not found"
}
```

**Causes:**
- User account deleted from database
- JWT token contains invalid username

#### 500 Internal Server Error
```json
{
  "error": "Failed to get profile: Database connection failed"
}
```

**Causes:**
- Database connectivity issues
- Server internal errors
- JWT token parsing errors

---

## 📤 PUT /api/users/profile - Update Profile

### Request Details
| Property | Value |
|----------|-------|
| **Method** | `PUT` |
| **URL** | `http://localhost:8081/api/users/profile` |
| **Content-Type** | `application/json` |

### Required Headers
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VybmFtZSIsInJvbGUiOiJFTVBMT1lFRSIsInVzZXJJZCI6MSwiZXhwIjoxNzE4Nzg2NDAwfQ.signature
Content-Type: application/json
```

### Request Body
```json
{
  "email": "john.updated@example.com",
  "fullName": "John Doe Updated"
}
```

### Updatable Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | String | No | New email address |
| `fullName` | String | No | Updated full name |

**Note:** Username and role cannot be updated through this endpoint.

### Success Response (200 OK)
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john.updated@example.com",
  "role": "EMPLOYEE",
  "active": true,
  "message": "Profile updated successfully"
}
```

### Error Responses

#### 400 Bad Request
```json
{
  "error": "Invalid email format"
}
```

**Causes:**
- Invalid email format
- Email already exists for another user
- Invalid request body format

#### 404 Not Found
```json
{
  "error": "User not found"
}
```

**Causes:**
- User account doesn't exist
- JWT token contains invalid user information

#### 500 Internal Server Error
```json
{
  "error": "Failed to update profile: Validation failed"
}
```

---

## 🧪 Testing Examples

### 1. PowerShell Testing

#### Get Profile
```powershell
# First, get a token by logging in
$loginBody = @{
    username = "john_doe"
    password = "password123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.data.token

# Get user profile
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$profile = Invoke-RestMethod -Uri "http://localhost:8081/api/users/profile" -Method GET -Headers $headers
$profile | ConvertTo-Json -Depth 2
```

#### Update Profile
```powershell
# Update profile
$updateBody = @{
    email = "john.newemail@example.com"
    fullName = "John Doe Updated"
} | ConvertTo-Json

$updatedProfile = Invoke-RestMethod -Uri "http://localhost:8081/api/users/profile" -Method PUT -Headers $headers -Body $updateBody
$updatedProfile | ConvertTo-Json -Depth 2
```

### 2. cURL Testing

#### Get Profile
```bash
# Get token first
TOKEN=$(curl -s -X POST http://localhost:8081/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"john_doe","password":"password123"}' | \
  jq -r '.data.token')

# Get profile
curl -X GET "http://localhost:8081/api/users/profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

#### Update Profile
```bash
# Update profile
curl -X PUT "http://localhost:8081/api/users/profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.updated@example.com",
    "fullName": "John Doe Updated"
  }'
```

### 3. JavaScript/Fetch Testing

#### Get Profile
```javascript
// Login first
const loginResponse = await fetch('http://localhost:8081/api/users/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    username: 'john_doe',
    password: 'password123'
  })
});

const loginData = await loginResponse.json();
const token = loginData.data.token;

// Get profile
const profileResponse = await fetch('http://localhost:8081/api/users/profile', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});

const profileData = await profileResponse.json();
console.log('Profile:', profileData);
```

#### Update Profile
```javascript
// Update profile
const updateResponse = await fetch('http://localhost:8081/api/users/profile', {
  method: 'PUT',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    email: 'john.updated@example.com',
    fullName: 'John Doe Updated'
  })
});

const updatedData = await updateResponse.json();
console.log('Updated Profile:', updatedData);
```

---

## 🔄 Frontend Integration Examples

### React Component
```jsx
import { useState, useEffect } from 'react';

const UserProfile = () => {
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [formData, setFormData] = useState({});
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const token = localStorage.getItem('authToken');
      const response = await fetch('http://localhost:8081/api/users/profile', {
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
      setProfile(data);
      setFormData({
        email: data.email,
        fullName: data.fullName || ''
      });
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const updateProfile = async (e) => {
    e.preventDefault();
    try {
      const token = localStorage.getItem('authToken');
      const response = await fetch('http://localhost:8081/api/users/profile', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
      });

      if (!response.ok) {
        throw new Error(`Update failed! status: ${response.status}`);
      }

      const updatedData = await response.json();
      setProfile(updatedData);
      setEditing(false);
      alert('Profile updated successfully!');
    } catch (err) {
      setError(err.message);
    }
  };

  if (loading) return <div>Loading profile...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div className="user-profile">
      <h2>My Profile</h2>
      
      {!editing ? (
        <div className="profile-display">
          <p><strong>Username:</strong> {profile.username}</p>
          <p><strong>Email:</strong> {profile.email}</p>
          <p><strong>Role:</strong> {profile.role}</p>
          <p><strong>Status:</strong> {profile.active ? 'Active' : 'Inactive'}</p>
          <p><strong>Member Since:</strong> {new Date(profile.createdAt).toLocaleDateString()}</p>
          
          <button onClick={() => setEditing(true)}>
            Edit Profile
          </button>
        </div>
      ) : (
        <form onSubmit={updateProfile} className="profile-form">
          <div>
            <label>Email:</label>
            <input
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({...formData, email: e.target.value})}
              required
            />
          </div>
          
          <div>
            <label>Full Name:</label>
            <input
              type="text"
              value={formData.fullName}
              onChange={(e) => setFormData({...formData, fullName: e.target.value})}
            />
          </div>
          
          <div className="form-buttons">
            <button type="submit">Save Changes</button>
            <button type="button" onClick={() => setEditing(false)}>
              Cancel
            </button>
          </div>
        </form>
      )}
    </div>
  );
};

export default UserProfile;
```

### Vue.js Component
```vue
<template>
  <div class="user-profile">
    <h2>My Profile</h2>
    
    <div v-if="loading">Loading profile...</div>
    <div v-else-if="error" class="error">Error: {{ error }}</div>
    
    <div v-else-if="!editing" class="profile-display">
      <p><strong>Username:</strong> {{ profile.username }}</p>
      <p><strong>Email:</strong> {{ profile.email }}</p>
      <p><strong>Role:</strong> {{ profile.role }}</p>
      <p><strong>Status:</strong> {{ profile.active ? 'Active' : 'Inactive' }}</p>
      <p><strong>Member Since:</strong> {{ formatDate(profile.createdAt) }}</p>
      
      <button @click="startEditing" class="btn-primary">
        Edit Profile
      </button>
    </div>
    
    <form v-else @submit.prevent="updateProfile" class="profile-form">
      <div class="form-group">
        <label>Email:</label>
        <input
          type="email"
          v-model="formData.email"
          required
          class="form-control"
        />
      </div>
      
      <div class="form-group">
        <label>Full Name:</label>
        <input
          type="text"
          v-model="formData.fullName"
          class="form-control"
        />
      </div>
      
      <div class="form-buttons">
        <button type="submit" class="btn-success">Save Changes</button>
        <button type="button" @click="cancelEditing" class="btn-secondary">
          Cancel
        </button>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  name: 'UserProfile',
  data() {
    return {
      profile: null,
      loading: true,
      editing: false,
      formData: {
        email: '',
        fullName: ''
      },
      error: null
    };
  },
  
  async mounted() {
    await this.fetchProfile();
  },
  
  methods: {
    async fetchProfile() {
      try {
        const token = localStorage.getItem('authToken');
        const response = await fetch('http://localhost:8081/api/users/profile', {
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
        this.profile = data;
        this.formData = {
          email: data.email,
          fullName: data.fullName || ''
        };
      } catch (err) {
        this.error = err.message;
      } finally {
        this.loading = false;
      }
    },
    
    async updateProfile() {
      try {
        const token = localStorage.getItem('authToken');
        const response = await fetch('http://localhost:8081/api/users/profile', {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(this.formData)
        });

        if (!response.ok) {
          throw new Error(`Update failed! status: ${response.status}`);
        }

        const updatedData = await response.json();
        this.profile = updatedData;
        this.editing = false;
        this.$emit('profile-updated', updatedData);
        alert('Profile updated successfully!');
      } catch (err) {
        this.error = err.message;
      }
    },
    
    startEditing() {
      this.editing = true;
      this.formData = {
        email: this.profile.email,
        fullName: this.profile.fullName || ''
      };
    },
    
    cancelEditing() {
      this.editing = false;
      this.error = null;
    },
    
    formatDate(dateString) {
      return new Date(dateString).toLocaleDateString();
    }
  }
};
</script>

<style scoped>
.user-profile {
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
}

.profile-display p {
  margin: 10px 0;
}

.profile-form {
  margin-top: 20px;
}

.form-group {
  margin-bottom: 15px;
}

.form-control {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.form-buttons {
  margin-top: 20px;
}

.form-buttons button {
  margin-right: 10px;
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary { background-color: #007bff; color: white; }
.btn-success { background-color: #28a745; color: white; }
.btn-secondary { background-color: #6c757d; color: white; }

.error {
  color: red;
  margin: 10px 0;
}
</style>
```

---

## 🧪 Live Test Case - Employee Role

### Test Setup (Performed on June 19, 2025)

#### 1. User Registration
```powershell
# Create test employee user
$registerBody = @{
    username = "test_employee"
    password = "password123"
    email = "employee@test.com"
    fullName = "Test Employee"
} | ConvertTo-Json

$registerResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/register" -Method POST -Body $registerBody -ContentType "application/json"
```

**Registration Result:**
```
role     : ROLE_EMPLOYEE
active   : True
id       : 20042
email    : employee@test.com
username : test_employee
```

#### 2. Employee Login
```powershell
# Login with test employee
$loginBody = @{
    username = "test_employee"
    password = "password123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/login" -Method POST -Body $loginBody -ContentType "application/json"
```

**Login Result:**
```
Role: EMPLOYEE
Permissions:
canTrackProcesses       : True
canAccessSystemSettings : False
canManageUsers          : False
canViewAllActivities    : False
canManageAdmins         : False
canViewAllUsers         : False
canViewOwnStats         : True
Token: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0X2VtcGxveWVlIiwidXNlcklkIjoyMDA0Miwicm9sZSI6IlJPTEVfRU1QTE9ZRUUiLCJpYXQiOjE3NTAyNzg1NTcsImV4cCI6MTc1MDM2NDk1N30...
```

#### 3. Profile Access Test
```powershell
# Test GET /api/users/profile as employee
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$profileResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/profile" -Method GET -Headers $headers
```

### ⚠️ Current Test Result (Issue Identified)

**Status**: ❌ **403 Forbidden**

**Issue Analysis:**
- **JWT Token Role**: `"role":"ROLE_EMPLOYEE"` (with ROLE_ prefix)
- **Spring Security Config**: Expects `"EMPLOYEE"` (without ROLE_ prefix)
- **Root Cause**: Role normalization mismatch between JWT token generation and Spring Security role checking

### 🔧 Expected Behavior vs Actual Behavior

| Aspect | Expected | Actual |
|--------|----------|--------|
| **Access** | ✅ Allowed (all authenticated users) | ❌ 403 Forbidden |
| **Response** | Profile data with user info | Error message |
| **Security** | Role-based access working | Role prefix mismatch |

### 📋 Recommended Fix

#### Option 1: Normalize Role in JWT Token Generation
```java
// In JwtTokenProvider.java
public String createToken(String username) {
    // ... existing code ...
    
    // Normalize role - remove ROLE_ prefix for JWT token
    String roleForToken = user.getRole().startsWith("ROLE_") ? 
        user.getRole().substring(5) : user.getRole();
    
    claims.put("role", roleForToken); // Store as "EMPLOYEE" not "ROLE_EMPLOYEE"
    
    // ... rest of the method ...
}
```

#### Option 2: Add Explicit Profile Endpoint Configuration
```java
// In SecurityConfig.java
.authorizeHttpRequests(auth -> auth
    // Public endpoints
    .requestMatchers("/api/users/register", "/api/users/login").permitAll()
    
    // Profile endpoint - accessible to all authenticated users
    .requestMatchers("/api/users/profile").hasAnyRole("SUPERADMIN", "ADMIN", "EMPLOYEE")
    
    // ... rest of configuration ...
)
```

### 🧪 Complete Test Script for Employee Role

```powershell
# Complete employee profile test script
Write-Host "=== Employee Profile API Test ==="

# Step 1: Register test employee
Write-Host "1. Registering test employee..."
$registerBody = @{
    username = "test_employee_$(Get-Date -Format 'yyyyMMddHHmmss')"
    password = "password123"
    email = "employee.test@example.com"
    fullName = "Test Employee User"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/register" -Method POST -Body $registerBody -ContentType "application/json"
    Write-Host "✅ Registration successful"
    $testUsername = ($registerBody | ConvertFrom-Json).username
} catch {
    Write-Host "❌ Registration failed: $($_.Exception.Message)"
    exit 1
}

# Step 2: Login as employee
Write-Host "2. Logging in as employee..."
$loginBody = @{
    username = $testUsername
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/login" -Method POST -Body $loginBody -ContentType "application/json"
    Write-Host "✅ Login successful - Role: $($loginResponse.role)"
    $token = $loginResponse.token
    
    # Display permissions
    Write-Host "Employee Permissions:"
    $loginResponse.permissions | Format-List
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)"
    exit 1
}

# Step 3: Test profile retrieval
Write-Host "3. Testing profile retrieval..."
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

try {
    $profileResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/profile" -Method GET -Headers $headers
    Write-Host "✅ Profile retrieval successful"
    Write-Host "Profile Data:"
    $profileResponse | Format-List
} catch {
    Write-Host "❌ Profile retrieval failed: $($_.Exception.Message)"
    Write-Host "This indicates a role configuration issue in Spring Security"
}

# Step 4: Test profile update
Write-Host "4. Testing profile update..."
$updateBody = @{
    email = "updated.employee@example.com"
    fullName = "Updated Test Employee"
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/profile" -Method PUT -Headers $headers -Body $updateBody
    Write-Host "✅ Profile update successful"
    $updateResponse | Format-List
} catch {
    Write-Host "❌ Profile update failed: $($_.Exception.Message)"
}

Write-Host "=== Test Complete ==="
```

### 🔍 JWT Token Analysis

**Token Payload Structure:**
```json
{
  "sub": "test_employee",
  "userId": 20042,
  "role": "ROLE_EMPLOYEE",
  "iat": 1750278557,
  "exp": 1750364957
}
```

**Key Observations:**
1. **Subject**: Contains username correctly
2. **User ID**: Properly included for user identification
3. **Role**: Contains `"ROLE_EMPLOYEE"` with prefix
4. **Timestamps**: Token expiry properly set (24 hours)

### 💡 Security Implications

This test reveals an important security configuration issue:
- **Current State**: Employee users cannot access their own profile
- **Impact**: Frontend applications cannot retrieve user profile data
- **Severity**: High - affects core user functionality
- **Solution**: Role normalization needs to be consistent across the application

### ✅ Once Fixed, Expected Employee Test Results

```json
{
  "id": 20042,
  "username": "test_employee",
  "email": "employee@test.com",
  "role": "EMPLOYEE",
  "active": true,
  "createdAt": "2025-06-19T10:30:00"
}
```

This test case demonstrates the importance of consistent role handling throughout the application and provides a complete testing framework for validating employee access to the profile endpoint.
