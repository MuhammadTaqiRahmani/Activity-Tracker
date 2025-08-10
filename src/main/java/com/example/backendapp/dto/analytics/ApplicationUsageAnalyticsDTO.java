package com.example.backendapp.dto.analytics;

import lombok.Data;
import lombok.Builder;
import java.util.Map;
import java.time.LocalDateTime;

@Data
@Builder
public class ApplicationUsageAnalyticsDTO {
    private Map<String, Long> applicationTimeByCategory;
    private Map<String, Double> productivityScoreByApp;
    private Map<LocalDateTime, Map<String, Long>> hourlyUsagePattern;
    private Map<String, Integer> applicationSwitchFrequency;
    private Map<String, Long> totalUsageTime;
    private Map<String, Boolean> productiveApps;
    private Double focusScore;
}
