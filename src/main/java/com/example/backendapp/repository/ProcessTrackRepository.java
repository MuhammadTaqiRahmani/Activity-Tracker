package com.example.backendapp.repository;

import com.example.backendapp.entity.ProcessTrack;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface ProcessTrackRepository extends JpaRepository<ProcessTrack, Long> {
    List<ProcessTrack> findByUserIdAndStartTimeBetween(Long userId, LocalDateTime start, LocalDateTime end);
    
    @Query("SELECT pt.category, SUM(pt.durationSeconds) FROM ProcessTrack pt " +
           "WHERE pt.userId = :userId AND pt.startTime BETWEEN :start AND :end " +
           "GROUP BY pt.category")
    List<Object[]> getCategoryUsageStats(@Param("userId") Long userId, 
                                       @Param("start") LocalDateTime start, 
                                       @Param("end") LocalDateTime end);

    @Query("SELECT pt.processName, SUM(pt.durationSeconds) FROM ProcessTrack pt " +
           "WHERE pt.userId = :userId AND pt.startTime BETWEEN :start AND :end " +
           "GROUP BY pt.processName ORDER BY SUM(pt.durationSeconds) DESC")
    List<Object[]> getMostUsedApplications(@Param("userId") Long userId, 
                                         @Param("start") LocalDateTime start, 
                                         @Param("end") LocalDateTime end);
}
