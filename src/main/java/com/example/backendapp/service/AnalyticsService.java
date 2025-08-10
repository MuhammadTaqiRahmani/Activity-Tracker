package com.example.backendapp.service;

import com.example.backendapp.dto.analytics.ProductivityAnalyticsDTO;
import com.example.backendapp.entity.Activity;
import com.example.backendapp.repository.ActivityRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

import com.example.backendapp.dto.analytics.TaskAnalyticsDTO;
import com.example.backendapp.dto.analytics.WorkspaceAnalyticsDTO;
import com.example.backendapp.entity.Task;
import com.example.backendapp.repository.TaskRepository;

@Service
public class AnalyticsService {

    @Autowired
    private ActivityRepository activityRepository;

    @Autowired
    private TaskRepository taskRepository;

    public ProductivityAnalyticsDTO analyzeProductivity(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        List<Activity> activities = activityRepository.findActivitiesByUserIdAndDateRange(userId, startDate, endDate);
        
        return ProductivityAnalyticsDTO.builder()
            .dailyProductivityScore(calculateDailyProductivityScores(activities))
            .applicationUsageTime(calculateApplicationUsage(activities))
            .averageProductiveHoursPerDay(calculateAverageProductiveHours(activities))
            .totalProductiveMinutes(calculateTotalProductiveTime(activities))
            .totalIdleMinutes(calculateTotalIdleTime(activities))
            .productivityByTimeOfDay(analyzeProductivityByTimeOfDay(activities))
            .build();
    }

    public TaskAnalyticsDTO analyzeTaskCompletion(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        List<Task> tasks = taskRepository.findByUserIdAndStartTimeBetween(userId, startDate, endDate);
        
        Map<String, Double> completionRates = calculateTaskCompletionRates(tasks);
        Double avgCompletionTime = calculateAverageCompletionTime(tasks);
        
        return TaskAnalyticsDTO.builder()
            .taskCompletionRates(completionRates)
            .averageTaskCompletionTime(avgCompletionTime)
            .tasksCompletedByDate(getTasksCompletedByDate(tasks))
            .taskEfficiencyScores(calculateTaskEfficiency(tasks))
            .totalTasksCompleted((int) tasks.stream().filter(t -> t.getStatus() == Task.TaskStatus.COMPLETED).count())
            .totalTasksPending((int) tasks.stream().filter(t -> t.getStatus() == Task.TaskStatus.PENDING).count())
            .build();
    }

    public WorkspaceAnalyticsDTO analyzeWorkspaces(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        List<Activity> activities = activityRepository.findActivitiesByUserIdAndDateRange(userId, startDate, endDate);
        
        Map<String, Long> productiveTime = calculateWorkspaceTime(activities, "PRODUCTIVE");
        Map<String, Long> localTime = calculateWorkspaceTime(activities, "LOCAL");
        
        return WorkspaceAnalyticsDTO.builder()
            .productiveWorkspaceTime(productiveTime)
            .localWorkspaceTime(localTime)
            .productiveVsLocalRatio(calculateWorkspaceRatio(productiveTime, localTime))
            .workspaceEfficiencyScores(calculateWorkspaceEfficiency(activities))
            .applicationUsageByWorkspace(getApplicationUsageByWorkspace(activities))
            .build();
    }

    private Map<LocalDate, Double> calculateDailyProductivityScores(List<Activity> activities) {
        return activities.stream()
            .collect(Collectors.groupingBy(
                activity -> activity.getCreatedAt().toLocalDate(),
                Collectors.collectingAndThen(
                    Collectors.toList(),
                    dailyActivities -> {
                        long productiveTime = calculateProductiveTime(dailyActivities);
                        long totalTime = calculateTotalTime(dailyActivities);
                        return totalTime > 0 ? (double) productiveTime / totalTime : 0.0;
                    }
                )
            ));
    }

    private Map<String, Double> analyzeProductivityByTimeOfDay(List<Activity> activities) {
        Map<String, Double> productivityByHour = new HashMap<>();
        
        activities.stream()
            .collect(Collectors.groupingBy(
                activity -> activity.getCreatedAt().getHour(),
                Collectors.averagingDouble(activity -> 
                    Activity.ActivityStatus.ACTIVE.equals(activity.getStatus()) ? 1.0 : 0.0)
            ))
            .forEach((hour, productivity) -> 
                productivityByHour.put(formatHourRange(hour), productivity * 100));
        
        return productivityByHour;
    }

    private String formatHourRange(int hour) {
        return String.format("%02d:00-%02d:00", hour, (hour + 1) % 24);
    }

    private long calculateProductiveTime(List<Activity> activities) {
        return activities.stream()
            .filter(a -> Activity.ActivityStatus.ACTIVE.equals(a.getStatus()))
            .mapToLong(Activity::getDurationSeconds)
            .sum();
    }

    private long calculateTotalTime(List<Activity> activities) {
        return activities.stream()
            .mapToLong(Activity::getDurationSeconds)
            .sum();
    }

    private Double calculateAverageProductiveHours(List<Activity> activities) {
        Map<LocalDate, Long> dailyProductiveMinutes = activities.stream()
            .filter(a -> Activity.ActivityStatus.ACTIVE.equals(a.getStatus()))
            .collect(Collectors.groupingBy(
                a -> a.getCreatedAt().toLocalDate(),
                Collectors.summingLong(Activity::getDurationSeconds)
            ));

        return dailyProductiveMinutes.values().stream()
            .mapToDouble(seconds -> seconds / 3600.0)
            .average()
            .orElse(0.0);
    }

    private Map<String, Long> calculateApplicationUsage(List<Activity> activities) {
        return activities.stream()
            .filter(a -> a.getApplicationName() != null)
            .collect(Collectors.groupingBy(
                Activity::getApplicationName,
                Collectors.summingLong(Activity::getDurationSeconds)
            ));
    }

    private Long calculateTotalProductiveTime(List<Activity> activities) {
        return activities.stream()
            .filter(a -> Activity.ActivityStatus.ACTIVE.equals(a.getStatus()))
            .mapToLong(Activity::getDurationSeconds)
            .sum() / 60; // Convert seconds to minutes
    }

    private Long calculateTotalIdleTime(List<Activity> activities) {
        return activities.stream()
            .filter(a -> Activity.ActivityStatus.IDLE.equals(a.getStatus()))
            .mapToLong(Activity::getDurationSeconds)
            .sum() / 60; // Convert seconds to minutes
    }

    private Map<String, Double> calculateTaskCompletionRates(List<Task> tasks) {
        return tasks.stream()
            .collect(Collectors.groupingBy(
                task -> task.getStatus().toString(),
                Collectors.collectingAndThen(
                    Collectors.counting(),
                    count -> (double) count / tasks.size() * 100
                )
            ));
    }

    private Map<String, Map<String, Long>> getApplicationUsageByWorkspace(List<Activity> activities) {
        return activities.stream()
            .filter(a -> a.getApplicationName() != null && a.getWorkspaceType() != null)
            .collect(Collectors.groupingBy(
                Activity::getWorkspaceType,
                Collectors.groupingBy(
                    Activity::getApplicationName,
                    Collectors.summingLong(Activity::getDurationSeconds)
                )
            ));
    }

    private Map<String, Double> calculateWorkspaceEfficiency(List<Activity> activities) {
        return activities.stream()
            .filter(a -> a.getWorkspaceType() != null)
            .collect(Collectors.groupingBy(
                Activity::getWorkspaceType,
                Collectors.averagingDouble(activity -> 
                    Activity.ActivityStatus.ACTIVE.equals(activity.getStatus()) ? 1.0 : 0.0)
            ));
    }

    private Double calculateAverageCompletionTime(List<Task> tasks) {
        return tasks.stream()
            .filter(task -> task.getCompletionTime() != null && task.getStartTime() != null)
            .mapToDouble(task -> {
                long seconds = java.time.Duration.between(task.getStartTime(), task.getCompletionTime()).getSeconds();
                return seconds / 3600.0; // Convert to hours
            })
            .average()
            .orElse(0.0);
    }

    private Map<String, Double> calculateTaskEfficiency(List<Task> tasks) {
        return tasks.stream()
            .filter(task -> task.getActualHours() != null && task.getEstimatedHours() != null)
            .collect(Collectors.groupingBy(
                task -> task.getStatus().toString(),
                Collectors.averagingDouble(task -> 
                    task.getEstimatedHours() / task.getActualHours() * 100)
            ));
    }

    private Map<String, Long> calculateWorkspaceTime(List<Activity> activities, String workspaceType) {
        return activities.stream()
            .filter(a -> workspaceType.equals(a.getWorkspaceType()))
            .collect(Collectors.groupingBy(
                Activity::getApplicationName,
                Collectors.summingLong(Activity::getDurationSeconds)
            ));
    }

    private Double calculateWorkspaceRatio(Map<String, Long> productiveTime, Map<String, Long> localTime) {
        long totalProductive = productiveTime.values().stream().mapToLong(Long::longValue).sum();
        long totalLocal = localTime.values().stream().mapToLong(Long::longValue).sum();
        return totalLocal == 0 ? 0.0 : (double) totalProductive / totalLocal;
    }

    private Map<LocalDate, Integer> getTasksCompletedByDate(List<Task> tasks) {
        return tasks.stream()
            .filter(task -> task.getStatus() == Task.TaskStatus.COMPLETED && task.getCompletionTime() != null)
            .collect(Collectors.groupingBy(
                task -> task.getCompletionTime().toLocalDate(),
                Collectors.collectingAndThen(
                    Collectors.counting(),
                    count -> count.intValue()
                )
            ));
    }
}
