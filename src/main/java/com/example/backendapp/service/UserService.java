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
import java.util.Collections;

import java.util.List;
import java.util.Optional;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

@Service
public class UserService implements UserDetailsService {

    // Predefined roles for the application
    public static final String ROLE_SUPERADMIN = "ROLE_SUPERADMIN";
    public static final String ROLE_ADMIN = "ROLE_ADMIN";
    public static final String ROLE_EMPLOYEE = "ROLE_EMPLOYEE";
    private static final Set<String> VALID_ROLES = new HashSet<>(Arrays.asList(
        ROLE_SUPERADMIN, ROLE_ADMIN, ROLE_EMPLOYEE
    ));

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // Register a new user
    public User registerUser(User user) {
        // Format and validate role
        String formattedRole = formatRole(user.getRole());
        
        if (!VALID_ROLES.contains(formattedRole)) {
            throw new RuntimeException("Invalid role: " + user.getRole() + 
                                    ". Valid roles are: SUPERADMIN, ADMIN, EMPLOYEE");
        }
        
        user.setRole(formattedRole);
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        user.setActive(true);
        return userRepository.save(user);
    }
    
    // Format role to ensure ROLE_ prefix
    public String formatRole(String role) {
        if (role == null) {
            return ROLE_EMPLOYEE; // Default role
        }
        
        // Remove ROLE_ prefix if it exists
        String normalizedRole = role.startsWith("ROLE_") ? 
                                role.substring(5) : role;
                                
        // Convert to uppercase
        normalizedRole = normalizedRole.toUpperCase();
        
        // Add ROLE_ prefix
        return "ROLE_" + normalizedRole;
    }

    // Find a user by username
    public Optional<User> findUserByUsername(String username) {
        return userRepository.findByUsername(username);
    }    // Find a user by email
    public Optional<User> findUserByEmail(String email) {
        return userRepository.findByEmail(email);
    }
    
    // Retrieve all users
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    // Update user details
    public Optional<User> updateUser(Long id, User updatedUser) {
        return userRepository.findById(id).map(user -> {
            user.setUsername(updatedUser.getUsername());
            
            // Update email if provided and validate uniqueness
            if (updatedUser.getEmail() != null && !updatedUser.getEmail().isEmpty()) {
                // Check if email is already taken by another user
                Optional<User> existingEmailUser = userRepository.findByEmail(updatedUser.getEmail());
                if (existingEmailUser.isPresent() && !existingEmailUser.get().getId().equals(id)) {
                    throw new RuntimeException("Email already exists: " + updatedUser.getEmail());
                }
                user.setEmail(updatedUser.getEmail());
            }
            
            if (updatedUser.getPassword() != null && !updatedUser.getPassword().isEmpty()) {
                user.setPassword(passwordEncoder.encode(updatedUser.getPassword()));
            }
            
            if (updatedUser.getRole() != null && !updatedUser.getRole().isEmpty()) {
                String formattedRole = formatRole(updatedUser.getRole());
                if (!VALID_ROLES.contains(formattedRole)) {
                    throw new RuntimeException("Invalid role: " + updatedUser.getRole());
                }
                user.setRole(formattedRole);
            }
            
            user.setActive(updatedUser.isActive());
            return userRepository.save(user);
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

    // Add deactivateUser method
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
        User user = findUserByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found with username: " + username));

        // Ensure role has ROLE_ prefix
        String role = formatRole(user.getRole());

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
