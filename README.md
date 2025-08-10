# Employee Productivity Tracking System

[![Status](https://img.shields.io/badge/status-production%20ready-green.svg)](https://github.com/your-repo/activity-tracker)
[![Java](https://img.shields.io/badge/Java-17%2B-orange.svg)](https://openjdk.java.net/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![React](https://img.shields.io/badge/React-18.2.0-blue.svg)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.2.2-blue.svg)](https://www.typescriptlang.org/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2019%2B-red.svg)](https://www.microsoft.com/en-us/sql-server)

A comprehensive full-stack web application designed to monitor, analyze, and optimize employee productivity across organizations. The system combines a robust Spring Boot backend with a modern React frontend to deliver real-time activity tracking, detailed analytics, and powerful administrative tools.

## 🎯 Key Features

### 📊 **Activity Tracking**
- **Real-time Monitoring**: Track user activities, applications, and processes in real-time
- **Comprehensive Logging**: Capture detailed activity data including timestamps, applications, and descriptions
- **Process Monitoring**: Monitor system processes and resource usage
- **Data Integrity**: Built-in tamper detection and hash validation

### 👥 **User Management**
- **Role-based Access Control**: 3-tier role system (Employee, Admin, SuperAdmin)
- **User Administration**: Complete user lifecycle management
- **Profile Management**: Self-service profile updates for all users
- **Secure Authentication**: JWT-based authentication with BCrypt password hashing

### 📋 **Task Management**
- **Task Assignment**: Create and assign tasks to team members
- **Status Tracking**: Monitor task progress with detailed status updates
- **Due Date Management**: Track deadlines and priorities
- **Team Collaboration**: Streamlined task workflows

### 📈 **Analytics & Reporting**
- **Real-time Dashboards**: Interactive charts and visualizations
- **Productivity Metrics**: Comprehensive analytics on user activities
- **System Statistics**: Monitor overall platform usage and performance
- **Export Capabilities**: Generate reports for management review

### 🔐 **Security & Compliance**
- **Enterprise Security**: JWT tokens with role-based permissions
- **Data Protection**: Foreign key constraints and validation
- **Audit Trail**: Complete activity logging for compliance
- **Password Security**: Industry-standard BCrypt encryption

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT APPLICATIONS                      │
├─────────────────────────────────────────────────────────────┤
│  React Frontend  │  Desktop Client  │  Mobile App  │  APIs   │
│  (Port 3000)     │  (Future)        │  (Future)    │         │
└─────────────────┴──────────────────┴──────────────┴─────────┘
                              │ HTTP/HTTPS
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  SPRING BOOT APPLICATION                    │
│                      (Port 8080)                           │
├─────────────────────┬───────────────────┬───────────────────┤
│   AUTHENTICATION    │   BUSINESS LOGIC  │   DATA ACCESS     │
│   - JWT Tokens      │   - Activity Log  │   - JPA/Hibernate │
│   - Role-based Auth │   - User Mgmt     │   - Repositories  │
│   - Session Mgmt    │   - Task Mgmt     │   - Transactions  │
└─────────────────────┴───────────────────┴───────────────────┘
                              │ JDBC
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   SQL SERVER DATABASE                      │
├─────────────────────────────────────────────────────────────┤
│  Users │ Activities │ Tasks │ Process_Tracks │ Audit_Logs   │
│  (67)  │  (12,469)  │ (45)  │   (tracking)   │ (audit trail)│
└─────────────────────────────────────────────────────────────┘
```

## 💻 Technology Stack

### **Frontend**
- **React 18.2.0** - Modern React with Concurrent Features
- **TypeScript 5.2.2** - Type-safe development
- **Vite 5.0.0** - Fast build tool and dev server
- **Tailwind CSS 3.3.6** - Utility-first styling
- **React Query 5.13.4** - Server state management
- **React Router DOM 6.20.1** - Client-side routing
- **Radix UI** - Accessible component library

### **Backend**
- **Spring Boot 3.x** - Enterprise Java framework
- **Java 17+** - Modern Java with latest features
- **Spring Security 6.x** - Authentication & authorization
- **Spring Data JPA** - Data access abstraction
- **Maven** - Build management
- **JWT** - Stateless authentication

### **Database**
- **Microsoft SQL Server** - Primary database
- **HikariCP** - Connection pooling
- **Foreign Key Constraints** - Data integrity
- **Performance Indexes** - Query optimization

## 🚀 Quick Start

### Prerequisites
- Java 17 or higher
- Node.js 18 or higher
- SQL Server 2019 or higher
- Maven 3.6 or higher

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-repo/activity-tracker.git
   cd activity-tracker
   ```

2. **Set up the database**
   ```powershell
   # Run the database setup script
   .\recreate-database.ps1
   ```

3. **Configure application properties**
   ```bash
   # Update src/main/resources/application.properties
   spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=ActivityTrackerDB
   spring.datasource.username=your_username
   spring.datasource.password=your_password
   ```

4. **Start the backend**
   ```powershell
   # Build and start the Spring Boot application
   .\build-and-start.bat
   ```

5. **Start the frontend**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

6. **Access the application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080
   - API Documentation: http://localhost:8080/swagger-ui.html

### Initial Setup

1. **Create an admin user**
   ```powershell
   .\create-admin.ps1
   ```

2. **Log in to the system**
   - Use the admin credentials created in step 1
   - Access the admin dashboard to create additional users

## 📁 Project Structure

```
Activity-Tracker/
├── src/main/java/com/example/backendapp/    # Spring Boot backend
│   ├── controller/                          # REST API endpoints
│   ├── service/                            # Business logic
│   ├── repository/                         # Data access layer
│   ├── entity/                             # JPA entities
│   ├── dto/                                # Data transfer objects
│   ├── security/                           # Security configuration
│   └── config/                             # Application configuration
├── frontend/                               # React frontend
│   ├── src/
│   │   ├── components/                     # Reusable UI components
│   │   ├── pages/                          # Route components
│   │   ├── hooks/                          # Custom React hooks
│   │   ├── services/                       # API services
│   │   ├── types/                          # TypeScript types
│   │   └── utils/                          # Utility functions
│   ├── public/                             # Static assets
│   └── package.json                        # Frontend dependencies
├── scripts/                                # PowerShell scripts
├── docs/                                   # Documentation
├── pom.xml                                 # Maven configuration
└── README.md                               # This file
```

## 🔐 User Roles & Permissions

| Permission | Employee | Admin | SuperAdmin |
|------------|----------|-------|------------|
| **View own profile** | ✅ | ✅ | ✅ |
| **Update own profile** | ✅ | ✅ | ✅ |
| **Log activities** | ✅ | ✅ | ✅ |
| **View own activities** | ✅ | ✅ | ✅ |
| **View team activities** | ❌ | ✅ | ✅ |
| **Create tasks** | ❌ | ✅ | ✅ |
| **View all users** | ❌ | ✅ | ✅ |
| **Create employees** | ❌ | ✅ | ✅ |
| **Manage users** | ❌ | ✅ | ✅ |
| **Create admins** | ❌ | ❌ | ✅ |
| **System settings** | ❌ | ✅ | ✅ |
| **Database admin** | ❌ | ❌ | ✅ |

## 📊 System Statistics

- **Total Users**: 67
- **Total Activities**: 12,469
- **Total Tasks**: 45
- **Database Status**: ✅ Optimized with FK constraints
- **Performance**: ✅ Indexed for optimal query performance

## 🛠️ Development

### Backend Development
```bash
# Run tests
mvn test

# Build the application
mvn clean package

# Run with development profile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

### Frontend Development
```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

### Database Management
```powershell
# Recreate database with latest schema
.\recreate-database.ps1

# Check database integrity
.\check-admin-db.sql

# Test database connections
.\test-commands.ps1
```

## 📚 API Documentation

The system provides comprehensive REST APIs for all functionality:

### Authentication
- `POST /api/auth/login` - User authentication
- `POST /api/auth/logout` - User logout
- `GET /api/auth/profile` - Get current user profile

### Activity Management
- `POST /api/activities/log` - Log new activity
- `GET /api/activities/user/{userId}` - Get user activities
- `GET /api/activities/analytics` - Get activity analytics

### User Management
- `GET /api/users` - List all users (Admin+)
- `POST /api/users` - Create new user (Admin+)
- `PUT /api/users/{id}` - Update user (Admin+)
- `DELETE /api/users/{id}` - Delete user (SuperAdmin)

### Task Management
- `GET /api/tasks` - List tasks
- `POST /api/tasks` - Create task (Admin+)
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task (Admin+)

For complete API documentation, visit `/swagger-ui.html` when the application is running.

## 🔧 Configuration

### Environment Variables
```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=1433
DB_NAME=ActivityTrackerDB
DB_USERNAME=your_username
DB_PASSWORD=your_password

# JWT Configuration
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRATION=86400000

# Application Configuration
SERVER_PORT=8080
CLIENT_URL=http://localhost:3000
```

### Production Configuration
```properties
# application-prod.properties
spring.datasource.url=jdbc:sqlserver://prod-server:1433;databaseName=ActivityTrackerDB
spring.jpa.hibernate.ddl-auto=validate
logging.level.com.example.backendapp=WARN
management.endpoints.web.exposure.include=health,info,metrics
```

## 🚀 Deployment

### Docker Deployment (Recommended)
```bash
# Build and run with Docker Compose
docker-compose up -d
```

### Manual Deployment
1. **Build the application**
   ```bash
   mvn clean package -Pprod
   ```

2. **Deploy to server**
   ```bash
   java -jar target/activity-tracker-1.0.0.jar --spring.profiles.active=prod
   ```

3. **Configure reverse proxy** (Nginx/Apache)
4. **Set up SSL certificates**
5. **Configure monitoring and logging**

## 🔍 Monitoring & Troubleshooting

### Health Checks
- Application health: `GET /actuator/health`
- Database connectivity: `GET /actuator/health/db`
- System metrics: `GET /actuator/metrics`

### Logs
- Application logs: `logs/application.log`
- Error logs: `logs/error.log`
- Access logs: `logs/access.log`

### Common Issues
1. **Database connection issues**: Check connection string and credentials
2. **JWT token errors**: Verify secret key configuration
3. **CORS errors**: Update allowed origins in configuration
4. **Performance issues**: Check database indexes and query optimization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Spring Boot best practices
- Write unit tests for new features
- Update documentation for API changes
- Use conventional commit messages
- Ensure code passes linting and tests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support, please contact:
- **Technical Issues**: Create an issue on GitHub
- **Documentation**: Check the `/docs` folder
- **General Questions**: Contact the development team

## 🚀 Roadmap

### Upcoming Features
- [ ] Mobile application (React Native)
- [ ] Desktop client (Electron)
- [ ] Advanced analytics dashboard
- [ ] Real-time notifications
- [ ] Integration with popular productivity tools
- [ ] Advanced reporting features
- [ ] Machine learning-based productivity insights

### Version History
- **v1.0.0** - Initial release with core functionality
- **v1.1.0** - Database optimization and foreign key constraints
- **v1.2.0** - Enhanced user management and role system
- **v1.3.0** - Task management system implementation

---

**Built with ❤️ by the Muhammad Taqi Rahmani**