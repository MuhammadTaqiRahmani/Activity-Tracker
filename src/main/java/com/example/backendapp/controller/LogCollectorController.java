package com.example.backendapp.controller;

import com.example.backendapp.entity.Activity;
import com.example.backendapp.entity.ProcessTrack;
import com.example.backendapp.service.LogCollectorService;
import com.example.backendapp.service.ProcessTrackingService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/logs")
public class LogCollectorController {
    private static final Logger logger = LoggerFactory.getLogger(LogCollectorController.class);

    @Autowired
    private LogCollectorService logCollectorService;

    @Autowired
    private ProcessTrackingService processTrackingService;

    @PostMapping("/batch")
    public ResponseEntity<?> collectBatchLogs(@RequestBody List<Map<String, Object>> logs) {
        System.out.println("\n=== Received Batch Log Request ===");
        System.out.println("Batch size: " + logs.size());
        
        try {
            List<ProcessTrack> processTracks = new ArrayList<>();
            List<Activity> activities = new ArrayList<>();

            for (Map<String, Object> log : logs) {
                // Validate required fields
                if (!isValidLogEntry(log)) {
                    System.err.println("Invalid log entry: " + log);
                    continue;
                }

                // Create ProcessTrack with safe get methods
                ProcessTrack processTrack = new ProcessTrack();
                processTrack.setUserId(getLongValue(log, "userId"));
                processTrack.setProcessName(getStringValue(log, "processName"));
                processTrack.setWindowTitle(getStringValue(log, "windowTitle"));
                processTrack.setProcessId(getStringValue(log, "processId"));
                processTrack.setApplicationPath(getStringValue(log, "applicationPath", ""));
                processTrack.setStartTime(getDateTimeValue(log, "startTime"));
                processTrack.setEndTime(getDateTimeValue(log, "endTime"));
                processTrack.setDurationSeconds(getLongValue(log, "durationSeconds"));
                processTrack.setCategory(getStringValue(log, "category", "OTHER"));
                processTrack.setIsProductiveApp(getBooleanValue(log, "isProductiveApp", true));
                processTracks.add(processTrack);

                // Create Activity
                Activity activity = new Activity();
                activity.setUserId(getLongValue(log, "userId"));
                activity.setActivityType(getStringValue(log, "activityType", "PROCESS_MONITORING"));
                activity.setDescription(getStringValue(log, "description", "Process monitoring: " + processTrack.getProcessName()));
                activity.setProcessName(getStringValue(log, "processName"));
                activity.setWindowTitle(getStringValue(log, "windowTitle"));
                activity.setApplicationName(getStringValue(log, "processName"));
                activity.setWorkspaceType(getStringValue(log, "workspaceType", "LOCAL"));
                activity.setApplicationCategory(getStringValue(log, "applicationCategory", "SYSTEM"));
                activity.setProcessId(getStringValue(log, "processId"));
                activity.setDurationSeconds(getLongValue(log, "durationSeconds"));
                activity.setStartTime(getDateTimeValue(log, "startTime"));
                activity.setEndTime(getDateTimeValue(log, "endTime"));
                
                System.out.println("\nCreated Activity:");
                System.out.println("UserId: " + activity.getUserId());
                System.out.println("ActivityType: " + activity.getActivityType());
                System.out.println("ProcessName: " + activity.getProcessName());
                
                activities.add(activity);
            }

            // Process valid entries
            processTracks.forEach(processTrackingService::logProcess);
            activities.forEach(logCollectorService::queueActivityLog);

            return ResponseEntity.ok(Map.of(
                "status", "success",
                "processTracksQueued", processTracks.size(),
                "activitiesQueued", activities.size()
            ));
        } catch (Exception e) {
            System.err.println("\nError in collectBatchLogs:");
            e.printStackTrace();
            return ResponseEntity.internalServerError().body(Map.of(
                "error", e.getMessage(),
                "stackTrace", e.getStackTrace()
            ));
        }
    }

    // Add helper methods
    private boolean isValidLogEntry(Map<String, Object> log) {
        return log.containsKey("userId") && 
               log.containsKey("processName") && 
               log.containsKey("processId") && 
               log.containsKey("startTime") &&
               log.containsKey("endTime") &&
               log.containsKey("durationSeconds");
    }

    private String getStringValue(Map<String, Object> map, String key, String defaultValue) {
        Object value = map.get(key);
        return value != null ? value.toString() : defaultValue;
    }

    private String getStringValue(Map<String, Object> map, String key) {
        return getStringValue(map, key, "");
    }

    private Long getLongValue(Map<String, Object> map, String key) {
        Object value = map.get(key);
        if (value == null) return 0L;
        return value instanceof Number ? ((Number) value).longValue() : Long.parseLong(value.toString());
    }

    private Boolean getBooleanValue(Map<String, Object> map, String key, Boolean defaultValue) {
        Object value = map.get(key);
        if (value == null) return defaultValue;
        return value instanceof Boolean ? (Boolean) value : Boolean.parseBoolean(value.toString());
    }

    private LocalDateTime getDateTimeValue(Map<String, Object> map, String key) {
        String value = getStringValue(map, key);
        return value.isEmpty() ? LocalDateTime.now() : LocalDateTime.parse(value);
    }
}
