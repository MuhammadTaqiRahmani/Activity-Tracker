# Organizational Employee Productivity Tracking System
## Project Report

## 1. Project Overview
The Organizational Employee Productivity Tracking System is a comprehensive solution designed to monitor and analyze employee activities, productivity, and performance in real-time. The system consists of two main components:
- Backend Server (Spring Boot)
- Frontend Server (Flask)

## 2. System Architecture

### 2.1 Backend Server (Spring Boot)
- **Framework**: Spring Boot 3.4.1
- **Database**: Microsoft SQL Server
- **Security**: JWT-based authentication
- **API Style**: RESTful

#### Core Modules:
1. User Management
2. Activity Tracking
3. Process Monitoring
4. Analytics Engine
5. Statistics Generator

#### Key Features:
- JWT Authentication
- Role-based access control
- Real-time activity tracking
- Process monitoring
- Anti-tampering mechanisms
- Comprehensive analytics

### 2.2 Frontend Server (Flask)
- **Framework**: Flask
- **Template Engine**: Jinja2
- **Session Management**: Flask-Session
- **HTTP Client**: Requests library

#### Core Routes:
```python
@app.route('/')                 # Dashboard
@app.route('/Register')         # User Registration
@app.route('/Login')           # User Login
@app.route('/Profile')         # User Profile
@app.route('/Tables')          # Activity Tables
@app.route('/Charts')          # Analytics Charts
```

#### API Integration:
```python
# Example of API integration in Flask
@app.route('/activities')
@login_required
def activities():
    token = session.get('token')
    headers = {'Authorization': f'Bearer {token}'}
    
    response = requests.get(
        f"{BACKEND_URL}/api/activities/today",
        headers=headers
    )
    
    return render_template(
        'activities.html',
        activities=response.json()
    )
```

### 2.3 Frontend Templates

#### Template Structure:
```
templates/
├── base.html          # Base template
├── index.html         # Dashboard
├── login.html         # Login page
├── register.html      # Registration page
├── profile.html       # User profile
├── activities.html    # Activity tracking
├── charts.html        # Analytics charts
└── components/        # Reusable components
```

#### Key Features:
- Responsive design
- Real-time updates
- Interactive charts
- Data tables
- Form validation
- Error handling

## 3. Implementation Details

### 3.1 Backend APIs

#### User Management:
- Registration
- Authentication
- Profile management
- Role-based access

#### Activity Tracking:
- Process monitoring
- Application usage tracking
- Productivity metrics
- Time tracking

#### Analytics:
- Productivity analysis
- Usage patterns
- Performance metrics
- Custom reports

### 3.2 Frontend Integration

#### Authentication Flow:
1. User submits login form
2. Flask server calls backend API
3. JWT token stored in session
4. Token used for subsequent requests

#### Data Display:
1. Frontend requests data
2. Backend processes request
3. Data formatted and displayed
4. Real-time updates via AJAX

## 4. Security Measures

### 4.1 Backend Security:
- JWT Authentication
- Role-based authorization
- Password encryption
- CORS configuration
- Anti-tampering mechanisms

### 4.2 Frontend Security:
- Session management
- CSRF protection
- Input validation
- Error handling
- Secure communication

## 5. Database Schema

### Core Tables:
```sql
-- Users Table
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    username VARCHAR(255),
    email VARCHAR(255),
    password VARCHAR(255),
    role VARCHAR(50),
    active BIT
);

-- Activities Table
CREATE TABLE activities (
    id BIGINT PRIMARY KEY,
    user_id BIGINT,
    activity_type VARCHAR(50),
    description TEXT,
    created_at DATETIME2
);

-- Process Tracks Table
CREATE TABLE process_tracks (
    id BIGINT PRIMARY KEY,
    user_id BIGINT,
    process_name VARCHAR(255),
    start_time DATETIME2,
    duration_seconds BIGINT
);
```

## 6. API Documentation

### Base URL: 
```
Backend: http://localhost:8081/api
Frontend: http://localhost:5000
```

### Core Endpoints:
- User Management (`/api/users/*`)
- Activity Tracking (`/api/activities/*`)
- Analytics (`/api/analytics/*`)
- Statistics (`/api/stats/*`)

## 7. Frontend Pages

### Dashboard:
- Activity overview
- Quick statistics
- Recent activities
- Performance metrics

### Activity Tracking:
- Process list
- Application usage
- Time tracking
- Productivity metrics

### Analytics:
- Performance charts
- Usage patterns
- Productivity trends
- Custom reports

## 8. Testing

### Backend Tests:
- Unit tests
- Integration tests
- API tests
- Security tests

### Frontend Tests:
- Route testing
- Form validation
- API integration
- User flow testing

## 9. Deployment

### Requirements:
- Java 21
- Python 3.8+
- SQL Server
- Maven
- pip

### Configuration:
- Database settings
- JWT settings
- CORS configuration
- Logging settings

## 10. Future Enhancements

### Planned Features:
1. Team management
2. Advanced analytics
3. Custom reporting
4. Mobile support
5. Real-time notifications

### Technical Improvements:
1. Caching system
2. Performance optimization
3. Enhanced security
4. Scalability improvements

## 11. Conclusion
The system successfully implements comprehensive employee activity tracking with a secure, scalable architecture. The combination of Spring Boot backend and Flask frontend provides a robust and user-friendly solution for organizational productivity monitoring.
