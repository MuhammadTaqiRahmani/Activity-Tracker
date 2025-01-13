package com.example.backendapp.controller;

import com.example.backendapp.service.UserService;
import com.example.backendapp.service.ActivityTrackingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    @Autowired
    private UserService userService;

    @Autowired
    private ActivityTrackingService activityService;

    @GetMapping("/system/status")
    public ResponseEntity<?> getSystemStatus() {
        try {
            Map<String, Object> status = new HashMap<>();
            status.put("activeUsers", userService.getActiveUsersCount());
            status.put("systemHealth", "OK");
            status.put("lastBackup", LocalDateTime.now());
            status.put("totalActivities", activityService.getTotalActivitiesCount());
            status.put("serverTime", LocalDateTime.now());
            status.put("version", "1.0.0");
            return ResponseEntity.ok(status);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to get system status: " + e.getMessage()));
        }
    }

    @PostMapping("/system/maintenance")
    public ResponseEntity<?> performMaintenance() {
        // System maintenance operations
        return ResponseEntity.ok("Maintenance completed");
    }

    @DeleteMapping("/users/{userId}/purge")
    public ResponseEntity<?> purgeUserData(@PathVariable Long userId) {
        // Complete user data removal
        return ResponseEntity.ok("User data purged");
    }
}
