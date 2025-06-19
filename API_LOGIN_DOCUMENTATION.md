# POST /api/users/login - Complete API Documentation

## Overview
The `/api/users/login` endpoint authenticates users and provides JWT tokens for accessing protected resources. This endpoint validates user credentials and returns detailed user information along with role-based permissions.

---

## 🔗 Endpoint Details

| Property | Value |
|----------|-------|
| **URL** | `http://localhost:8081/api/users/login` |
| **Method** | `POST` |
| **Authentication** | Not Required (Public Endpoint) |
| **Content-Type** | `application/json` |

---

## 🔐 Security Configuration

### Public Access
- **Authentication**: Not required
- **Authorization**: Public endpoint (no role restrictions)
- **Rate Limiting**: Should be implemented for security

### Security Implementation
```java
// From SecurityConfig.java
.requestMatchers("/api/users/register", "/api/users/login").permitAll()
```

---

## 📥 Request Format

### Required Headers
```http
Content-Type: application/json
```

### Request Body
```json
{
  "username": "john_doe",
  "password": "SecurePassword123"
}
```

### Request Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `username` | String | Yes | User's username |
| `password` | String | Yes | User's password |

### Field Validation
- **Username**: Cannot be null or empty
- **Password**: Cannot be null or empty
- **Case Sensitivity**: Username is case-sensitive

---

## 📤 Response Format

### Success Response (200 OK)
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJqb2huX2RvZSIsInJvbGUiOiJFTVBMT1lFRSIsInVzZXJJZCI6MSwiZXhwIjoxNzE5MzA2MDAwfQ.signature",
  "userId": 1,
  "role": "EMPLOYEE",
  "username": "john_doe",
  "email": "john@example.com",
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

### Response Fields Explanation
| Field | Type | Description |
|-------|------|-------------|
| `token` | String | JWT token for authentication (expires in 24 hours) |
| `userId` | Integer | Unique user identifier |
| `role` | String | User's role (EMPLOYEE, ADMIN, SUPERADMIN) |
| `username` | String | User's username |
| `email` | String | User's email address |
| `permissions` | Object | Role-based permissions object |

### Permission Matrix
| Permission | EMPLOYEE | ADMIN | SUPERADMIN |
|------------|----------|-------|------------|
| `canTrackProcesses` | ✅ | ✅ | ✅ |
| `canViewOwnStats` | ✅ | ✅ | ✅ |
| `canViewAllUsers` | ❌ | ✅ | ✅ |
| `canViewAllActivities` | ❌ | ✅ | ✅ |
| `canManageUsers` | ❌ | ✅ | ✅ |
| `canManageAdmins` | ❌ | ❌ | ✅ |
| `canAccessSystemSettings` | ❌ | ❌ | ✅ |

---

## ❌ Error Responses

### 400 Bad Request - Missing Fields
```json
{
  "error": "Username and password are required"
}
```

**Causes:**
- Missing username field
- Missing password field
- Empty username or password
- Invalid JSON format

### 401 Unauthorized - Invalid Credentials
```json
{
  "error": "Invalid credentials"
}
```

**Causes:**
- Username doesn't exist
- Password doesn't match
- Incorrect username/password combination

### 403 Forbidden - Account Disabled
```json
{
  "error": "Account is disabled"
}
```

**Causes:**
- User account has been deactivated by admin
- Account status is set to inactive in database

### 500 Internal Server Error
```json
{
  "error": "Login failed: Database connection error"
}
```

**Causes:**
- Database connectivity issues
- Server internal errors
- JWT token generation failures

---

## 🧪 Testing Examples

### 1. PowerShell Testing

#### Successful Login
```powershell
# Employee Login
$loginBody = @{
    username = "john_doe"
    password = "password123"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8081/api/users/login" -Method POST -Body $loginBody -ContentType "application/json"
$response | ConvertTo-Json -Depth 3

# Store token for future requests
$token = $response.token
Write-Host "Login successful! Token: $token"
```

#### Admin Login
```powershell
# Admin Login
$adminLoginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$adminResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/login" -Method POST -Body $adminLoginBody -ContentType "application/json"
$adminResponse | ConvertTo-Json -Depth 3
```

#### SuperAdmin Login
```powershell
# SuperAdmin Login
$superAdminLoginBody = @{
    username = "superadmin"
    password = "superadmin123"
} | ConvertTo-Json

$superAdminResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/users/login" -Method POST -Body $superAdminLoginBody -ContentType "application/json"
$superAdminResponse | ConvertTo-Json -Depth 3
```

### 2. cURL Testing

#### Basic Login
```bash
# Employee Login
curl -X POST "http://localhost:8081/api/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "password123"
  }'
```

#### Login with Error Handling
```bash
# Login with response code checking
response=$(curl -s -w "%{http_code}" -X POST "http://localhost:8081/api/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "password123"
  }')

http_code="${response: -3}"
body="${response%???}"

if [ "$http_code" -eq 200 ]; then
    echo "Login successful!"
    token=$(echo "$body" | jq -r '.token')
    echo "Token: $token"
else
    echo "Login failed with code: $http_code"
    echo "Error: $body"
fi
```

### 3. JavaScript/Fetch Testing

#### Basic Login Function
```javascript
async function login(username, password) {
  try {
    const response = await fetch('http://localhost:8081/api/users/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        username: username,
        password: password
      })
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || `HTTP error! status: ${response.status}`);
    }

    // Store token in localStorage
    localStorage.setItem('authToken', data.token);
    localStorage.setItem('userRole', data.role);
    localStorage.setItem('userId', data.userId);
    localStorage.setItem('userPermissions', JSON.stringify(data.permissions));

    console.log('Login successful:', data);
    return data;

  } catch (error) {
    console.error('Login failed:', error.message);
    throw error;
  }
}

// Usage
login('john_doe', 'password123')
  .then(userData => {
    console.log('User logged in:', userData.username);
    console.log('Role:', userData.role);
    console.log('Permissions:', userData.permissions);
  })
  .catch(error => {
    console.error('Login error:', error.message);
  });
```

#### Complete Login Handler with Retry
```javascript
class AuthService {
  constructor() {
    this.baseUrl = 'http://localhost:8081/api';
    this.maxRetries = 3;
  }

  async login(username, password, retryCount = 0) {
    try {
      const response = await fetch(`${this.baseUrl}/users/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ username, password })
      });

      const data = await response.json();

      if (!response.ok) {
        // Handle specific error cases
        switch (response.status) {
          case 400:
            throw new Error('Please provide both username and password');
          case 401:
            throw new Error('Invalid username or password');
          case 403:
            throw new Error('Your account has been disabled. Please contact support.');
          case 500:
            if (retryCount < this.maxRetries) {
              console.log(`Server error, retrying... (${retryCount + 1}/${this.maxRetries})`);
              await this.delay(1000 * (retryCount + 1)); // Exponential backoff
              return this.login(username, password, retryCount + 1);
            }
            throw new Error('Server error. Please try again later.');
          default:
            throw new Error(data.error || 'Login failed');
        }
      }

      // Store authentication data
      this.storeAuthData(data);
      
      return data;

    } catch (error) {
      if (error.name === 'TypeError' && retryCount < this.maxRetries) {
        // Network error, retry
        console.log(`Network error, retrying... (${retryCount + 1}/${this.maxRetries})`);
        await this.delay(1000 * (retryCount + 1));
        return this.login(username, password, retryCount + 1);
      }
      throw error;
    }
  }

  storeAuthData(data) {
    localStorage.setItem('authToken', data.token);
    localStorage.setItem('userRole', data.role);
    localStorage.setItem('userId', data.userId.toString());
    localStorage.setItem('username', data.username);
    localStorage.setItem('userEmail', data.email);
    localStorage.setItem('userPermissions', JSON.stringify(data.permissions));
    localStorage.setItem('loginTime', new Date().toISOString());
  }

  clearAuthData() {
    const keys = ['authToken', 'userRole', 'userId', 'username', 'userEmail', 'userPermissions', 'loginTime'];
    keys.forEach(key => localStorage.removeItem(key));
  }

  isAuthenticated() {
    const token = localStorage.getItem('authToken');
    return token !== null;
  }

  getUserRole() {
    return localStorage.getItem('userRole');
  }

  getUserPermissions() {
    const permissions = localStorage.getItem('userPermissions');
    return permissions ? JSON.parse(permissions) : {};
  }

  hasPermission(permission) {
    const permissions = this.getUserPermissions();
    return permissions[permission] === true;
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Usage
const authService = new AuthService();

// Login example
authService.login('john_doe', 'password123')
  .then(userData => {
    console.log('Login successful!');
    console.log('User:', userData.username);
    console.log('Role:', userData.role);
    
    // Check permissions
    if (authService.hasPermission('canManageUsers')) {
      console.log('User can manage other users');
    } else {
      console.log('User cannot manage other users');
    }
  })
  .catch(error => {
    console.error('Login failed:', error.message);
    // Show error to user
    document.getElementById('error-message').textContent = error.message;
  });
```

---

## 🔄 Frontend Integration Examples

### React Login Component
```jsx
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

const LoginForm = ({ onLogin }) => {
  const [formData, setFormData] = useState({
    username: '',
    password: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
    // Clear error when user starts typing
    if (error) setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await fetch('http://localhost:8081/api/users/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Login failed');
      }

      // Store authentication data
      localStorage.setItem('authToken', data.token);
      localStorage.setItem('userRole', data.role);
      localStorage.setItem('userId', data.userId);
      localStorage.setItem('userPermissions', JSON.stringify(data.permissions));

      // Call parent callback
      if (onLogin) {
        onLogin(data);
      }

      // Redirect based on role
      switch (data.role) {
        case 'SUPERADMIN':
          navigate('/admin/dashboard');
          break;
        case 'ADMIN':
          navigate('/admin/users');
          break;
        case 'EMPLOYEE':
          navigate('/employee/dashboard');
          break;
        default:
          navigate('/dashboard');
      }

    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-form">
      <h2>Login</h2>
      
      {error && (
        <div className="error-message">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="username">Username:</label>
          <input
            type="text"
            id="username"
            name="username"
            value={formData.username}
            onChange={handleChange}
            required
            disabled={loading}
            placeholder="Enter your username"
          />
        </div>

        <div className="form-group">
          <label htmlFor="password">Password:</label>
          <input
            type="password"
            id="password"
            name="password"
            value={formData.password}
            onChange={handleChange}
            required
            disabled={loading}
            placeholder="Enter your password"
          />
        </div>

        <button
          type="submit"
          disabled={loading || !formData.username || !formData.password}
          className="login-button"
        >
          {loading ? 'Logging in...' : 'Login'}
        </button>
      </form>

      <div className="test-credentials">
        <h4>Test Credentials:</h4>
        <p><strong>Employee:</strong> username: employee, password: employee123</p>
        <p><strong>Admin:</strong> username: admin, password: admin123</p>
        <p><strong>SuperAdmin:</strong> username: superadmin, password: superadmin123</p>
      </div>
    </div>
  );
};

export default LoginForm;
```

### Vue.js Login Component
```vue
<template>
  <div class="login-container">
    <div class="login-form">
      <h2>Employee Productivity Tracker</h2>
      <h3>Login</h3>

      <div v-if="error" class="error-message">
        {{ error }}
      </div>

      <form @submit.prevent="handleLogin">
        <div class="form-group">
          <label for="username">Username:</label>
          <input
            type="text"
            id="username"
            v-model="formData.username"
            required
            :disabled="loading"
            placeholder="Enter your username"
            class="form-control"
          />
        </div>

        <div class="form-group">
          <label for="password">Password:</label>
          <input
            type="password"
            id="password"
            v-model="formData.password"
            required
            :disabled="loading"
            placeholder="Enter your password"
            class="form-control"
          />
        </div>

        <button
          type="submit"
          :disabled="loading || !isFormValid"
          class="btn-login"
        >
          {{ loading ? 'Logging in...' : 'Login' }}
        </button>
      </form>

      <div class="test-credentials">
        <h4>Test Credentials:</h4>
        <div class="credential-item" @click="fillCredentials('employee')">
          <strong>Employee:</strong> employee / employee123
        </div>
        <div class="credential-item" @click="fillCredentials('admin')">
          <strong>Admin:</strong> admin / admin123
        </div>
        <div class="credential-item" @click="fillCredentials('superadmin')">
          <strong>SuperAdmin:</strong> superadmin / superadmin123
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LoginForm',
  data() {
    return {
      formData: {
        username: '',
        password: ''
      },
      loading: false,
      error: ''
    };
  },
  
  computed: {
    isFormValid() {
      return this.formData.username.trim() && this.formData.password.trim();
    }
  },
  
  methods: {
    async handleLogin() {
      this.loading = true;
      this.error = '';

      try {
        const response = await fetch('http://localhost:8081/api/users/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(this.formData)
        });

        const data = await response.json();

        if (!response.ok) {
          throw new Error(data.error || 'Login failed');
        }

        // Store authentication data
        localStorage.setItem('authToken', data.token);
        localStorage.setItem('userRole', data.role);
        localStorage.setItem('userId', data.userId);
        localStorage.setItem('username', data.username);
        localStorage.setItem('userEmail', data.email);
        localStorage.setItem('userPermissions', JSON.stringify(data.permissions));

        // Emit login event
        this.$emit('login-success', data);

        // Redirect based on role
        this.redirectByRole(data.role);

      } catch (err) {
        this.error = err.message;
      } finally {
        this.loading = false;
      }
    },

    redirectByRole(role) {
      switch (role) {
        case 'SUPERADMIN':
          this.$router.push('/admin/system');
          break;
        case 'ADMIN':
          this.$router.push('/admin/dashboard');
          break;
        case 'EMPLOYEE':
          this.$router.push('/employee/dashboard');
          break;
        default:
          this.$router.push('/dashboard');
      }
    },

    fillCredentials(userType) {
      const credentials = {
        employee: { username: 'employee', password: 'employee123' },
        admin: { username: 'admin', password: 'admin123' },
        superadmin: { username: 'superadmin', password: 'superadmin123' }
      };

      if (credentials[userType]) {
        this.formData = { ...credentials[userType] };
        this.error = '';
      }
    }
  }
};
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background-color: #f5f5f5;
}

.login-form {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}

.form-group {
  margin-bottom: 1rem;
}

.form-control {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.btn-login {
  width: 100%;
  padding: 0.75rem;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-login:hover:not(:disabled) {
  background-color: #0056b3;
}

.btn-login:disabled {
  background-color: #6c757d;
  cursor: not-allowed;
}

.error-message {
  background-color: #f8d7da;
  color: #721c24;
  padding: 0.75rem;
  border-radius: 4px;
  margin-bottom: 1rem;
  border: 1px solid #f5c6cb;
}

.test-credentials {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid #eee;
}

.credential-item {
  padding: 0.5rem;
  margin: 0.25rem 0;
  background-color: #f8f9fa;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.credential-item:hover {
  background-color: #e9ecef;
}
</style>
```

---

## 🛠️ Implementation Details

### Backend Code Location
- **Controller**: `src/main/java/com/example/backendapp/controller/UserController.java` (lines 49-125)
- **Service**: `src/main/java/com/example/backendapp/service/UserService.java`
- **JWT Provider**: `src/main/java/com/example/backendapp/security/JwtTokenProvider.java`
- **Security Config**: `src/main/java/com/example/backendapp/config/SecurityConfig.java` (line 41)

### Key Features
1. **Credential Validation**: Username and password verification
2. **Account Status Check**: Ensures only active accounts can login
3. **JWT Token Generation**: Creates secure tokens with user claims
4. **Role-Based Permissions**: Returns detailed permission matrix
5. **Error Handling**: Comprehensive error responses
6. **Security**: Password hashing with BCrypt

### JWT Token Details
- **Algorithm**: HMAC SHA-256
- **Expiration**: 24 hours
- **Claims**: username, role, userId
- **Usage**: Include in Authorization header as `Bearer <token>`

---

## 🐛 Troubleshooting

### Common Issues

1. **400 Bad Request**
   - Missing username or password fields
   - Empty values
   - Invalid JSON format

2. **401 Invalid Credentials**
   - Wrong username/password combination
   - Case-sensitive username
   - User doesn't exist

3. **403 Account Disabled**
   - Admin has deactivated the account
   - Check user status in database

4. **500 Server Error**
   - Database connection issues
   - JWT configuration problems
   - Server internal errors

### Debug Steps

1. **Verify User Exists**:
   ```sql
   SELECT id, username, email, role, active FROM users WHERE username = 'your_username';
   ```

2. **Check Password**:
   ```sql
   SELECT password FROM users WHERE username = 'your_username';
   ```

3. **Test JWT Configuration**:
   Check `application.properties` for JWT secret key

4. **Monitor Logs**:
   Check server logs for detailed error messages

---

## 🚨 Security Best Practices

### Implementation Recommendations

1. **Rate Limiting**: Implement login attempt limits
2. **Account Lockout**: Temporarily lock accounts after failed attempts
3. **Password Policy**: Enforce strong password requirements
4. **HTTPS Only**: Use SSL/TLS in production
5. **Token Expiry**: Short-lived tokens with refresh mechanism
6. **Audit Logging**: Log all login attempts

### Example Rate Limiting (Recommendation)
```java
@Component
public class LoginRateLimiter {
    private final Map<String, AtomicInteger> attemptsByUsername = new ConcurrentHashMap<>();
    private final Map<String, LocalDateTime> lockoutTime = new ConcurrentHashMap<>();
    
    public boolean isAllowed(String username) {
        // Check if account is locked
        LocalDateTime lockout = lockoutTime.get(username);
        if (lockout != null && lockout.isAfter(LocalDateTime.now())) {
            return false;
        }
        
        // Check attempt count
        AtomicInteger attempts = attemptsByUsername.get(username);
        return attempts == null || attempts.get() < 5;
    }
    
    public void recordFailedAttempt(String username) {
        AtomicInteger attempts = attemptsByUsername.computeIfAbsent(username, k -> new AtomicInteger(0));
        int currentAttempts = attempts.incrementAndGet();
        
        if (currentAttempts >= 5) {
            lockoutTime.put(username, LocalDateTime.now().plusMinutes(15));
        }
    }
    
    public void recordSuccessfulLogin(String username) {
        attemptsByUsername.remove(username);
        lockoutTime.remove(username);
    }
}
```

---

## 🚀 Quick Start Checklist

1. ✅ Ensure server is running on port 8081
2. ✅ Have valid username/password credentials
3. ✅ Send POST request with JSON body
4. ✅ Include Content-Type: application/json header
5. ✅ Store returned JWT token for authenticated requests
6. ✅ Handle error responses appropriately
7. ✅ Implement proper logout functionality

This login API is the gateway to your Employee Productivity Tracking System and provides secure authentication with detailed user information and permissions for role-based access control.
