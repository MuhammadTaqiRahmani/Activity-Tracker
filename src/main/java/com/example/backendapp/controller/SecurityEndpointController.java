package com.example.backendapp.controller;

import com.example.backendapp.service.ActivityTrackingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/security")
@PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')") // Allow both roles to access the controller
public class SecurityEndpointController {

    @Autowired
    private ActivityTrackingService activityTrackingService;

    @GetMapping("/tamper-report")
    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')") // Allow both roles to access the endpoint
    public ResponseEntity<?> getTamperReport(
            @RequestParam Long userId,
            @RequestParam LocalDateTime startDate,
            @RequestParam LocalDateTime endDate) {
        Map<String, Object> report = activityTrackingService.getDetailedActivitySummary(userId, startDate, endDate);
        return ResponseEntity.ok(report);
    }
}
