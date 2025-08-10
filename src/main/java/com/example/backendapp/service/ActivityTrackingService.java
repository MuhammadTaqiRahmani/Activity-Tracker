package com.example.backendapp.service;

import com.example.backendapp.dto.ActivitySummaryDTO;
import com.example.backendapp.entity.Activity;
import com.example.backendapp.repository.ActivityRepository;
import lombok.Data;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.InetAddress;
import java.time.LocalDateTime;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional
public class ActivityTrackingService {    @Autowired
    private ActivityRepository activityRepository;

    @Autowired
    private AntiTamperingService antiTamperingService;
    
    @Autowired
    private UserService userService;    public Activity logActivity(Activity activity) {
        System.out.println("\n=== Pre-Save Activity Validation ===");
        System.out.println("Required Fields Check:");
        System.out.println("userId: " + activity.getUserId());
        System.out.println("activityType: " + activity.getActivityType());
        System.out.println("description: " + activity.getDescription());
        System.out.println("processName: " + activity.getProcessName());
        System.out.println("windowTitle: " + activity.getWindowTitle());
        System.out.println("startTime: " + activity.getStartTime());
        System.out.println("endTime: " + activity.getEndTime());
        
        // Validate that user exists before saving activity
        if (activity.getUserId() == null) {
            throw new IllegalArgumentException("User ID cannot be null");
        }
        
        // Check if user exists to prevent orphaned activities
        if (!userService.findById(activity.getUserId()).isPresent()) {
            throw new IllegalArgumentException("User with ID " + activity.getUserId() + " does not exist. Cannot create activity for non-existent user.");
        }
        
        try {
            enrichActivityData(activity);
            validateActivity(activity);
            
            Activity savedActivity = activityRepository.save(activity);
            System.out.println("Activity saved successfully with ID: " + savedActivity.getId());
            return savedActivity;
        } catch (Exception e) {
            System.err.println("Error saving activity: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    public List<Activity> getTodayActivities(Long userId) {
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1).minusNanos(1);
        return activityRepository.findByUserIdAndCreatedAtBetween(userId, startOfDay, endOfDay);
    }

    public Map<String, Long> getDailyApplicationUsage(Long userId) {
        List<Activity> activities = activityRepository.findTodayActivitiesByUserId(userId);
        return activities.stream()
                .filter(a -> "APPLICATION_USAGE".equals(a.getActivityType()))
                .collect(Collectors.groupingBy(
                    Activity::getApplicationName,
                    Collectors.summingLong(Activity::getDurationSeconds)
                ));
    }

    public Long getProductiveTimeToday(Long userId) {
        return activityRepository.getTotalDurationByActivityType(userId, "PRODUCTIVE");
    }

    public void clearUserActivities(Long userId) {
        LocalDateTime thirtyDaysAgo = LocalDateTime.now().minusDays(30);
        List<Activity> activities = activityRepository.findActivitiesInDateRange(
            userId, 
            thirtyDaysAgo,
            LocalDateTime.now()
        );
        activityRepository.deleteAll(activities);
    }

    public ActivitySummaryDTO getActivitySummary(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        List<Activity> activities = activityRepository.findActivitiesByDateRange(userId, startDate, endDate);
        ActivitySummaryDTO summary = new ActivitySummaryDTO();
        summary.setUserId(userId);

        Map<String, Long> appUsage = activities.stream()
            .filter(a -> a.getApplicationName() != null)
            .collect(Collectors.groupingBy(
                Activity::getApplicationName,
                Collectors.summingLong(Activity::getDurationSeconds)
            ));

        summary.setApplicationUsageDuration(appUsage);
        summary.setTotalProductiveTime(calculateProductiveTime(activities));
        summary.setTotalIdleTime(activityRepository.getTotalIdleTimeNative(userId)); // Use native query
        summary.setMostUsedApplication(findMostUsedApp(appUsage));

        return summary;
    }

    public Map<String, Long> getApplicationUsageByCategory(Long userId) {
        return activityRepository.findTodayActivitiesByUserId(userId).stream()
            .filter(a -> a.getApplicationCategory() != null)
            .collect(Collectors.groupingBy(
                Activity::getApplicationCategory,
                Collectors.summingLong(Activity::getDurationSeconds)
            ));
    }

    public Activity getLatestActivity(Long userId) {
        return activityRepository.findLatestActivityByUserId(userId)
            .orElseThrow(() -> new RuntimeException("No activity found for user: " + userId));
    }

    private Long calculateProductiveTime(List<Activity> activities) {
        return activities.stream()
            .filter(a -> a.getStatus() == Activity.ActivityStatus.ACTIVE)
            .mapToLong(Activity::getDurationSeconds)
            .sum();
    }

    private String findMostUsedApp(Map<String, Long> appUsage) {
        return appUsage.entrySet().stream()
            .max(Map.Entry.comparingByValue())
            .map(Map.Entry::getKey)
            .orElse(null);
    }

    private void enrichActivityData(Activity activity) {
        try {
            // Set default values if null
            if (activity.getCreatedAt() == null) {
                activity.setCreatedAt(LocalDateTime.now());
            }
            if (activity.getStatus() == null) {
                activity.setStatus(Activity.ActivityStatus.ACTIVE);
            }
            if (activity.getTamperAttempt() == null) {
                activity.setTamperAttempt(false);
            }
            
            activity.setIpAddress(InetAddress.getLocalHost().getHostAddress());
            activity.setMachineId(System.getProperty("user.name") + "-" + 
                                InetAddress.getLocalHost().getHostName());
            
            // Generate hash value
            String activityData = activity.getUserId() + activity.getProcessName() + 
                                activity.getCreatedAt() + activity.getMachineId();
            activity.setHashValue(antiTamperingService.calculateHash(activityData));
            
        } catch (Exception e) {
            System.err.println("Error in enrichActivityData: " + e.getMessage());
            throw new RuntimeException("Failed to enrich activity data", e);
        }
    }

    private void validateActivity(Activity activity) {
        if (!antiTamperingService.isValidProcess(activity.getProcessId(), activity.getMachineId())) {
            activity.setTamperAttempt(true);
            activity.setTamperDetails("Invalid process detected");
        }
    }

    public Map<String, Object> getDetailedActivitySummary(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        Map<String, Object> summary = new HashMap<>();
        List<Activity> activities = activityRepository.findActivitiesByUserIdAndDateRange(userId, startDate, endDate);
        
        summary.put("totalActivities", activities.size());
        summary.put("productiveTime", calculateProductiveTime(activities));
        summary.put("applicationUsage", getApplicationUsageStats(activities));
        summary.put("tamperAttempts", getTamperAttempts(activities));
        summary.put("timelineAnalysis", analyzeTimeline(activities));
        
        return summary;
    }

    private Map<String, Object> analyzeTimeline(List<Activity> activities) {
        return activities.stream()
            .collect(Collectors.groupingBy(
                activity -> activity.getCreatedAt().toLocalDate().toString(), // Convert to String
                Collectors.collectingAndThen(
                    Collectors.toList(),
                    dailyActivities -> {
                        Map<String, Object> dailyStats = new HashMap<>();
                        dailyStats.put("totalTime", calculateTotalTime(dailyActivities));
                        dailyStats.put("productiveTime", calculateProductiveTime(dailyActivities));
                        dailyStats.put("applications", getUniqueApplications(dailyActivities));
                        return dailyStats;
                    }
                )
            ));
    }

    private List<TamperReport> getTamperAttempts(List<Activity> activities) {
        return activities.stream()
            .filter(Activity::getTamperAttempt)
            .map(activity -> new TamperReport(
                activity.getCreatedAt(),
                activity.getTamperDetails(),
                activity.getMachineId(),
                activity.getIpAddress()
            ))
            .collect(Collectors.toList());
    }

    private Map<String, Long> getApplicationUsageStats(List<Activity> activities) {
        return activities.stream()
            .filter(a -> a.getApplicationName() != null)
            .collect(Collectors.groupingBy(
                Activity::getApplicationName,
                Collectors.summingLong(Activity::getDurationSeconds)
            ));
    }

    private Long calculateTotalTime(List<Activity> activities) {
        return activities.stream()
            .mapToLong(Activity::getDurationSeconds)
            .sum();
    }

    private Set<String> getUniqueApplications(List<Activity> activities) {
        return activities.stream()
            .map(Activity::getApplicationName)
            .filter(Objects::nonNull)
            .collect(Collectors.toCollection(HashSet::new)); // Use HashSet for better type safety
    }

    public Long getTotalActivitiesCount() {
        return activityRepository.count();
    }    // Additional helper method to get count for a specific user
    public Long getTotalActivitiesCountForUser(Long userId) {
        return activityRepository.countByUserId(userId);
    }
    
    /**
     * Check for orphaned activities - activities that reference non-existent users
     * @return Map containing orphaned activity information
     */
    public Map<String, Object> checkOrphanedActivities() {
        Map<String, Object> result = new HashMap<>();
        
        List<Long> orphanedUserIds = activityRepository.findOrphanedActivityUserIds();
        Long orphanedCount = activityRepository.countOrphanedActivities();
        
        result.put("hasOrphanedActivities", !orphanedUserIds.isEmpty());
        result.put("orphanedUserIds", orphanedUserIds);
        result.put("orphanedActivityCount", orphanedCount);
        result.put("timestamp", LocalDateTime.now());
        
        if (!orphanedUserIds.isEmpty()) {
            System.err.println("WARNING: Found " + orphanedCount + " orphaned activities for user IDs: " + orphanedUserIds);
        }
        
        return result;
    }
    
    /**
     * Clean up orphaned activities - removes activities that reference non-existent users
     * @return Number of orphaned activities removed
     */
    @Transactional
    public int cleanupOrphanedActivities() {
        Map<String, Object> orphanedInfo = checkOrphanedActivities();
        
        if (!(Boolean) orphanedInfo.get("hasOrphanedActivities")) {
            System.out.println("No orphaned activities found to clean up.");
            return 0;
        }
        
        List<Long> orphanedUserIds = (List<Long>) orphanedInfo.get("orphanedUserIds");
        Long orphanedCount = (Long) orphanedInfo.get("orphanedActivityCount");
        
        System.out.println("Cleaning up " + orphanedCount + " orphaned activities for user IDs: " + orphanedUserIds);
        
        int deletedCount = activityRepository.deleteOrphanedActivities();
        
        System.out.println("Successfully deleted " + deletedCount + " orphaned activities.");
        
        return deletedCount;
    }
    
    /**
     * Get detailed information about orphaned activities
     * @return List of orphaned activities with full details
     */
    public List<Activity> getOrphanedActivitiesDetails() {
        return activityRepository.findOrphanedActivities();
    }

    @Data
    @AllArgsConstructor
    public static class TamperReport {
        private final LocalDateTime timestamp;
        private final String details;
        private final String machineId;
        private final String ipAddress;
    }
}
