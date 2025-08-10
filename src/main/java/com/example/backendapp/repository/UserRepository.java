// UserRepository.java
package com.example.backendapp.repository;

import com.example.backendapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email); // New method to find user by email

    // Add these methods for active user counting
    Long countByActiveTrue();
    
    @Query("SELECT COUNT(u) FROM User u WHERE u.active = true")
    Long getActiveUsersCount();
}
