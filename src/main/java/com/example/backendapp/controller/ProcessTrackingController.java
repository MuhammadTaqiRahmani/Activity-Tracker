package com.example.backendapp.controller;

import com.example.backendapp.entity.ProcessTrack;
import com.example.backendapp.service.ProcessTrackingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/process-tracking")
public class ProcessTrackingController {

    @Autowired
    private ProcessTrackingService processTrackingService;

    @PostMapping("/log")
    public ResponseEntity<?> logProcess(@RequestBody ProcessTrack process) {
        return ResponseEntity.ok(processTrackingService.logProcess(process));
    }

    @GetMapping("/analytics")
    public ResponseEntity<?> getProcessAnalytics(
            @RequestParam Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return ResponseEntity.ok(processTrackingService.getProcessAnalytics(userId, startDate, endDate));
    }
}
