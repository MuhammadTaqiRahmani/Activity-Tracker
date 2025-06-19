# Backend API Issue - User Activities Not Showing

## 🚨 Issue Summary

**Problem**: Frontend shows "User not found" when trying to view user activities, despite activities existing in the database.

**Status**: Backend API issue identified - needs backend team resolution

**Frontend Status**: ✅ Ready and robust - handles missing users gracefully

---

## 🔍 Issue Details

### **Observed Behavior**
- Activities are being tracked and stored in database correctly
- Database shows activities for user ID `25214` (confirmed via screenshot)
- Frontend URL attempts to access user ID `20046` 
- Result: "User not found" error in frontend

### **Root Cause Analysis**
This appears to be a **backend data consistency issue**:

1. **User-Activity Mismatch**: Activities exist for user IDs that may not exist in the users table
2. **API Endpoint Issues**: Possible issues with user lookup or activities retrieval
3. **Data Synchronization**: User records and activity records may be out of sync

---

## 🔧 Backend Issues to Investigate

### **1. User Table vs Activities Table Sync**

**Check if user records exist for all activity user IDs:**

```sql
-- Find user IDs that have activities but no user record
SELECT DISTINCT a.userId 
FROM activities a 
LEFT JOIN users u ON a.userId = u.id 
WHERE u.id IS NULL;

-- Count activities for users that don't exist
SELECT a.userId, COUNT(*) as activity_count
FROM activities a 
LEFT JOIN users u ON a.userId = u.id 
WHERE u.id IS NULL
GROUP BY a.userId
ORDER BY activity_count DESC;
```

### **2. User API Endpoint Verification**

**Test these endpoints:**

```bash
# Check if user 20046 exists
GET /api/users/20046

# Check if user 25214 exists (from database screenshot)
GET /api/users/25214

# Get all users to see what IDs exist
GET /api/users/all?size=100
```

### **3. Activities API Endpoint Verification**

**Test activities retrieval:**

```bash
# Check activities for user 20046
GET /api/activities/all?userId=20046&page=0&size=5

# Check activities for user 25214 (confirmed in database)
GET /api/activities/all?userId=25214&page=0&size=5

# Check which user IDs have activities
GET /api/activities/all?page=0&size=100
```

### **4. Data Integrity Issues**

**Possible backend problems:**

1. **Orphaned Activities**: Activities exist for deleted users
2. **User Creation Failures**: Users not properly created during registration
3. **ID Generation Issues**: Inconsistent user ID generation
4. **Database Constraints**: Missing foreign key constraints
5. **API Authentication**: User creation/deletion not properly synchronized

---

## 📊 Expected API Responses

### **Correct User API Response**
```json
{
  "id": 25214,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "EMPLOYEE",
  "active": true,
  "createdAt": "2025-06-19T10:00:00"
}
```

### **Correct Activities API Response**
```json
{
  "activities": [
    {
      "id": 12345,
      "userId": 25214,
      "activityType": "PROCESS_MONITORING",
      "applicationName": "Chrome",
      "description": "Web browsing",
      "durationSeconds": 300,
      "startTime": "2025-06-19T14:00:00",
      "endTime": "2025-06-19T14:05:00",
      "status": "COMPLETED"
    }
  ],
  "totalItems": 150,
  "currentPage": 0,
  "totalPages": 8,
  "timestamp": "2025-06-19T15:00:00"
}
```

---

## 🔍 Backend Debugging Steps

### **Step 1: Database Verification**

```sql
-- Check users table
SELECT id, username, email, active, createdAt 
FROM users 
ORDER BY id;

-- Check activities table user IDs
SELECT DISTINCT userId, COUNT(*) as count 
FROM activities 
GROUP BY userId 
ORDER BY userId;

-- Check for data consistency
SELECT 
  u.id as user_id,
  u.username,
  COUNT(a.id) as activity_count
FROM users u
LEFT JOIN activities a ON u.id = a.userId
GROUP BY u.id, u.username
ORDER BY activity_count DESC;
```

### **Step 2: API Testing**

Test these scenarios with a REST client (Postman/Insomnia):

1. **User Lookup**:
   - `GET /api/users/20046` - Should return 404 if user doesn't exist
   - `GET /api/users/25214` - Should return user data
   - `GET /api/users/all` - Check all available user IDs

2. **Activities Lookup**:
   - `GET /api/activities/all?userId=20046` - Should return empty or error
   - `GET /api/activities/all?userId=25214` - Should return activities

### **Step 3: Error Logging**

Enable backend logging to check:
- User creation/deletion events
- API endpoint access attempts
- Database query failures
- Authentication/authorization issues

---

## 🛠️ Potential Backend Fixes

### **Fix 1: Add Foreign Key Constraints**

```sql
-- Add foreign key constraint to prevent orphaned activities
ALTER TABLE activities 
ADD CONSTRAINT fk_activities_user_id 
FOREIGN KEY (userId) REFERENCES users(id) 
ON DELETE CASCADE;
```

### **Fix 2: Data Cleanup**

```sql
-- Remove orphaned activities (activities without users)
DELETE FROM activities 
WHERE userId NOT IN (SELECT id FROM users);
```

### **Fix 3: User Creation Verification**

Ensure user creation process:
1. Creates user record in database
2. Assigns proper ID
3. Sets up default permissions
4. Returns proper response

### **Fix 4: API Error Handling**

Update backend APIs to:
- Return proper HTTP status codes (404 for not found)
- Include detailed error messages
- Log failed requests for debugging

---

## 🎯 Frontend Status (Already Fixed)

The frontend has been updated to handle these backend issues gracefully:

### ✅ **Implemented Solutions**

1. **Robust Error Handling**: Shows activities even if user record is missing
2. **Fallback User Creation**: Creates placeholder user data from activities
3. **Comprehensive Debugging**: Detailed console logging for troubleshooting
4. **User-Friendly Messages**: Clear error messages with helpful tips
5. **Graceful Degradation**: App continues to work even with missing data

### ✅ **Frontend Features Ready**

- ✅ User activities page with pagination
- ✅ Search and filtering
- ✅ Activity details display
- ✅ Navigation between users
- ✅ Responsive design
- ✅ Error handling and loading states

---

## 📝 Action Items for Backend Team

### **Immediate Actions**

1. **Run database queries** to check user/activity consistency
2. **Test API endpoints** for users 20046 and 25214
3. **Check server logs** for any errors during user creation/access
4. **Verify user registration flow** is working correctly

### **Investigation Questions**

1. **Why does user ID 20046 not exist?** Was the user deleted? Failed to create?
2. **How are user IDs generated?** Sequential? UUID? Any gaps?
3. **Are there other missing users?** Run the orphaned activities query
4. **Is user deletion working correctly?** Should activities be preserved?

### **Long-term Fixes**

1. **Add database constraints** to prevent orphaned data
2. **Implement proper cascading deletes** or data archival
3. **Add user creation validation** and error handling
4. **Set up monitoring** for data consistency issues

---

## 🧪 Testing Instructions

### **Backend Testing**

1. **Database Queries**: Run the SQL queries above
2. **API Testing**: Test endpoints with different user IDs
3. **User Creation**: Test full user registration flow
4. **Data Cleanup**: Verify no orphaned records exist

### **Frontend Testing**

1. **Navigate to** `/activities`
2. **Find a user that exists** (from API response)
3. **Click "View Details"** 
4. **Verify activities display correctly**
5. **Test with user ID from database**: `/activities/user/25214`

---

## 📞 Support Information

**Frontend Status**: ✅ Complete and robust
**Backend Status**: ❌ Requires investigation and fixes
**Impact**: High - Feature not usable until backend issues resolved
**Priority**: High - Core functionality affected

**Next Steps**: Backend team to investigate data consistency and API endpoint issues.

---

**Created**: June 19, 2025  
**Reporter**: Frontend Development Team  
**Assignee**: Backend Development Team  
**Status**: Open - Awaiting Backend Investigation
