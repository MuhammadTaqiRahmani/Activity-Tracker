package com.example.backendapp.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "process_tracks")
@Data
public class ProcessTrack {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String processName;

    @Column(nullable = false)
    private String windowTitle;

    @Column(name = "process_id", nullable = false)
    private String processId;

    @Column
    private String category; // DEVELOPMENT, COMMUNICATION, BROWSER, ENTERTAINMENT, etc.

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    @Column(name = "end_time")
    private LocalDateTime endTime;

    @Column(name = "duration_seconds")
    private Long durationSeconds;

    @Column(name = "is_productive_app")
    private Boolean isProductiveApp;

    @Column(name = "application_path")
    private String applicationPath;

    @PrePersist
    protected void onCreate() {
        if (startTime == null) {
            startTime = LocalDateTime.now();
        }
        if (endTime == null) {
            endTime = startTime.plusMinutes(1);
        }
        System.out.println("Pre-persist ProcessTrack: " + this.toString());
    }

    @PostPersist
    protected void afterSave() {
        System.out.println("Saved ProcessTrack with ID: " + this.id);
    }
}
