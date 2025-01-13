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
                // Create ProcessTrack
                ProcessTrack processTrack = new ProcessTrack();
                processTrack.setUserId(Long.valueOf(log.get("userId").toString()));
                processTrack.setProcessName(log.get("processName").toString());
                processTrack.setWindowTitle(log.get("windowTitle").toString());
                processTrack.setProcessId(log.get("processId").toString());
                processTrack.setApplicationPath(log.get("applicationPath").toString());
                processTrack.setStartTime(LocalDateTime.parse(log.get("startTime").toString()));
                processTrack.setEndTime(LocalDateTime.parse(log.get("endTime").toString()));
                processTrack.setDurationSeconds(Long.valueOf(log.get("durationSeconds").toString()));
                processTrack.setCategory(log.get("category").toString());
                processTrack.setIsProductiveApp(Boolean.valueOf(log.get("isProductiveApp").toString()));
                processTracks.add(processTrack);

                // Create Activity with all required fields
                Activity activity = new Activity();
                activity.setUserId(Long.valueOf(log.get("userId").toString()));
                activity.setActivityType(log.get("activityType").toString());
                activity.setDescription(log.get("description").toString());
                activity.setProcessName(log.get("processName").toString());
                activity.setWindowTitle(log.get("windowTitle").toString());
                activity.setApplicationName(log.get("processName").toString());
                activity.setWorkspaceType(log.get("workspaceType").toString());
                activity.setApplicationCategory(log.get("applicationCategory").toString());
                activity.setProcessId(log.get("processId").toString());
                activity.setDurationSeconds(Long.valueOf(log.get("durationSeconds").toString()));
                activity.setStartTime(LocalDateTime.parse(log.get("startTime").toString()));
                activity.setEndTime(LocalDateTime.parse(log.get("endTime").toString()));
                
                System.out.println("\nCreated Activity:");
                System.out.println("UserId: " + activity.getUserId());
                System.out.println("ActivityType: " + activity.getActivityType());
                System.out.println("ProcessName: " + activity.getProcessName());
                
                activities.add(activity);
            }

            // Save both
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
}
