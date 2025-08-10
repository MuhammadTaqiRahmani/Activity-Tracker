# Frontend API Integration Documentation

## Overview

This document provides comprehensive information about the API integration in the React Productivity Tracker Frontend application. The frontend communicates with a Spring Boot backend running on `http://localhost:8081/api`.

## Table of Contents

1. [API Configuration](#api-configuration)
2. [Authentication & Authorization](#authentication--authorization)
3. [API Endpoints](#api-endpoints)
4. [Data Flow & Integration](#data-flow--integration)
5. [Error Handling](#error-handling)
6. [State Management](#state-management)
7. [Security Implementation](#security-implementation)

---

## API Configuration

### Base Setup
```typescript
// Base URL: http://localhost:8081/api
const api = axios.create({
  baseURL: 'http://localhost:8081/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})
```

### Request Interceptor
- Automatically adds Bearer token to all requests
- Includes comprehensive debug logging
- Token retrieved from `localStorage.getItem('token')`

### Response Interceptor
- Handles 401 (Unauthorized) errors globally
- Automatically redirects to login on token expiration
- Clears local storage on authentication failures
- Comprehensive error logging without intrusive toast notifications

---

## Authentication & Authorization

### Authentication Flow

1. **Login Process**
   ```typescript
   POST /api/users/login
   Body: { username: string, password: string }
   Response: {
     token: string,
     userId: number,
     username: string,
     email: string,
     role: UserRole,
     permissions: UserPermissions
   }
   ```

2. **Token Storage**
   - JWT token stored in `localStorage`
   - User data stored in `localStorage`
   - Permissions cached in `localStorage`

3. **Role-Based Access Control**
   ```typescript
   type UserRole = 'EMPLOYEE' | 'ADMIN' | 'SUPERADMIN'
   
   interface UserPermissions {
     canTrackProcesses: boolean
     canViewOwnStats: boolean
     canViewAllUsers: boolean
     canViewAllActivities: boolean
     canManageUsers: boolean
     canCreateEmployees: boolean
     canCreateAdmins: boolean
     canManageAdmins: boolean
     canAccessSystemSettings: boolean
   }
   ```

4. **Token Validation**
   ```typescript
   POST /api/security/validate-token
   Response: { valid: boolean }
   ```

### Auto-Logout Feature
- Admin/SuperAdmin users are automatically logged out when updating their own username/email
- Prevents security issues with cached authentication data
- Graceful user experience with informative messages

---

## API Endpoints

### 🔐 Authentication API (`authApi`)

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | `/users/login` | User login | `LoginRequest` | `LoginResponse` |
| POST | `/users/register` | User registration | `RegisterRequest` | `User` |
| GET | `/users/profile` | Get current user profile | - | `User` |
| PUT | `/users/profile` | Update user profile | `Partial<User>` | `User` |
| POST | `/users/change-password` | Change password | `{currentPassword, newPassword}` | `{message}` |
| POST | `/security/validate-token` | Validate JWT token | - | `{valid: boolean}` |

### 👥 User Management API (`userApi`)

| Method | Endpoint | Description | Parameters | Response |
|--------|----------|-------------|------------|----------|
| GET | `/users/all` | Get all users (paginated) | `role?, active?, page?, size?` | `UsersAllResponse` |
| GET | `/users/{id}` | Get user by ID | - | `User` |
| PUT | `/users/{id}` | Update user | `Partial<User>` | `User` |
| POST | `/users/deactivate/{id}` | Deactivate user | - | `{message}` |
| GET | `/users/list` | Get simple users list | - | `User[]` |

### 📊 Activity Tracking API (`activityApi`)

| Method | Endpoint | Description | Parameters | Response |
|--------|----------|-------------|------------|----------|
| GET | `/activities/today` | Get today's activities | - | `Activity[]` |
| GET | `/activities/all` | Get user activities (paginated) | `userId, page?, size?, sortBy?, sortDirection?, activityType?, applicationCategory?, dateRange?` | `UserActivitiesResponse` |
| POST | `/activities/log` | Log new activity | `Partial<Activity>` | `Activity` |
| GET | `/activities/summary` | Get activity summary | `userId, dateRange` | `ActivitySummary` |

### 🔄 Process Tracking API (`processApi`)

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | `/logs/batch` | Log batch processes | `ProcessTrack[]` | `{status, processTracksQueued, activitiesQueued}` |
| POST | `/process-tracking/log` | Log single process | `Partial<ProcessTrack>` | `ProcessTrack` |
| GET | `/process-tracking/analytics` | Get process analytics | `userId, dateRange` | Analytics data |

### 📈 Analytics API (`analyticsApi`)

| Method | Endpoint | Description | Parameters | Response |
|--------|----------|-------------|------------|----------|
| GET | `/analytics/user/{userId}/stats` | Get user statistics | - | `UserStats` |
| GET | `/analytics/system/overview` | Get system analytics | - | `SystemAnalytics` |
| GET | `/security/system-status` | Get system status | - | `{status, uptime, activeUsers}` |

---

## Data Flow & Integration

### React Query Integration

The application uses **TanStack React Query** for:
- **Caching**: Automatic caching of API responses
- **Background Refetching**: Keeps data fresh
- **Optimistic Updates**: Immediate UI updates
- **Error Handling**: Centralized error management
- **Loading States**: Automatic loading indicators

#### Query Keys Strategy
```typescript
// User queries
['profile'] - Current user profile
['users', 'all', params] - All users list
['users', id] - Individual user by ID

// Activity queries
['activities', 'today'] - Today's activities
['activities', 'user', userId, params] - User-specific activities
['activities', 'summary', userId, dateRange] - Activity summary

// Analytics queries
['analytics', 'user', userId] - User statistics
['analytics', 'system'] - System overview
```

### Form Integration with React Hook Form

```typescript
// Profile update example
const {
  register,
  handleSubmit,
  formState: { errors },
  reset,
} = useForm<ProfileFormData>({
  resolver: zodResolver(profileSchema),
  defaultValues: { email: user?.email || '' }
})
```

### Real-time Updates

- **Query Invalidation**: Automatic refetch after mutations
- **Optimistic Updates**: Immediate UI feedback
- **Background Sync**: Periodic data refresh
- **Cache Management**: Intelligent cache invalidation

---

## Error Handling

### Global Error Handling
```typescript
// Axios Response Interceptor
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    // 401: Auto-logout and redirect
    if (error.response?.status === 401) {
      localStorage.clear()
      window.location.href = '/login'
    }
    
    // Comprehensive error logging
    console.log('API Error Details:', {
      status: error.response?.status,
      data: error.response?.data,
      url: error.config?.url
    })
    
    return Promise.reject(error)
  }
)
```

### Component-Level Error Handling
```typescript
// React Query mutation error handling
const updateProfileMutation = useMutation({
  mutationFn: updateProfile,
  onError: (error: any) => {
    const message = error.response?.data?.message || 'Update failed'
    toast.error(message)
  },
  onSuccess: () => {
    toast.success('Profile updated successfully!')
  }
})
```

### Error Types Handled
- **Network Errors**: Connection timeouts, network unavailability
- **Authentication Errors**: Invalid tokens, expired sessions
- **Authorization Errors**: Insufficient permissions
- **Validation Errors**: Form validation, server-side validation
- **Server Errors**: 500+ status codes
- **Client Errors**: 400+ status codes

---

## State Management

### Auth Context
```typescript
interface AuthContextType {
  user: User | null
  permissions: UserPermissions | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (credentials: LoginRequest) => Promise<void>
  logout: () => void
  hasPermission: (permission: keyof UserPermissions) => boolean
  hasRole: (role: UserRole | UserRole[]) => boolean
}
```

### Local Storage Management
- **Token**: JWT authentication token
- **User**: Complete user object with profile data
- **Permissions**: User permission object for role-based access

### Query Cache Management
- **Automatic**: React Query handles most caching
- **Manual Invalidation**: Strategic cache invalidation after mutations
- **Background Updates**: Automatic refetching of stale data

---

## Security Implementation

### Authentication Security
- **JWT Tokens**: Secure token-based authentication  
- **Automatic Expiry**: Tokens expire and redirect to login
- **Secure Storage**: Tokens stored in localStorage (client-side only)
- **Request Security**: All API requests include Bearer token

### Permission-Based Access Control
```typescript
// Route protection example
<ProtectedRoute 
  requiredPermission="canManageUsers" 
  fallback={<UnauthorizedPage />}
>
  <UsersPage />
</ProtectedRoute>

// Component-level permission checks
{hasPermission('canViewAllActivities') && (
  <ActivitiesButton />
)}
```

### API Security Features
- **CORS Handling**: Proper cross-origin configuration
- **Request Validation**: Client-side and server-side validation
- **Error Message Sanitization**: No sensitive data in error messages
- **Auto-logout on Security Changes**: Profile updates trigger re-authentication

### Data Validation
- **Zod Schemas**: Type-safe validation for all forms
- **Runtime Validation**: Client-side validation before API calls
- **Server Validation**: Backend validation for all endpoints

### Security Best Practices Implemented
1. **No Sensitive Data in URLs**: All sensitive data in request bodies
2. **Proper Error Handling**: No information leakage in error messages
3. **Token Management**: Automatic cleanup on logout/error
4. **Permission Checks**: Multi-layer permission validation
5. **Input Sanitization**: All user inputs validated and sanitized

---

## Integration Patterns

### Mutation Pattern
```typescript
const updateUser = useMutation({
  mutationFn: (data) => userApi.update(userId, data),
  onSuccess: () => {
    queryClient.invalidateQueries(['users'])
    toast.success('User updated!')
  },
  onError: (error) => {
    toast.error(error.message)
  }
})
```

### Query Pattern with Parameters
```typescript
const { data: activities, isLoading } = useQuery({
  queryKey: ['activities', 'user', userId, filters],
  queryFn: () => activityApi.getUserActivities(userId, filters),
  enabled: !!userId
})
```

### Optimistic Updates Pattern
```typescript
const updateProfile = useMutation({
  mutationFn: updateProfileApi,
  onMutate: async (newData) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries(['profile'])
    
    // Snapshot previous value
    const previousProfile = queryClient.getQueryData(['profile'])
    
    // Optimistically update cache
    queryClient.setQueryData(['profile'], old => ({...old, ...newData}))
    
    return { previousProfile }
  },
  onError: (err, newData, context) => {
    // Rollback on error
    queryClient.setQueryData(['profile'], context.previousProfile)
  },
  onSettled: () => {
    // Always refetch after error or success
    queryClient.invalidateQueries(['profile'])
  }
})
```

---

This documentation covers all aspects of API integration in the React Productivity Tracker Frontend, providing developers with comprehensive information about authentication, data flow, error handling, and security implementation.
