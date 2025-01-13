package com.example.backendapp.dto.analytics;

import lombok.Data;
import lombok.Builder;
import java.util.Map;
import java.time.LocalDateTime;

@Data
@Builder
public class EnhancedTaskAnalyticsDTO {
    private Map<String, Double> taskEfficiencyByCategory;
    private Map<LocalDateTime, Integer> taskCompletionTimeline;
    private Double averageCompletionTime;
    private Map<String, Integer> taskStatusDistribution;
    private Map<String, Double> productivityTrends;
    private Integer tasksCompletedOnTime;
    private Integer tasksDelayed;
    private Double efficiencyScore;
}
