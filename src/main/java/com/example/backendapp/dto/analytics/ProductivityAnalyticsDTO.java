package com.example.backendapp.dto.analytics;

import lombok.Data;
import lombok.Builder;
import java.util.Map;
import java.time.LocalDate;

@Data
@Builder
public class ProductivityAnalyticsDTO {
    private Map<LocalDate, Double> dailyProductivityScore;
    private Map<String, Long> applicationUsageTime;
    private Double averageProductiveHoursPerDay;
    private Long totalProductiveMinutes;
    private Long totalIdleMinutes;
    private Map<String, Integer> taskCompletionRates;
    private Map<String, Double> productivityByTimeOfDay;
}
