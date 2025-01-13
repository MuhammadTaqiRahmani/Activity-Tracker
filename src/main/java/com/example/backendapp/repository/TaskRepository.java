package com.example.backendapp.repository;

import com.example.backendapp.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {
    List<Task> findByUserIdAndStartTimeBetween(Long userId, LocalDateTime startTime, LocalDateTime endTime);
}
