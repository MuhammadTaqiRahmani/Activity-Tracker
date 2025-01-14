package com.example.backendapp.service;

import com.example.backendapp.entity.User;
import com.example.backendapp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.Collections;

import java.util.List;
import java.util.Optional;

@Service
public class UserService implements UserDetailsService {

    private static final Logger logger = LoggerFactory.getLogger(UserService.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // Register a new user
    public User registerUser(User user) {
        // Add ROLE_ prefix if not present
        if (!user.getRole().startsWith("ROLE_")) {
            user.setRole("ROLE_" + user.getRole());
        }
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        user.setActive(true);
        return userRepository.save(user);
    }

    // Find a user by username
    public Optional<User> findUserByUsername(String username) {
        return userRepository.findByUsername(username);
    }

    // Find a user by email
    public Optional<User> findUserByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    // Retrieve all users
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    // Update user details
    public Optional<User> updateUser(Long id, User updatedUser) {
        return userRepository.findById(id)
            .map(existingUser -> {
                // Update only if new values are provided
                if (updatedUser.getUsername() != null) {
                    existingUser.setUsername(updatedUser.getUsername());
                }
                if (updatedUser.getEmail() != null) {
                    existingUser.setEmail(updatedUser.getEmail());
                }
                if (updatedUser.getPassword() != null) {
                    existingUser.setPassword(passwordEncoder.encode(updatedUser.getPassword()));
                }
                // Preserve role and active status
                existingUser.setRole(existingUser.getRole());
                existingUser.setActive(existingUser.isActive());
                
                return userRepository.save(existingUser);
            });
    }

    // Change user password
    public boolean changeUserPassword(Long id, String newPassword) {
        Optional<User> userOptional = userRepository.findById(id);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            user.setPassword(passwordEncoder.encode(newPassword));
            userRepository.save(user);
            return true;
        }
        return false;
    }

    // Delete a user by ID
    public boolean deleteUser(Long id) {
        if (userRepository.existsById(id)) {
            userRepository.deleteById(id);
            return true;
        }
        return false;
    }

    // Add findById method
    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }

    // Add getUser method with exception handling
    public User getUser(Long id) {
        return findById(id)
            .orElseThrow(() -> new RuntimeException("User not found with id: " + id));
    }

    // Add this new method
    public boolean deactivateUser(Long id) {
        return userRepository.findById(id).map(user -> {
            user.setActive(false);
            userRepository.save(user);
            return true;
        }).orElse(false);
    }

    public Long getActiveUsersCount() {
        return userRepository.countByActiveTrue();
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        logger.debug("Loading user by username: {}", username);
        
        User user = findUserByUsername(username)
            .orElseThrow(() -> {
                logger.error("User not found with username: {}", username);
                return new UsernameNotFoundException("User not found with username: " + username);
            });

        // Ensure role has ROLE_ prefix
        String role = user.getRole().startsWith("ROLE_") ? user.getRole() : "ROLE_" + user.getRole();
        
        logger.debug("User found: {} with role: {}", username, role);

        return org.springframework.security.core.userdetails.User
            .withUsername(user.getUsername())
            .password(user.getPassword())
            .authorities(Collections.singletonList(new SimpleGrantedAuthority(role)))
            .accountExpired(false)
            .accountLocked(false)
            .credentialsExpired(false)
            .disabled(!user.isActive())
            .build();
    }
}
