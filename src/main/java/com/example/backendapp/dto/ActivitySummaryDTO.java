package com.example.backendapp.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActivitySummaryDTO {
    private Long userId;
    private Map<String, Long> applicationUsageDuration;
    private Long totalProductiveTime;
    private Long totalIdleTime;
    private String mostUsedApplication;
    private Map<String, Object> additionalMetrics;
}
