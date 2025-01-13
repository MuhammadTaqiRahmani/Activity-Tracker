package com.example.backendapp.dto.analytics;

import lombok.Builder;
import lombok.Data;
import java.util.Map;
import java.time.LocalDate;

@Data
@Builder
public class TaskAnalyticsDTO {
    private Map<String, Double> taskCompletionRates;
    private Double averageTaskCompletionTime;
    private Map<LocalDate, Integer> tasksCompletedByDate;
    private Map<String, Double> taskEfficiencyScores;
    private Integer totalTasksCompleted;
    private Integer totalTasksPending;
}
