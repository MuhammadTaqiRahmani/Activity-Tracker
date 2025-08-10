package com.example.backendapp.controller;

import com.example.backendapp.dto.ActivitySummaryDTO;
import com.example.backendapp.entity.Activity;
import com.example.backendapp.repository.ActivityRepository;
import com.example.backendapp.service.ActivityTrackingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Collections;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/activities")
public class ActivityController {

    @Autowired
    private ActivityTrackingService activityService;

    @Autowired
    private ActivityRepository activityRepository;

    @PostMapping("/log")
    public ResponseEntity<?> logActivity(@RequestBody Activity activity) {
        return ResponseEntity.ok(activityService.logActivity(activity));
    }

    @GetMapping("/today")
    public ResponseEntity<?> getTodayActivities(@RequestParam Long userId) {
        return ResponseEntity.ok(activityService.getTodayActivities(userId));
    }

    @GetMapping("/application-usage")
    public ResponseEntity<?> getApplicationUsage(@RequestParam Long userId) {
        return ResponseEntity.ok(activityService.getDailyApplicationUsage(userId));
    }

    @GetMapping("/productive-time")
    public ResponseEntity<?> getProductiveTime(@RequestParam Long userId) {
        return ResponseEntity.ok(activityService.getProductiveTimeToday(userId));
    }

    @DeleteMapping("/clear")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> clearActivities(@RequestParam Long userId) {
        activityService.clearUserActivities(userId);
        return ResponseEntity.ok("Activities cleared successfully");
    }

    @GetMapping("/summary")
    public ResponseEntity<?> getActivitySummary(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return ResponseEntity.ok(activityService.getActivitySummary(userId, startDate, endDate));
    }

    @GetMapping("/categories")
    public ResponseEntity<?> getApplicationCategories(@RequestParam Long userId) {
        return ResponseEntity.ok(activityService.getApplicationUsageByCategory(userId));
    }

    @GetMapping("/status")
    public ResponseEntity<?> getCurrentStatus(@RequestParam Long userId) {
        Activity latestActivity = activityService.getLatestActivity(userId);
        return ResponseEntity.ok(Map.of(
            "status", latestActivity.getStatus(),
            "lastActive", latestActivity.getCreatedAt()
        ));
    }

    @GetMapping("/security/tamper-report")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getTamperReport(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        Map<String, Object> summary = activityService.getDetailedActivitySummary(userId, startDate, endDate);
        return ResponseEntity.ok(summary);
    }

    @GetMapping("/detailed-summary")
    public ResponseEntity<?> getDetailedSummary(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return ResponseEntity.ok(activityService.getDetailedActivitySummary(userId, startDate, endDate));
    }

    // Get all activities with filtering and pagination
    @GetMapping("/all")
    public ResponseEntity<Map<String, Object>> getAllActivities(
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String activityType,
            @RequestParam(required = false) String applicationCategory,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        try {
            // Create pageable object
            Sort.Direction direction = Sort.Direction.fromString(sortDirection);
            PageRequest pageRequest = PageRequest.of(page, size, Sort.by(direction, sortBy));
            
            // Get activities with filters
            Page<Activity> activitiesPage = activityRepository.findActivitiesWithFilters(
                userId, activityType, applicationCategory, pageRequest);

            // Prepare response
            Map<String, Object> response = new HashMap<>();
            response.put("activities", activitiesPage.getContent());
            response.put("currentPage", activitiesPage.getNumber());
            response.put("totalItems", activitiesPage.getTotalElements());
            response.put("totalPages", activitiesPage.getTotalPages());
            response.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to fetch activities: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Collections.singletonMap("error", e.getMessage()));
        }
    }

    // Get activity details by ID
    @GetMapping("/details/{id}")
    public ResponseEntity<?> getActivityDetails(@PathVariable Long id) {
        try {
            return activityRepository.findById(id)
                .map(activity -> {
                    Map<String, Object> details = new HashMap<>();
                    details.put("id", activity.getId());
                    details.put("userId", activity.getUserId());
                    details.put("activityType", activity.getActivityType());
                    details.put("description", activity.getDescription());
                    details.put("applicationName", activity.getApplicationName());
                    details.put("processName", activity.getProcessName());
                    details.put("windowTitle", activity.getWindowTitle());
                    details.put("startTime", activity.getStartTime());
                    details.put("endTime", activity.getEndTime());
                    details.put("durationSeconds", activity.getDurationSeconds());
                    details.put("status", activity.getStatus());
                    details.put("workspaceType", activity.getWorkspaceType());
                    details.put("applicationCategory", activity.getApplicationCategory());
                    return ResponseEntity.ok(details);
                })
                .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Collections.singletonMap("error", e.getMessage()));
        }
    }

    // Get activity statistics
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getActivityStatistics(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        try {
            Map<String, Object> stats = new HashMap<>();
            
            List<Activity> activities = activityRepository
                .findByUserIdAndCreatedAtBetween(userId, startDate, endDate);
            
            stats.put("totalActivities", activities.size());
            stats.put("byCategory", getActivityCountByCategory(activities));
            stats.put("byStatus", getActivityCountByStatus(activities));
            stats.put("totalDuration", calculateTotalDuration(activities));
            stats.put("timeRange", Map.of("start", startDate, "end", endDate));
            
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Collections.singletonMap("error", e.getMessage()));
        }
    }

    private Map<String, Long> getActivityCountByCategory(List<Activity> activities) {
        return activities.stream()
            .filter(a -> a.getApplicationCategory() != null)
            .collect(Collectors.groupingBy(
                Activity::getApplicationCategory,
                Collectors.counting()
            ));
    }

    private Map<String, Long> getActivityCountByStatus(List<Activity> activities) {
        return activities.stream()
            .filter(a -> a.getStatus() != null)
            .collect(Collectors.groupingBy(
                a -> a.getStatus().toString(),
                Collectors.counting()
            ));
    }    private Long calculateTotalDuration(List<Activity> activities) {
        return activities.stream()
            .mapToLong(Activity::getDurationSeconds)
            .sum();
    }
    
    // Orphaned Activities Management Endpoints (Admin only)
    
    /**
     * Check for orphaned activities - activities that reference non-existent users
     */
    @GetMapping("/admin/orphaned-check")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> checkOrphanedActivities() {
        try {
            Map<String, Object> result = activityService.checkOrphanedActivities();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Collections.singletonMap("error", "Failed to check orphaned activities: " + e.getMessage()));
        }
    }
    
    /**
     * Get detailed information about orphaned activities
     */
    @GetMapping("/admin/orphaned-details")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getOrphanedActivitiesDetails() {
        try {
            List<Activity> orphanedActivities = activityService.getOrphanedActivitiesDetails();
            
            Map<String, Object> response = new HashMap<>();
            response.put("orphanedActivities", orphanedActivities);
            response.put("count", orphanedActivities.size());
            response.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Collections.singletonMap("error", "Failed to get orphaned activities details: " + e.getMessage()));
        }
    }
    
    /**
     * Clean up orphaned activities - removes activities that reference non-existent users
     */
    @DeleteMapping("/admin/orphaned-cleanup")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> cleanupOrphanedActivities() {
        try {
            int deletedCount = activityService.cleanupOrphanedActivities();
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Orphaned activities cleanup completed");
            response.put("deletedCount", deletedCount);
            response.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Collections.singletonMap("error", "Failed to cleanup orphaned activities: " + e.getMessage()));
        }
    }
}
