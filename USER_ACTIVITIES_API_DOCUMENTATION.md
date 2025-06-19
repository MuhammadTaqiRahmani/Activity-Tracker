# User-Specific Activities API Documentation

## Overview
This document provides comprehensive documentation for the User-Specific Activities API endpoint that allows filtering activities by user ID. This is the primary API for frontend implementations that need to display activities for specific users.

## API Endpoint

**GET** `/api/activities/all?userId={id}`

Retrieve all activities for a specific user with pagination and filtering support.

---

## 🎯 **Primary Use Case**

This API is designed for frontend applications that need to:
1. **Display a list of all users** (using `/api/users/all`)
2. **Show activities for a specific user** when clicked (using this API)
3. **Implement user-specific activity dashboards**

**Frontend Flow:**
```
Users List → Click User → Activities for That User Only
```

---

## 📋 **Request Details**

### **HTTP Method**
```
GET
```

### **Base URL**
```
http://localhost:8081/api/activities/all
```

### **Required Headers**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### **Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `userId` | Long | ✅ **Required** | - | The ID of the user whose activities you want to retrieve |
| `page` | Integer | ❌ Optional | 0 | Page number for pagination (0-based) |
| `size` | Integer | ❌ Optional | 10 | Number of activities per page (max: 100) |
| `sortBy` | String | ❌ Optional | "createdAt" | Field to sort by (id, createdAt, startTime, etc.) |
| `sortDirection` | String | ❌ Optional | "desc" | Sort direction ("asc" or "desc") |
| `activityType` | String | ❌ Optional | - | Filter by activity type |
| `applicationCategory` | String | ❌ Optional | - | Filter by application category |

### **Example Requests**

#### **Basic Request**
```http
GET /api/activities/all?userId=20046
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9...
```

#### **With Pagination**
```http
GET /api/activities/all?userId=20046&page=0&size=20
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9...
```

#### **With Sorting**
```http
GET /api/activities/all?userId=20046&sortBy=startTime&sortDirection=desc
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9...
```

#### **With Filtering**
```http
GET /api/activities/all?userId=20046&applicationCategory=DEVELOPMENT&page=0&size=50
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9...
```

---

## 📊 **Response Format**

### **Success Response (200 OK)**

```json
{
  "activities": [
    {
      "id": 24657,
      "userId": 20046,
      "activityType": "PROCESS_MONITORING",
      "description": "Process monitoring: fontdrvhost.exe",
      "applicationName": "fontdrvhost.exe",
      "processName": "fontdrvhost.exe",
      "windowTitle": "fontdrvhost.exe",
      "workspaceType": "LOCAL",
      "durationSeconds": 60,
      "createdAt": "2025-06-19T20:07:36.766489",
      "idleTimeSeconds": null,
      "status": "IDLE",
      "applicationCategory": "OTHER",
      "processId": "20312",
      "ipAddress": "100.112.21.108",
      "machineId": "M. Taqi Rahmani-DESKTOP-FER2L17",
      "tamperAttempt": false,
      "tamperDetails": null,
      "hashValue": "aGDegrv8P/r9ng3tyK2GVNSpqeSMmbC6QJH5TMSPhYc=",
      "startTime": "2025-06-19T20:07:36.751148",
      "endTime": "2025-06-19T20:08:36.751148",
      "version": 0
    }
  ],
  "currentPage": 0,
  "totalItems": 594,
  "totalPages": 60,
  "timestamp": "2025-06-19T20:54:01.6271549"
}
```

### **Response Fields Explanation**

#### **Metadata Fields**
| Field | Type | Description |
|-------|------|-------------|
| `currentPage` | Integer | Current page number (0-based) |
| `totalItems` | Integer | Total number of activities for this user |
| `totalPages` | Integer | Total number of pages available |
| `timestamp` | String | Response generation timestamp |

#### **Activity Fields**
| Field | Type | Description |
|-------|------|-------------|
| `id` | Long | Unique activity identifier |
| `userId` | Long | **User ID (always matches the requested userId)** |
| `activityType` | String | Type of activity (PROCESS_MONITORING, APPLICATION_USAGE, etc.) |
| `description` | String | Human-readable description |
| `applicationName` | String | Name of the application/process |
| `processName` | String | System process name |
| `windowTitle` | String | Window title text |
| `workspaceType` | String | Workspace type (LOCAL, OFFICE, HOME, etc.) |
| `durationSeconds` | Long | Activity duration in seconds |
| `createdAt` | String | When the activity was recorded |
| `startTime` | String | When the activity started |
| `endTime` | String | When the activity ended |
| `status` | String | Activity status (ACTIVE, IDLE, OFFLINE) |
| `applicationCategory` | String | Category (DEVELOPMENT, PRODUCTIVITY, OTHER, etc.) |
| `processId` | String | System process ID |
| `ipAddress` | String | User's IP address during activity |
| `machineId` | String | Unique machine identifier |
| `tamperAttempt` | Boolean | Whether tampering was detected |
| `tamperDetails` | String | Details of any tampering attempts |
| `hashValue` | String | Security hash for integrity verification |
| `idleTimeSeconds` | Long | Idle time during this activity |
| `version` | Long | Entity version for optimistic locking |

---

## 🧪 **API Testing Results**

### **Test Case 1: Existing User with Activities**

**Request:**
```http
GET /api/activities/all?userId=20046&page=0&size=10
```

**Result:**
- ✅ **Status Code:** 200 OK
- ✅ **Total Activities:** 594
- ✅ **User ID Filter:** All activities have `userId: 20046`
- ✅ **Pagination:** Returns 10 activities, totalPages: 60

### **Test Case 2: Different User**

**Request:**
```http
GET /api/activities/all?userId=8&page=0&size=5
```

**Result:**
- ✅ **Status Code:** 200 OK
- ✅ **Total Activities:** 3,350
- ✅ **User ID Filter:** All activities have `userId: 8`
- ✅ **Different Data:** Completely different set of activities

### **Test Case 3: Non-existent User**

**Request:**
```http
GET /api/activities/all?userId=99999&page=0&size=10
```

**Result:**
- ✅ **Status Code:** 200 OK
- ✅ **Total Activities:** 0
- ✅ **Activities Array:** Empty `[]`
- ✅ **Graceful Handling:** No errors, just empty response

---

## 🚨 **Error Responses**

### **401 Unauthorized**
```json
{
  "error": "Authentication required"
}
```
**Cause:** Missing or invalid JWT token

### **403 Forbidden**
```json
{
  "error": "Access denied"
}
```
**Cause:** User doesn't have permission to view activities

### **400 Bad Request**
```json
{
  "error": "Invalid userId parameter"
}
```
**Cause:** userId is not a valid number

### **500 Internal Server Error**
```json
{
  "error": "Failed to fetch activities: <error_message>"
}
```
**Cause:** Server-side error

---

## 💻 **Frontend Implementation Examples**

### **JavaScript/Fetch API**

```javascript
// Function to get activities for a specific user
async function getUserActivities(userId, page = 0, size = 20) {
    try {
        const response = await fetch(
            `/api/activities/all?userId=${userId}&page=${page}&size=${size}&sortBy=createdAt&sortDirection=desc`,
            {
                headers: {
                    'Authorization': `Bearer ${authToken}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Error fetching user activities:', error);
        throw error;
    }
}

// Usage example
getUserActivities(20046, 0, 50)
    .then(data => {
        console.log(`Found ${data.totalItems} activities for user`);
        console.log(`Showing page ${data.currentPage + 1} of ${data.totalPages}`);
        
        data.activities.forEach(activity => {
            console.log(`${activity.applicationName}: ${activity.durationSeconds}s`);
        });
    })
    .catch(error => {
        console.error('Failed to load activities:', error);
    });
```

### **jQuery AJAX**

```javascript
function loadUserActivities(userId, page = 0) {
    $.ajax({
        url: `/api/activities/all?userId=${userId}&page=${page}&size=25`,
        method: 'GET',
        headers: {
            'Authorization': 'Bearer ' + authToken
        },
        success: function(response) {
            displayActivities(response.activities);
            updatePagination(response.currentPage, response.totalPages);
        },
        error: function(xhr, status, error) {
            console.error('Error loading activities:', error);
            alert('Failed to load activities for this user');
        }
    });
}
```

### **React Hook Example**

```javascript
import { useState, useEffect } from 'react';

function useUserActivities(userId, page = 0, size = 20) {
    const [activities, setActivities] = useState([]);
    const [loading, setLoading] = useState(false);
    const [totalItems, setTotalItems] = useState(0);
    const [totalPages, setTotalPages] = useState(0);
    const [error, setError] = useState(null);

    useEffect(() => {
        if (!userId) return;

        const fetchActivities = async () => {
            setLoading(true);
            setError(null);

            try {
                const response = await fetch(
                    `/api/activities/all?userId=${userId}&page=${page}&size=${size}`,
                    {
                        headers: {
                            'Authorization': `Bearer ${authToken}`,
                            'Content-Type': 'application/json'
                        }
                    }
                );

                if (!response.ok) {
                    throw new Error('Failed to fetch activities');
                }

                const data = await response.json();
                setActivities(data.activities);
                setTotalItems(data.totalItems);
                setTotalPages(data.totalPages);
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };

        fetchActivities();
    }, [userId, page, size]);

    return { activities, loading, totalItems, totalPages, error };
}

// Usage in component
function UserActivitiesPage({ userId }) {
    const { activities, loading, totalItems, error } = useUserActivities(userId);

    if (loading) return <div>Loading activities...</div>;
    if (error) return <div>Error: {error}</div>;

    return (
        <div>
            <h2>User Activities ({totalItems} total)</h2>
            <ul>
                {activities.map(activity => (
                    <li key={activity.id}>
                        {activity.applicationName} - {activity.durationSeconds}s
                    </li>
                ))}
            </ul>
        </div>
    );
}
```

---

## 🔧 **Performance Considerations**

### **Pagination Best Practices**
- **Default page size:** 10-20 items for good performance
- **Maximum page size:** 100 items (enforced by backend)
- **Large datasets:** Use pagination instead of fetching all at once

### **Caching Strategy**
```javascript
// Simple cache implementation
const activityCache = new Map();

function getCachedActivities(userId, page) {
    const cacheKey = `${userId}-${page}`;
    
    if (activityCache.has(cacheKey)) {
        const cached = activityCache.get(cacheKey);
        // Return cached data if less than 5 minutes old
        if (Date.now() - cached.timestamp < 300000) {
            return Promise.resolve(cached.data);
        }
    }
    
    return getUserActivities(userId, page).then(data => {
        activityCache.set(cacheKey, {
            data: data,
            timestamp: Date.now()
        });
        return data;
    });
}
```

### **Filtering for Better Performance**
```javascript
// Filter by application category for focused views
function getProductivityActivities(userId) {
    return fetch(
        `/api/activities/all?userId=${userId}&applicationCategory=PRODUCTIVITY&size=50`
    );
}

// Filter by date range for time-based analysis
function getTodayActivities(userId) {
    const today = new Date().toISOString().split('T')[0];
    return fetch(
        `/api/activities/all?userId=${userId}&startDate=${today}T00:00:00&endDate=${today}T23:59:59`
    );
}
```

---

## 🔗 **Related APIs**

### **Get All Users** (for main user list)
```http
GET /api/users/all
```

### **Get User Details** (for user info)
```http
GET /api/users/email/{email}
GET /api/users/{id}
```

### **Get Activity Details** (for specific activity)
```http
GET /api/activities/details/{activityId}
```

### **Alternative Activity APIs**
- `GET /api/activities/today?userId={id}` - Today's activities only
- `GET /api/activities/summary?userId={id}&startDate=...&endDate=...` - Summary data
- `GET /api/activities/stats?userId={id}&startDate=...&endDate=...` - Statistics

---

## 🛡️ **Security & Permissions**

### **Authentication Required**
- All requests must include valid JWT token
- Token must not be expired

### **Authorization Levels**
- **ADMIN/SUPERADMIN:** Can view activities for any user
- **EMPLOYEE:** Can only view their own activities (userId must match token)

### **Rate Limiting**
- API calls are rate-limited to prevent abuse
- Recommended: Max 60 requests per minute per user

---

## 📈 **Usage Analytics**

### **Common Use Cases**
1. **Employee Dashboard:** Show own activities (`userId` from JWT token)
2. **Admin Monitoring:** View any employee's activities
3. **Time Tracking:** Filter by date ranges and categories
4. **Productivity Analysis:** Analyze application usage patterns
5. **Compliance Reports:** Generate activity reports for auditing

### **Data Insights Available**
- **Total time spent per application**
- **Most active time periods**
- **Application category breakdown**
- **Productivity vs idle time ratio**
- **Security incidents (tamper attempts)**

---

## 🔄 **API Versioning**

**Current Version:** v1
**Endpoint Path:** `/api/activities/all`
**Stability:** ✅ **Stable** - Production ready

### **Backward Compatibility**
- API response format is stable
- New fields may be added (non-breaking)
- Deprecated fields will have 6-month notice

### **Future Enhancements**
- Real-time activity streaming
- Advanced filtering options
- Bulk operations support
- GraphQL endpoint alternative

---

## 🆘 **Troubleshooting**

### **Common Issues**

#### **Empty Results for Valid User**
**Problem:** API returns `totalItems: 0` for user that should have activities
**Solution:** 
- Check if user ID exists: `GET /api/users/email/{email}`
- Verify date range if using date filters
- Check if activities were recorded for this user

#### **Large Dataset Performance**
**Problem:** API responses are slow for users with many activities
**Solution:**
- Use smaller page sizes (`size=10-20`)
- Implement pagination properly
- Add date range filters
- Use application category filters

#### **Permission Denied**
**Problem:** 403 Forbidden error when accessing activities
**Solution:**
- Verify JWT token is valid and not expired
- Check user role (EMPLOYEE can only see own activities)
- Ensure userId in request matches token for non-admin users

### **Debug Information**
```javascript
// Add debug logging
function debugUserActivities(userId) {
    console.log(`Fetching activities for user ID: ${userId}`);
    console.log(`Auth token: ${authToken ? 'Present' : 'Missing'}`);
    
    return getUserActivities(userId)
        .then(data => {
            console.log(`Success: ${data.totalItems} activities found`);
            console.log(`Pages: ${data.totalPages}, Current: ${data.currentPage}`);
            return data;
        })
        .catch(error => {
            console.error(`Error fetching activities for user ${userId}:`, error);
            throw error;
        });
}
```

---

## 📞 **Support**

For technical support or questions about this API:
- **Documentation Issues:** Update this document
- **API Bugs:** Create backend issue ticket
- **Feature Requests:** Submit enhancement request
- **Integration Help:** Contact development team

---

**Last Updated:** June 19, 2025  
**API Version:** v1.0  
**Documentation Version:** 1.0
