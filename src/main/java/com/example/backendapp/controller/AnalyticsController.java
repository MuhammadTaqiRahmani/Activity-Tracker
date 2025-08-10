package com.example.backendapp.controller;

import com.example.backendapp.dto.analytics.ProductivityAnalyticsDTO;
import com.example.backendapp.dto.analytics.TaskAnalyticsDTO;
import com.example.backendapp.dto.analytics.WorkspaceAnalyticsDTO;
import com.example.backendapp.service.AnalyticsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/analytics")
public class AnalyticsController {

    @Autowired
    private AnalyticsService analyticsService;

    @GetMapping("/productivity")
    public ResponseEntity<ProductivityAnalyticsDTO> getProductivityAnalytics(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return ResponseEntity.ok(analyticsService.analyzeProductivity(userId, startDate, endDate));
    }

    @GetMapping("/task-completion")
    public ResponseEntity<TaskAnalyticsDTO> getTaskCompletionAnalytics(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return ResponseEntity.ok(analyticsService.analyzeTaskCompletion(userId, startDate, endDate));
    }

    @GetMapping("/app-usage")
    public ResponseEntity<?> getApplicationUsageAnalytics(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        // To be implemented
        return ResponseEntity.ok().build();
    }

    @GetMapping("/workspace-comparison")
    public ResponseEntity<WorkspaceAnalyticsDTO> getWorkspaceAnalytics(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return ResponseEntity.ok(analyticsService.analyzeWorkspaces(userId, startDate, endDate));
    }

    @GetMapping("/efficiency-metrics")
    public ResponseEntity<Map<String, Object>> getEfficiencyMetrics(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("tasks", analyticsService.analyzeTaskCompletion(userId, startDate, endDate));
        metrics.put("workspaces", analyticsService.analyzeWorkspaces(userId, startDate, endDate));
        metrics.put("productivity", analyticsService.analyzeProductivity(userId, startDate, endDate));
        return ResponseEntity.ok(metrics);
    }
}
