# 1. Register a test user
curl -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123","email":"test@example.com","role":"EMPLOYEE"}'

# 2. Login and get JWT token
curl -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'

# 3. Simulate keystroke activity
curl -X POST "http://localhost:8080/api/test/tracking/simulate-keystroke?userId=1" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# 4. Simulate application usage
curl -X POST "http://localhost:8080/api/test/tracking/simulate-app-usage?userId=1&appName=VS%20Code&duration=3600" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# 5. Get daily report
curl -X GET "http://localhost:8080/api/test/tracking/simulate-daily-report?userId=1" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# 6. Get productive time
curl -X GET "http://localhost:8080/api/activities/productive-time?userId=1" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# 7. Get application usage statistics
curl -X GET "http://localhost:8080/api/activities/application-usage?userId=1" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
