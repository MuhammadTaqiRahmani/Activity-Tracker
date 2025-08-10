package com.example.backendapp.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "activities")
@Data
public class Activity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;    // Foreign key reference to User entity (constraint handled by database migration)
    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String activityType;

    @Column(nullable = false)
    private String description;

    @Column(name = "application_name")
    private String applicationName;

    @Column(name = "workspace_type")
    private String workspaceType;

    @Column(name = "duration_seconds")
    private Long durationSeconds;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "idle_time_seconds")
    private Long idleTimeSeconds;

    @Column(name = "activity_status")
    @Enumerated(EnumType.STRING)
    private ActivityStatus status;

    public enum ActivityStatus {
        ACTIVE, IDLE, OFFLINE
    }

    @Column(name = "application_category")
    private String applicationCategory; // e.g., "DEVELOPMENT", "COMMUNICATION", "BROWSER"

    @Column(name = "process_id")
    private String processId;

    @Column(name = "process_name")
    private String processName;  // Add this field

    @Column(name = "window_title")
    private String windowTitle;

    @Column(name = "ip_address")
    private String ipAddress;

    @Column(name = "machine_id")
    private String machineId;

    @Column(name = "tamper_attempt")
    private Boolean tamperAttempt = false;

    @Column(name = "tamper_details")
    private String tamperDetails;

    @Column(name = "hash_value")
    private String hashValue;

    @Column(name = "start_time")
    private LocalDateTime startTime;

    @Column(name = "end_time")
    private LocalDateTime endTime;

    @Version
    private Long version;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (startTime == null) {
            startTime = LocalDateTime.now();
        }
        if (endTime == null) {
            endTime = startTime.plusMinutes(1);
        }
        if (status == null) {
            status = ActivityStatus.ACTIVE;
        }
        if (tamperAttempt == null) {
            tamperAttempt = false;
        }
        if (version == null) {
            version = 0L;
        }
        System.out.println("PrePersist - Activity being saved: " + this);
    }

    @PostPersist
    protected void afterSave() {
        System.out.println("PostPersist - Activity saved with ID: " + this.id);
    }
}
