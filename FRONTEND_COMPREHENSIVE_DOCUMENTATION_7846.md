# Frontend Documentation - ProductivityTracker

## Overview
This document provides comprehensive documentation for the ProductivityTracker React frontend application, including architecture, API communication patterns, components, and specific implementation details.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [API Communication](#api-communication)
3. [Profile API Endpoints](#profile-api-endpoints)
4. [Authentication System](#authentication-system)
5. [State Management](#state-management)
6. [Component Structure](#component-structure)
7. [Styling & Theming](#styling--theming)
8. [Error Handling](#error-handling)
9. [Build & Development](#build--development)

---

## Architecture Overview

### Tech Stack
- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **State Management**: TanStack Query (React Query) + React Context
- **Styling**: Tailwind CSS with custom dark theme
- **Form Handling**: React Hook Form with Zod validation
- **HTTP Client**: Axios
- **Notifications**: Sonner (toast notifications)
- **Icons**: Lucide React
- **Routing**: React Router v6

### Project Structure
```
frontend/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── Auth/           # Authentication components
│   │   ├── Layout/         # Layout components (Header, Sidebar)
│   │   └── UI/             # Base UI components (Button, Input, etc.)
│   ├── contexts/           # React contexts (Auth, Theme)
│   ├── hooks/              # Custom React hooks
│   ├── lib/                # Utility libraries
│   │   ├── api.ts          # API client configuration
│   │   ├── utils.ts        # Utility functions
│   │   └── constants.ts    # Application constants
│   ├── pages/              # Page components
│   ├── types/              # TypeScript type definitions
│   └── styles/             # Global styles
├── public/                 # Static assets
└── dist/                   # Production build output
```

---

## API Communication

### Base Configuration
```typescript
// Base API instance configuration
const api = axios.create({
  baseURL: 'http://localhost:8081/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})
```

### Authentication Flow
1. **Request Interceptor**: Automatically adds JWT token to all requests
2. **Response Interceptor**: Handles authentication errors and token expiration
3. **Error Handling**: Silent error handling for expected 403s, vocal for 401s

### API Structure
The API is organized into modular services:

```typescript
// Authentication API
export const authApi = {
  login: (data: LoginRequest) => Promise<LoginResponse>
  register: (data: RegisterRequest) => Promise<User>
  getProfile: () => Promise<User>
  updateProfile: (data: Partial<User>) => Promise<User>
  changePassword: (data: PasswordChangeRequest) => Promise<{ message: string }>
  validateToken: () => Promise<{ valid: boolean }>
}

// User Management API
export const userApi = {
  getAll: (params) => Promise<UsersAllResponse>
  getById: (id: number) => Promise<User>
  update: (id: number, data: Partial<User>) => Promise<User>
  deactivate: (id: number) => Promise<{ message: string }>
  list: () => Promise<User[]>
}

// Activity Tracking API
export const activityApi = {
  getTodaysActivities: () => Promise<Activity[]>
  getUserActivities: (userId: number, dateRange?: DateRange) => Promise<Activity[]>
  getAllActivities: (params) => Promise<PaginatedResponse<Activity>>
  logActivity: (data: Partial<Activity>) => Promise<Activity>
  getSummary: (userId: number, dateRange: DateRange) => Promise<ActivitySummary>
}

// Analytics API
export const analyticsApi = {
  getUserStats: (userId: number) => Promise<UserStats>
  getSystemOverview: () => Promise<SystemAnalytics>
  getSystemStatus: () => Promise<SystemStatus>
}
```

---

## Profile API Endpoints

### GET /api/users/profile

**Purpose**: Retrieve the current user's profile information

**Usage in Frontend**:
```typescript
// In AuthContext.tsx - Used for user profile queries
const profileQuery = useQuery({
  queryKey: ['user-profile'],
  queryFn: authApi.getProfile,
  enabled: !!token,
  retry: (failureCount, error) => {
    // Don't retry on 401 (unauthorized) or 403 (forbidden)
    if (error?.response?.status === 401 || error?.response?.status === 403) {
      return false
    }
    return failureCount < 3
  },
  meta: {
    silent: true // Prevents automatic error toasts for expected 403s
  }
})
```

**Request Headers**:
```
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
```

**Response Format**:
```typescript
interface User {
  id: number
  username: string
  email: string
  fullName?: string
  role: 'EMPLOYEE' | 'ADMIN' | 'SUPERADMIN'
  active: boolean
  createdAt?: string
}
```

**Error Handling**:
- **401 Unauthorized**: Token expired or invalid - redirects to login
- **403 Forbidden**: User doesn't have permission - handled silently for employees
- **500 Internal Server Error**: Server error - logged for debugging

### PUT /api/users/profile

**Purpose**: Update the current user's profile information

**Usage in Frontend**:
```typescript
// In ProfilePage.tsx - Profile update mutation
const updateProfileMutation = useMutation({
  mutationFn: async (data: Partial<User>) => {
    console.log('🔄 authApi.updateProfile called with data:', data);
    console.log('🔄 Making PUT request to: /users/profile');
    
    const result = await authApi.updateProfile(data)
    
    console.log('✅ authApi.updateProfile result:', result);
    return result
  },
  onSuccess: (updatedUser) => {
    // Update the user in context and refresh profile query
    setUser(updatedUser)
    queryClient.invalidateQueries({ queryKey: ['user-profile'] })
    toast.success('Profile updated successfully!')
  },
  onError: (error) => {
    console.error('Profile update failed:', error)
    toast.error('Failed to update profile')
  }
})
```

**Request Format**:
```typescript
// PUT /api/users/profile
{
  "email": "newemail@example.com",
  "fullName": "Updated Full Name"
  // Only include fields that need to be updated
}
```

**Request Headers**:
```
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
```

**Response Format**:
```typescript
// Returns the updated user object
{
  "id": 1,
  "username": "employee_test",
  "email": "newemail@example.com",
  "fullName": "Updated Full Name",
  "role": "EMPLOYEE",
  "active": true,
  "createdAt": "2025-06-19T10:30:00Z"
}
```

**Validation & Constraints**:
- **Email**: Must be valid email format and unique across all users
- **Full Name**: Optional field, string up to 255 characters
- **Role**: Cannot be updated via this endpoint (admin-only operation)
- **Username**: Cannot be updated via this endpoint (immutable)

**Error Scenarios**:
- **400 Bad Request**: Invalid data format or validation errors
- **401 Unauthorized**: Token expired or invalid
- **403 Forbidden**: Employee trying to update restricted fields
- **409 Conflict**: Email already exists for another user
- **500 Internal Server Error**: Database or server error

### Role-Based Access Control

**Employee Profile Updates**:
- ✅ Can update: `email`, `fullName`
- ❌ Cannot update: `role`, `username`, `active`, `id`
- Uses `authApi.updateProfile()` → `PUT /api/users/profile`

**Admin/SuperAdmin Profile Management**:
- ✅ Can update any user via: `userApi.update(id, data)` → `PUT /api/users/{id}`
- ✅ Can update all fields including role and active status
- ✅ Can deactivate users via: `userApi.deactivate(id)` → `POST /api/users/deactivate/{id}`

---

## Authentication System

### Context-Based Authentication
The application uses a centralized `AuthContext` that manages:

```typescript
interface AuthContextType {
  user: User | null                    // Current user data
  permissions: UserPermissions | null  // User permissions based on role
  isLoading: boolean                   // Loading state
  isAuthenticated: boolean             // Authentication status
  login: (credentials: LoginRequest) => Promise<void>
  logout: () => void
  hasPermission: (permission: keyof UserPermissions) => boolean
}
```

### Role-Based Permissions
```typescript
interface UserPermissions {
  canTrackProcesses: boolean           // Track activities and processes
  canViewOwnStats: boolean            // View personal analytics
  canViewAllUsers: boolean            // Access user management
  canViewAllActivities: boolean       // View all user activities
  canManageUsers: boolean             // Create/edit/deactivate users
  canCreateEmployees: boolean         // Create employee accounts
  canCreateAdmins: boolean            // Create admin accounts (SuperAdmin only)
  canManageAdmins: boolean            // Manage admin accounts
  canAccessSystemSettings: boolean    // Access system configuration
}
```

### Permission Mapping by Role
- **EMPLOYEE**: Basic tracking and personal stats only
- **ADMIN**: All employee permissions + user management (except admin creation)
- **SUPERADMIN**: All permissions including admin management and system settings

### Token Management
- **Storage**: JWT tokens stored in `localStorage`
- **Expiration**: Automatic logout on token expiration (401 responses)
- **Validation**: Token validation on app initialization
- **Refresh**: Manual re-authentication required (no refresh tokens)

---

## State Management

### TanStack Query (React Query)
Used for server state management with intelligent caching:

```typescript
// Profile data caching
const profileQuery = useQuery({
  queryKey: ['user-profile'],
  queryFn: authApi.getProfile,
  enabled: !!token,
  staleTime: 5 * 60 * 1000,  // 5 minutes
  retry: (failureCount, error) => {
    if (error?.response?.status === 401 || error?.response?.status === 403) {
      return false
    }
    return failureCount < 3
  }
})

// Profile update mutation
const updateMutation = useMutation({
  mutationFn: authApi.updateProfile,
  onSuccess: (updatedUser) => {
    queryClient.setQueryData(['user-profile'], updatedUser)
    queryClient.invalidateQueries({ queryKey: ['user-profile'] })
  }
})
```

### React Context
Used for global application state:
- **AuthContext**: Authentication state and user permissions
- **ThemeContext**: Dark/light theme preferences

### Local State
Component-level state managed with `useState` and `useReducer` for:
- Form inputs and validation
- UI state (modals, loading states)
- Component-specific data

---

## Component Structure

### Layout Components
```typescript
// Header.tsx - Navigation and user menu
interface HeaderProps {
  // Contains search, notifications, theme toggle, user profile
}

// Sidebar.tsx - Navigation menu
interface SidebarProps {
  // Role-based navigation items
  // Responsive design with mobile support
}
```

### Page Components
- **DashboardPage**: Main overview with metrics and quick actions
- **ProfilePage**: User profile management with role-based editing
- **UsersPageSimple**: User management for admins
- **ActivitiesPage**: Activity tracking and logs
- **AnalyticsPage**: Analytics and reporting
- **SettingsPage**: Application settings

### Authentication Components
- **LoginPage**: User authentication form
- **RegisterPage**: New user registration (admin only)
- **ProtectedRoute**: Route protection based on permissions

### UI Components
- **Button**: Consistent button styling with loading states
- **Input**: Form inputs with validation support
- **Modal**: Reusable modal component
- **Toast**: Notification system integration

---

## Styling & Theming

### Tailwind CSS Configuration
Custom color palette with separate configurations for headings and content:

```javascript
// tailwind.config.js
theme: {
  extend: {
    colors: {
      // Primary application colors
      primary: {
        DEFAULT: '#0066CC',  // Enterprise blue
        dark: '#58A6FF',     // Dark mode primary
      },
      
      // Background colors
      background: {
        DEFAULT: '#F7F9FC',  // Light theme background
        dark: '#0D1117',     // Dark theme background
      },
      
      // Text colors - General
      text: {
        primary: '#1F2937',
        secondary: '#6B7280',
        'primary-dark': '#F3F4F6',
        'secondary-dark': '#9CA3AF',
      },
      
      // Text colors - Headings (Dark blue theme)
      heading: {
        primary: '#1E3A8A',      // Dark blue for light theme
        secondary: '#374151',    // Dark gray for light theme
        'primary-dark': '#1E40AF',    // Rich blue for dark theme
        'secondary-dark': '#4B5563',  // Medium dark gray for dark theme
      },
      
      // Text colors - Content (Medium contrast)
      content: {
        primary: '#1F2937',      // Dark slate for light theme
        secondary: '#4B5563',    // Medium gray for light theme
        'primary-dark': '#1E40AF',    // Rich blue for dark theme
        'secondary-dark': '#6B7280',  // Lighter gray for dark theme
      },
    }
  }
}
```

### Theme Usage Examples
```tsx
// Main page headings
<h1 className="text-3xl font-bold text-heading-primary dark:text-heading-primary-dark">
  Welcome back, {user?.username}!
</h1>

// Content paragraphs
<p className="text-content-secondary dark:text-content-secondary-dark mt-1">
  Here's your productivity overview for today
</p>

// Section headings
<h2 className="text-xl font-semibold text-heading-primary dark:text-heading-primary-dark">
  Recent Activities
</h2>
```

### Dark Theme Implementation
- **Toggle**: Available in header for instant theme switching
- **Persistence**: Theme preference saved to localStorage
- **System**: Respects system dark mode preference by default
- **Comprehensive**: All components support both light and dark themes

---

## Error Handling

### API Error Handling Strategy
```typescript
// Response interceptor with intelligent error handling
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    // Critical authentication errors - show toast and redirect
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      localStorage.removeItem('permissions')
      
      if (window.location.pathname !== '/login') {
        toast.error('Session expired. Please login again.')
        window.location.href = '/login'
      }
    }
    
    // Expected errors (403, 500, timeouts) - handle silently
    // Let components decide when to show user-facing errors
    
    return Promise.reject(error)
  }
)
```

### Component-Level Error Handling
```typescript
// Query error handling with user-friendly messages
const { data: users, error, isLoading } = useQuery({
  queryKey: ['users'],
  queryFn: userApi.getAll,
  onError: (error) => {
    // Show toast only for unexpected errors
    if (error.response?.status !== 403) {
      toast.error('Failed to load users')
    }
  }
})

// Form submission error handling
const handleSubmit = async (data: FormData) => {
  try {
    await mutation.mutateAsync(data)
  } catch (error) {
    // Specific error handling based on status codes
    if (error.response?.status === 409) {
      toast.error('Email already exists')
    } else if (error.response?.status === 400) {
      toast.error('Invalid data provided')
    } else {
      toast.error('An unexpected error occurred')
    }
  }
}
```

### Error Boundaries
React Error Boundaries implemented for:
- Component rendering errors
- Route-level error handling
- Graceful fallback UI

---

## Build & Development

### Development Setup
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run with specific port
npm run dev -- --port 3000
```

### Build Process
```bash
# Production build
npm run build

# Preview production build
npm run preview

# Type checking
npm run type-check

# Linting
npm run lint
```

### Environment Configuration
```env
# .env.development
VITE_API_BASE_URL=http://localhost:8081/api
VITE_APP_TITLE=ProductivityTracker

# .env.production
VITE_API_BASE_URL=https://api.productivitytracker.com/api
VITE_APP_TITLE=ProductivityTracker
```

### Build Optimization
- **Code Splitting**: Automatic route-based code splitting
- **Tree Shaking**: Dead code elimination
- **Asset Optimization**: Image and CSS optimization
- **Bundle Analysis**: Webpack bundle analyzer integration

---

## API Communication Patterns

### Query Patterns
```typescript
// Basic data fetching
const { data, isLoading, error } = useQuery({
  queryKey: ['users'],
  queryFn: userApi.getAll
})

// Parameterized queries
const { data: userActivities } = useQuery({
  queryKey: ['activities', userId, dateRange],
  queryFn: () => activityApi.getUserActivities(userId, dateRange),
  enabled: !!userId
})

// Dependent queries
const { data: profile } = useQuery({
  queryKey: ['profile'],
  queryFn: authApi.getProfile,
  enabled: isAuthenticated
})
```

### Mutation Patterns
```typescript
// Basic mutations
const createUserMutation = useMutation({
  mutationFn: userApi.create,
  onSuccess: () => {
    queryClient.invalidateQueries(['users'])
    toast.success('User created successfully')
  },
  onError: (error) => {
    toast.error('Failed to create user')
  }
})

// Optimistic updates
const updateUserMutation = useMutation({
  mutationFn: ({ id, data }) => userApi.update(id, data),
  onMutate: async ({ id, data }) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries(['users'])
    
    // Optimistically update
    const previousUsers = queryClient.getQueryData(['users'])
    queryClient.setQueryData(['users'], (old) => 
      old?.map(user => user.id === id ? { ...user, ...data } : user)
    )
    
    return { previousUsers }
  },
  onError: (err, variables, context) => {
    // Rollback on error
    queryClient.setQueryData(['users'], context.previousUsers)
  },
  onSettled: () => {
    // Always refetch after error or success
    queryClient.invalidateQueries(['users'])
  }
})
```

---

## Security Considerations

### Authentication Security
- **JWT Tokens**: Secure token-based authentication
- **Token Expiration**: Automatic logout on token expiration
- **HTTPS Only**: All API communication over HTTPS in production
- **XSS Protection**: Sanitized user inputs and secure token storage

### Authorization Patterns
```typescript
// Route-level protection
<ProtectedRoute requiredPermission="canManageUsers">
  <UsersPage />
</ProtectedRoute>

// Component-level permission checks
{hasPermission('canCreateEmployees') && (
  <Button onClick={handleCreateEmployee}>
    Create Employee
  </Button>
)}

// Conditional rendering based on role
{user?.role === 'SUPERADMIN' && (
  <AdminPanel />
)}
```

### Data Validation
- **Frontend Validation**: Zod schemas for form validation
- **Backend Validation**: Server-side validation for all endpoints
- **Type Safety**: Full TypeScript coverage for API contracts

---

## Performance Optimizations

### React Query Optimizations
```typescript
// Intelligent caching with background updates
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,     // 5 minutes
      cacheTime: 10 * 60 * 1000,    // 10 minutes
      refetchOnWindowFocus: false,   // Prevent excessive refetching
      retry: (failureCount, error) => {
        // Smart retry logic based on error types
        return error.status >= 500 && failureCount < 3
      }
    }
  }
})
```

### Component Optimizations
- **React.memo**: Prevent unnecessary re-renders
- **useCallback**: Memoize event handlers
- **useMemo**: Memoize expensive calculations
- **Lazy Loading**: Route-based code splitting

### Bundle Optimizations
- **Tree Shaking**: Remove unused code
- **Code Splitting**: Load code on demand
- **Asset Optimization**: Compress images and fonts
- **CDN Integration**: Serve static assets from CDN

---

## Testing Strategy

### Testing Stack
- **Unit Tests**: Jest + React Testing Library
- **Integration Tests**: API integration testing
- **E2E Tests**: Cypress for critical user flows
- **Type Checking**: TypeScript for compile-time safety

### Test Patterns
```typescript
// Component testing
test('renders user profile correctly', () => {
  render(<ProfilePage />, { wrapper: AuthProvider })
  expect(screen.getByText('Profile')).toBeInTheDocument()
})

// API testing
test('updates user profile', async () => {
  const mockUser = { id: 1, email: 'test@example.com' }
  const { result } = renderHook(() => useUpdateProfile())
  
  await act(async () => {
    await result.current.mutateAsync(mockUser)
  })
  
  expect(mockUpdateProfile).toHaveBeenCalledWith(mockUser)
})
```

---

## Deployment

### Production Build
```bash
# Create production build
npm run build

# Serve static files
npm run preview
```

### Environment Variables
```env
# Production configuration
VITE_API_BASE_URL=https://api.productivitytracker.com/api
VITE_APP_TITLE=ProductivityTracker - Production
VITE_ENABLE_ANALYTICS=true
```

### CI/CD Pipeline
```yaml
# Example GitHub Actions workflow
name: Frontend CI/CD
on:
  push:
    branches: [main]
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install dependencies
        run: npm ci
      - name: Run tests
        run: npm test
      - name: Build application
        run: npm run build
      - name: Deploy to production
        run: npm run deploy
```

---

## Troubleshooting

### Common Issues

**Profile Update Failures**:
```bash
# Check API endpoint availability
curl -X GET http://localhost:8081/api/users/profile \
  -H "Authorization: Bearer YOUR_TOKEN"

# Verify token validity
curl -X POST http://localhost:8081/api/security/validate-token \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**CORS Issues**:
- Ensure backend CORS configuration allows frontend origin
- Check browser network tab for preflight OPTIONS requests
- Verify API base URL configuration

**Authentication Problems**:
- Clear localStorage and retry authentication
- Check token expiration in JWT payload
- Verify backend authentication endpoint functionality

### Debug Mode
```typescript
// Enable detailed API logging
const api = axios.create({
  baseURL: 'http://localhost:8081/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add request/response logging
api.interceptors.request.use(request => {
  console.log('API Request:', request)
  return request
})

api.interceptors.response.use(
  response => {
    console.log('API Response:', response)
    return response
  },
  error => {
    console.error('API Error:', error.response || error)
    return Promise.reject(error)
  }
)
```

---

## Contributing

### Code Style
- **ESLint**: Enforce code style and best practices
- **Prettier**: Automatic code formatting
- **TypeScript**: Strict type checking enabled
- **Conventional Commits**: Standardized commit messages

### Development Workflow
1. Create feature branch from `main`
2. Implement changes with tests
3. Run linting and type checking
4. Submit pull request with description
5. Code review and approval
6. Merge to main branch

### Pull Request Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] E2E tests pass

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
```

---

This documentation provides a comprehensive overview of the ProductivityTracker frontend application, with special attention to the profile API communication patterns you requested. The application follows modern React best practices with a focus on type safety, performance, and maintainable code architecture.
