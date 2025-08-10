package com.example.backendapp.service;

import com.example.backendapp.entity.Activity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.Map;
import java.util.HashMap;

@Service
@EnableScheduling
public class LogCollectorService {
    private static final Logger logger = LoggerFactory.getLogger(LogCollectorService.class);
    
    private final Queue<Activity> activityLogQueue = new ConcurrentLinkedQueue<>();
    
    @Autowired
    private ActivityTrackingService activityTrackingService;

    private final Map<String, String> applicationCategories = new HashMap<String, String>() {{
        // Development Tools
        put("code", "DEVELOPMENT");
        put("studio", "DEVELOPMENT");
        put("intellij", "DEVELOPMENT");
        put("eclipse", "DEVELOPMENT");
        put("vim", "DEVELOPMENT");
        
        // Browsers
        put("chrome", "BROWSER");
        put("firefox", "BROWSER");
        put("edge", "BROWSER");
        put("iexplore", "BROWSER");
        
        // Office Applications
        put("winword", "PRODUCTIVITY");
        put("excel", "PRODUCTIVITY");
        put("powerpoint", "PRODUCTIVITY");
        put("outlook", "PRODUCTIVITY");
        put("onenote", "PRODUCTIVITY");
        
        // Communication
        put("teams", "COMMUNICATION");
        put("slack", "COMMUNICATION");
        put("zoom", "COMMUNICATION");
        put("skype", "COMMUNICATION");
        
        // System Tools
        put("explorer", "SYSTEM");
        put("cmd", "SYSTEM");
        put("powershell", "SYSTEM");
        put("taskmanager", "SYSTEM");
        
        // Entertainment
        put("spotify", "ENTERTAINMENT");
        put("vlc", "ENTERTAINMENT");
        put("steam", "ENTERTAINMENT");
    }};

    public void queueActivityLog(Activity activity) {
        System.out.println("\n=== Data Validation Before Queueing ===");
        validateActivityData(activity);
        
        System.out.println("\n=== Queueing Activity ===");
        System.out.println("Process: " + activity.getProcessName());
        System.out.println("Activity Type: " + activity.getActivityType());
        System.out.println("Description: " + activity.getDescription());
        System.out.println("Workspace Type: " + activity.getWorkspaceType());
        System.out.println("Queue size before: " + activityLogQueue.size());
        
        // Set default values if null
        if (activity.getActivityType() == null) {
            activity.setActivityType("PROCESS_MONITORING");
        }
        if (activity.getDescription() == null) {
            activity.setDescription("Automatic process monitoring: " + activity.getProcessName());
        }
        if (activity.getWorkspaceType() == null) {
            activity.setWorkspaceType("LOCAL");
        }

        // Categorize the application
        String processName = activity.getProcessName().toLowerCase();
        String category = applicationCategories.entrySet().stream()
            .filter(entry -> processName.contains(entry.getKey()))
            .map(Map.Entry::getValue)
            .findFirst()
            .orElse("OTHER");

        activity.setApplicationCategory(category);
        
        // Set productivity status based on category
        boolean isProductive = category.equals("DEVELOPMENT") || 
                             category.equals("PRODUCTIVITY") || 
                             category.equals("COMMUNICATION");
        activity.setStatus(isProductive ? Activity.ActivityStatus.ACTIVE : Activity.ActivityStatus.IDLE);

        System.out.println("Application Category: " + category);
        System.out.println("Productivity Status: " + activity.getStatus());
        
        activityLogQueue.add(activity);
        
        System.out.println("Queue size after: " + activityLogQueue.size());
    }

    private void validateActivityData(Activity activity) {
        if (activity.getUserId() == null) throw new IllegalArgumentException("userId is required");
        if (activity.getProcessName() == null) throw new IllegalArgumentException("processName is required");
        if (activity.getActivityType() == null) throw new IllegalArgumentException("activityType is required");
        if (activity.getDescription() == null) throw new IllegalArgumentException("description is required");
        
        System.out.println("All required fields present");
        System.out.println("Activity data: " + activity);
    }

    @Scheduled(fixedRate = 60000) // Process every minute
    @Transactional
    public void processBatchLogs() {
        int batchSize = activityLogQueue.size();
        System.out.println("\n=== Processing Batch Logs ===");
        System.out.println("Current queue size: " + batchSize);
        
        for (int i = 0; i < batchSize; i++) {
            Activity log = activityLogQueue.poll();
            if (log != null) {
                try {
                    System.out.println("\nProcessing activity:");
                    System.out.println("Process: " + log.getProcessName());
                    System.out.println("User ID: " + log.getUserId());
                    
                    Activity savedActivity = activityTrackingService.logActivity(log);
                    
                    System.out.println("Successfully saved activity with ID: " + savedActivity.getId());
                } catch (Exception e) {
                    System.err.println("\nError processing activity:");
                    System.err.println("Process: " + log.getProcessName());
                    e.printStackTrace();
                    activityLogQueue.add(log);
                }
            }
        }
        
        System.out.println("\nBatch processing completed");
        System.out.println("Remaining queue size: " + activityLogQueue.size());
    }
}
