package com.example.backendapp.controller;

import com.example.backendapp.dto.ActivitySummaryDTO;
import com.example.backendapp.entity.Activity;
import com.example.backendapp.service.ActivityTrackingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/activities")
public class ActivityController {

    @Autowired
    private ActivityTrackingService activityService;

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
}
