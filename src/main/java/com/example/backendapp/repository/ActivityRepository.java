package com.example.backendapp.repository;

import com.example.backendapp.entity.Activity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ActivityRepository extends JpaRepository<Activity, Long> {
    List<Activity> findByUserIdAndCreatedAtBetween(Long userId, LocalDateTime start, LocalDateTime end);
    
    @Query("SELECT a FROM Activity a WHERE a.userId = :userId AND CAST(a.createdAt AS date) = CAST(CURRENT_TIMESTAMP AS date)")
    List<Activity> findTodayActivitiesByUserId(@Param("userId") Long userId);
    
    @Query("SELECT SUM(a.durationSeconds) FROM Activity a " +
           "WHERE a.userId = :userId AND a.activityType = :activityType " +
           "AND CAST(a.createdAt AS date) = CAST(CURRENT_TIMESTAMP AS date)")
    Long getTotalDurationByActivityType(@Param("userId") Long userId, @Param("activityType") String activityType);
    
    @Query("SELECT a FROM Activity a WHERE a.userId = :userId AND a.createdAt BETWEEN :startDate AND :endDate")
    List<Activity> findActivitiesInDateRange(@Param("userId") Long userId, 
                                           @Param("startDate") LocalDateTime startDate, 
                                           @Param("endDate") LocalDateTime endDate);

    @Query("SELECT a FROM Activity a WHERE a.userId = :userId AND a.createdAt BETWEEN :startDate AND :endDate")
    List<Activity> findActivitiesByUserIdAndDateRange(
        @Param("userId") Long userId,
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate
    );

    @Query("SELECT a.applicationName, SUM(a.durationSeconds) FROM Activity a " +
           "WHERE a.userId = :userId AND FUNCTION('DATE', a.createdAt) = FUNCTION('DATE', CURRENT_TIMESTAMP) " +
           "GROUP BY a.applicationName")
    List<Object[]> getApplicationUsageStats(@Param("userId") Long userId);

    @Query("SELECT SUM(a.idleTimeSeconds) FROM Activity a " +
           "WHERE a.userId = :userId AND CAST(a.createdAt AS date) = CAST(CURRENT_TIMESTAMP AS date)")
    Long getTotalIdleTime(@Param("userId") Long userId);

    @Query("SELECT a FROM Activity a WHERE a.userId = :userId ORDER BY a.createdAt DESC")
    Optional<Activity> findLatestActivityByUserId(@Param("userId") Long userId);
    
    @Query(value = "SELECT SUM(idle_time_seconds) FROM activities WHERE user_id = :userId AND CAST(created_at AS DATE) = CAST(GETDATE() AS DATE)", nativeQuery = true)
    Long getTotalIdleTimeNative(@Param("userId") Long userId);

    @Query(value = "SELECT a FROM Activity a WHERE a.userId = :userId " +
           "AND CAST(a.createdAt AS date) BETWEEN CAST(:startDate AS date) AND CAST(:endDate AS date)")
    List<Activity> findActivitiesByDateRange(
        @Param("userId") Long userId,
        @Param("startDate") LocalDateTime startDate,
        @Param("endDate") LocalDateTime endDate
    );

    Long countByUserId(Long userId);  // Add this method
}