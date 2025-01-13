package com.example.backendapp.controller;

import com.example.backendapp.entity.Activity;
import com.example.backendapp.entity.User;
import com.example.backendapp.service.ActivityTrackingService;
import com.example.backendapp.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/test/tracking")
public class TestTrackingController {

    @Autowired
    private ActivityTrackingService activityService;

    @Autowired
    private UserService userService;

    @PostMapping("/simulate-keystroke")
    public ResponseEntity<?> simulateKeystroke(@RequestParam Long userId) {
        try {
            User user = userService.getUser(userId);
            Activity activity = new Activity();
            activity.setUserId(userId);  // Using userId instead of user object
            activity.setActivityType("KEYSTROKE");
            activity.setDescription("Test keystroke activity");
            activity.setDurationSeconds(60L);
            activity.setCreatedAt(LocalDateTime.now());
            return ResponseEntity.ok(activityService.logActivity(activity));
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body("User not found");
        }
    }

    @PostMapping("/simulate-app-usage")
    public ResponseEntity<?> simulateAppUsage(
            @RequestParam Long userId,
            @RequestParam String appName,
            @RequestParam Long duration) {
        try {
            User user = userService.getUser(userId);
            Activity activity = new Activity();
            activity.setUserId(userId);  // Using userId instead of user object
            activity.setActivityType("APPLICATION_USAGE");
            activity.setApplicationName(appName);
            activity.setDescription("Using " + appName);
            activity.setDurationSeconds(duration);
            activity.setWorkspaceType("PRODUCTIVE");
            activity.setCreatedAt(LocalDateTime.now());
            return ResponseEntity.ok(activityService.logActivity(activity));
        } catch (RuntimeException e) {
            return ResponseEntity.status(404).body("User not found");
        }
    }

    @GetMapping("/simulate-daily-report")
    public ResponseEntity<?> simulateDailyReport(@RequestParam Long userId) {
        Map<String, Object> report = new HashMap<>();
        report.put("activities", activityService.getTodayActivities(userId));
        report.put("appUsage", activityService.getDailyApplicationUsage(userId));
        report.put("productiveTime", activityService.getProductiveTimeToday(userId));
        
        return ResponseEntity.ok(report);
    }
}
