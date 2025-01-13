package com.example.backendapp.dto.analytics;

import lombok.Builder;
import lombok.Data;
import java.util.Map;

@Data
@Builder
public class WorkspaceAnalyticsDTO {
    private Map<String, Long> productiveWorkspaceTime;
    private Map<String, Long> localWorkspaceTime;
    private Double productiveVsLocalRatio;
    private Map<String, Double> workspaceEfficiencyScores;
    private Map<String, Map<String, Long>> applicationUsageByWorkspace;
}
