package com.example.backendapp.service;

import com.example.backendapp.entity.ProcessTrack;
import com.example.backendapp.repository.ProcessTrackRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ProcessTrackingService {
    
    @Autowired
    private ProcessTrackRepository processTrackRepository;

    private final Map<String, String> applicationCategories = new HashMap<String, String>() {{
        put("code", "DEVELOPMENT");
        put("studio", "DEVELOPMENT");
        put("intellij", "DEVELOPMENT");
        put("eclipse", "DEVELOPMENT");
        put("chrome", "BROWSER");
        put("firefox", "BROWSER");
        put("edge", "BROWSER");
        put("teams", "COMMUNICATION");
        put("slack", "COMMUNICATION");
        put("outlook", "COMMUNICATION");
        put("word", "PRODUCTIVITY");
        put("excel", "PRODUCTIVITY");
        put("powerpoint", "PRODUCTIVITY");
        put("notepad", "PRODUCTIVITY");
        put("spotify", "ENTERTAINMENT");
        put("vlc", "ENTERTAINMENT");
        put("game", "ENTERTAINMENT");
    }};

    public ProcessTrack logProcess(ProcessTrack process) {
        categorizeProcess(process);
        calculateProductivity(process);
        return processTrackRepository.save(process);
    }

    public Map<String, Object> getProcessAnalytics(Long userId, LocalDateTime start, LocalDateTime end) {
        Map<String, Object> analytics = new HashMap<>();
        
        // Get category-wise usage
        List<Object[]> categoryStats = processTrackRepository.getCategoryUsageStats(userId, start, end);
        Map<String, Long> categoryUsage = categoryStats.stream()
            .collect(Collectors.toMap(
                row -> (String) row[0],
                row -> (Long) row[1]
            ));
        
        // Get most used applications
        List<Object[]> appStats = processTrackRepository.getMostUsedApplications(userId, start, end);
        Map<String, Long> topApps = appStats.stream()
            .limit(10)
            .collect(Collectors.toMap(
                row -> (String) row[0],
                row -> (Long) row[1]
            ));

        analytics.put("categoryUsage", categoryUsage);
        analytics.put("topApplications", topApps);
        analytics.put("productiveTime", calculateProductiveTime(userId, start, end));
        analytics.put("nonProductiveTime", calculateNonProductiveTime(userId, start, end));
        
        return analytics;
    }

    private void categorizeProcess(ProcessTrack process) {
        String processNameLower = process.getProcessName().toLowerCase();
        process.setCategory(
            applicationCategories.entrySet().stream()
                .filter(entry -> processNameLower.contains(entry.getKey()))
                .map(Map.Entry::getValue)
                .findFirst()
                .orElse("OTHER")
        );
    }

    private void calculateProductivity(ProcessTrack process) {
        String category = process.getCategory();
        process.setIsProductiveApp(
            category.equals("DEVELOPMENT") || 
            category.equals("PRODUCTIVITY") || 
            category.equals("COMMUNICATION")
        );
    }

    private Long calculateProductiveTime(Long userId, LocalDateTime start, LocalDateTime end) {
        return processTrackRepository.findByUserIdAndStartTimeBetween(userId, start, end).stream()
            .filter(ProcessTrack::getIsProductiveApp)
            .mapToLong(ProcessTrack::getDurationSeconds)
            .sum();
    }

    private Long calculateNonProductiveTime(Long userId, LocalDateTime start, LocalDateTime end) {
        return processTrackRepository.findByUserIdAndStartTimeBetween(userId, start, end).stream()
            .filter(pt -> !pt.getIsProductiveApp())
            .mapToLong(ProcessTrack::getDurationSeconds)
            .sum();
    }
}
