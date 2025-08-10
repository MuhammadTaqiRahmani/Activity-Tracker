package com.example.backendapp.controller;

import com.example.backendapp.entity.User;
import com.example.backendapp.security.JwtTokenProvider;
import com.example.backendapp.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    // Register a new user
    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody User user) {
        try {
            // Normalize any role input
            User registeredUser = userService.registerUser(user);
            Map<String, Object> response = new HashMap<>();
            response.put("id", registeredUser.getId());
            response.put("username", registeredUser.getUsername());
            response.put("email", registeredUser.getEmail());
            response.put("role", registeredUser.getRole());
            response.put("active", registeredUser.isActive());
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.CONFLICT).body(response);
        }
    }

    // Login endpoint
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> loginUser(@RequestBody Map<String, String> loginRequest) {
        try {
            String username = loginRequest.get("username");
            String password = loginRequest.get("password");
            
            if (username == null || password == null) {
                return ResponseEntity.status(400)
                    .body(Collections.singletonMap("error", "Username and password are required"));
            }
            
            Optional<User> userOpt = userService.findUserByUsername(username);
            
            if (!userOpt.isPresent() || !passwordEncoder.matches(password, userOpt.get().getPassword())) {
                return ResponseEntity.status(401)
                    .body(Collections.singletonMap("error", "Invalid credentials"));
            }
            
            User user = userOpt.get();
            
            // Check if user is active
            if (!user.isActive()) {
                return ResponseEntity.status(403)
                    .body(Collections.singletonMap("error", "Account is disabled"));
            }
            
            // Create token with user information
            String token = jwtTokenProvider.createToken(username);
            
            // Return standardized response with user details and permissions
            Map<String, Object> response = new HashMap<>();
            response.put("token", token);
            response.put("userId", user.getId());
            
            // Normalize the role for frontend display (remove ROLE_ prefix)
            String roleForDisplay = user.getRole().startsWith("ROLE_") ? 
                user.getRole().substring(5) : user.getRole();
                
            response.put("role", roleForDisplay);
            response.put("username", user.getUsername());
            response.put("email", user.getEmail());
            
            // Add permissions based on role
            Map<String, Boolean> permissions = new HashMap<>();
            
            // Basic permissions for all users
            permissions.put("canTrackProcesses", true);
            permissions.put("canViewOwnStats", true);
            
            // Admin permissions
            if (user.getRole().contains("ADMIN") || user.getRole().contains("SUPERADMIN")) {
                permissions.put("canViewAllUsers", true);
                permissions.put("canViewAllActivities", true);
                permissions.put("canManageUsers", true);
            } else {
                permissions.put("canViewAllUsers", false);
                permissions.put("canViewAllActivities", false);
                permissions.put("canManageUsers", false);
            }
            
            // SuperAdmin specific permissions
            if (user.getRole().contains("SUPERADMIN")) {
                permissions.put("canManageAdmins", true);
                permissions.put("canAccessSystemSettings", true);
            } else {
                permissions.put("canManageAdmins", false);
                permissions.put("canAccessSystemSettings", false);
            }
            
            response.put("permissions", permissions);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Login failed: " + e.getMessage());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    // Get profile details of the logged-in user
    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(@RequestHeader("Authorization") String token) {
        try {
            String tokenValue = token.replace("Bearer ", "");
            String username = jwtTokenProvider.getUsername(tokenValue);
            
            return userService.findUserByUsername(username)
                    .map(user -> {
                        Map<String, Object> response = new HashMap<>();
                        response.put("id", user.getId());
                        response.put("username", user.getUsername());
                        response.put("email", user.getEmail());
                        
                        // Normalize role for frontend display
                        String roleForDisplay = user.getRole().startsWith("ROLE_") ? 
                            user.getRole().substring(5) : user.getRole();
                        response.put("role", roleForDisplay);
                        
                        response.put("active", user.isActive());
                        response.put("createdAt", user.getCreatedAt());
                        
                        return ResponseEntity.ok(response);
                    })
                    .orElse(ResponseEntity.status(404).body(Collections.singletonMap("error", "User not found")));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Collections.singletonMap("error", "Failed to get profile: " + e.getMessage()));
        }
    }

    // Update user profile information
    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(@RequestHeader("Authorization") String token, @RequestBody User user) {
        try {
            String username = jwtTokenProvider.getUsername(token.replace("Bearer ", ""));
            return userService.findUserByUsername(username)
                    .flatMap(existingUser -> userService.updateUser(existingUser.getId(), user))
                    .map(updatedUser -> {
                        Map<String, Object> response = new HashMap<>();
                        response.put("id", updatedUser.getId());
                        response.put("username", updatedUser.getUsername());
                        response.put("email", updatedUser.getEmail());
                        
                        // Normalize role for frontend display
                        String roleForDisplay = updatedUser.getRole().startsWith("ROLE_") ? 
                            updatedUser.getRole().substring(5) : updatedUser.getRole();
                        response.put("role", roleForDisplay);
                        
                        response.put("active", updatedUser.isActive());
                        response.put("message", "Profile updated successfully");
                        
                        return ResponseEntity.ok(response);
                    })
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Collections.singletonMap("error", "Failed to update profile: " + e.getMessage()));
        }
    }

    // Deactivate a user account (admin-only)
    @PostMapping("/deactivate/{id}")
    public ResponseEntity<Map<String, String>> deactivateUser(@PathVariable Long id) {
        boolean deactivated = userService.deactivateUser(id);
        if (deactivated) {
            return ResponseEntity.ok(Collections.singletonMap("message", "User deactivated successfully"));
        }
        return ResponseEntity.status(404).body(Collections.singletonMap("error", "User not found"));
    }

    // List all users (admin-only, with filters for roles/status)
    @GetMapping("/all")
    public ResponseEntity<?> listAllUsers(
            @RequestParam(required = false) String role,
            @RequestParam(required = false) Boolean active,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            List<User> allUsers = userService.getAllUsers();
            
            // Apply filters
            List<User> filteredUsers = new ArrayList<>();
            for (User user : allUsers) {
                boolean roleMatches = (role == null) || 
                    user.getRole().equalsIgnoreCase("ROLE_" + role) || 
                    user.getRole().equalsIgnoreCase(role);
                    
                boolean statusMatches = (active == null) || (user.isActive() == active);
                
                if (roleMatches && statusMatches) {
                    filteredUsers.add(user);
                }
            }
            
            // Apply pagination
            int fromIndex = page * size;
            int toIndex = Math.min(fromIndex + size, filteredUsers.size());
            
            if (fromIndex > filteredUsers.size()) {
                fromIndex = 0;
                toIndex = Math.min(size, filteredUsers.size());
            }
            
            List<User> pagedUsers = filteredUsers.subList(fromIndex, toIndex);
            
            // Map to DTO to remove sensitive information
            List<Map<String, Object>> userDtos = new ArrayList<>();
            for (User user : pagedUsers) {
                Map<String, Object> userDto = new HashMap<>();
                userDto.put("id", user.getId());
                userDto.put("username", user.getUsername());
                userDto.put("email", user.getEmail());
                
                // Normalize role for frontend display
                String roleForDisplay = user.getRole().startsWith("ROLE_") ? 
                    user.getRole().substring(5) : user.getRole();
                userDto.put("role", roleForDisplay);
                
                userDto.put("active", user.isActive());
                userDto.put("createdAt", user.getCreatedAt());
                
                userDtos.add(userDto);
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("users", userDtos);
            response.put("totalUsers", filteredUsers.size());
            response.put("currentPage", page);
            response.put("totalPages", (int) Math.ceil((double) filteredUsers.size() / size));
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Collections.singletonMap("error", "Failed to retrieve users: " + e.getMessage()));
        }
    }

    // Find user by email
    @GetMapping("/email/{email}")
    public ResponseEntity<?> findUserByEmail(@PathVariable String email) {
        try {
            return userService.findUserByEmail(email)
                    .map(user -> {
                        Map<String, Object> response = new HashMap<>();
                        response.put("id", user.getId());
                        response.put("username", user.getUsername());
                        response.put("email", user.getEmail());
                        
                        // Normalize role for frontend display
                        String roleForDisplay = user.getRole().startsWith("ROLE_") ? 
                            user.getRole().substring(5) : user.getRole();
                        response.put("role", roleForDisplay);
                        
                        response.put("active", user.isActive());
                        response.put("createdAt", user.getCreatedAt());
                        
                        return ResponseEntity.ok(response);
                    })
                    .orElse(ResponseEntity.status(404).body(Collections.singletonMap("error", "User not found")));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Collections.singletonMap("error", "Failed to find user: " + e.getMessage()));
        }
    }

    // Update user details (admin only)
    @PutMapping("/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody User user) {
        try {
            return userService.updateUser(id, user)
                    .map(updatedUser -> {
                        Map<String, Object> response = new HashMap<>();
                        response.put("id", updatedUser.getId());
                        response.put("username", updatedUser.getUsername());
                        response.put("email", updatedUser.getEmail());
                        
                        // Normalize role for frontend display
                        String roleForDisplay = updatedUser.getRole().startsWith("ROLE_") ? 
                            updatedUser.getRole().substring(5) : updatedUser.getRole();
                        response.put("role", roleForDisplay);
                        
                        response.put("active", updatedUser.isActive());
                        response.put("message", "User updated successfully");
                        
                        return ResponseEntity.ok(response);
                    })
                    .orElse(ResponseEntity.status(404).body(Collections.singletonMap("error", "User not found")));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Collections.singletonMap("error", "Failed to update user: " + e.getMessage()));
        }
    }

    // Change user password
    @PutMapping("/{id}/change-password")
    public ResponseEntity<Map<String, String>> changeUserPassword(@PathVariable Long id, @RequestBody Map<String, String> passwordRequest) {
        try {
            String newPassword = passwordRequest.get("newPassword");
            if (newPassword == null || newPassword.isEmpty()) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "New password is required"));
            }
            
            boolean isPasswordChanged = userService.changeUserPassword(id, newPassword);
            if (isPasswordChanged) {
                return ResponseEntity.ok(Collections.singletonMap("message", "Password changed successfully"));
            }
            return ResponseEntity.status(404).body(Collections.singletonMap("error", "User not found"));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Collections.singletonMap("error", "Failed to change password: " + e.getMessage()));
        }
    }

    // Delete user by ID (admin only)
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteUser(@PathVariable Long id) {
        try {
            if (userService.deleteUser(id)) {
                return ResponseEntity.ok(Collections.singletonMap("message", "User deleted successfully"));
            }
            return ResponseEntity.status(404).body(Collections.singletonMap("error", "User not found"));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Collections.singletonMap("error", "Failed to delete user: " + e.getMessage()));
        }
    }
}
