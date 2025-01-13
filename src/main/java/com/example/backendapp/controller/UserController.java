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
            User registeredUser = userService.registerUser(user);
            return ResponseEntity.ok(registeredUser);
        } catch (RuntimeException e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.CONFLICT).body(response);
        }
    }

    // Login endpoint
    @PostMapping("/login")
    public ResponseEntity<Map<String, String>> loginUser(@RequestBody User loginRequest) {
        Optional<User> user = userService.findUserByUsername(loginRequest.getUsername());
        if (user.isPresent() && passwordEncoder.matches(loginRequest.getPassword(), user.get().getPassword())) {
            String token = jwtTokenProvider.createToken(user.get().getUsername());
            Map<String, String> response = new HashMap<>();
            response.put("token", token);
            response.put("userId", user.get().getId().toString());
            response.put("role", user.get().getRole());
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.status(401).body(Collections.singletonMap("error", "Invalid credentials"));
    }

    // Get profile details of the logged-in user
    @GetMapping("/profile")
    public ResponseEntity<User> getProfile(@RequestHeader("Authorization") String token) {
        String username = jwtTokenProvider.getUsername(token.replace("Bearer ", ""));
        return userService.findUserByUsername(username)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Update user profile information
    @PutMapping("/profile")
    public ResponseEntity<User> updateProfile(@RequestHeader("Authorization") String token, @RequestBody User user) {
        String username = jwtTokenProvider.getUsername(token.replace("Bearer ", ""));
        return userService.findUserByUsername(username)
                .flatMap(existingUser -> userService.updateUser(existingUser.getId(), user))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Deactivate a user account (admin-only)
    @DeleteMapping("/deactivate/{id}")
    public ResponseEntity<Map<String, String>> deactivateUser(@PathVariable Long id) {
        boolean deactivated = userService.deactivateUser(id);
        if (deactivated) {
            return ResponseEntity.ok(Collections.singletonMap("message", "User deactivated successfully"));
        }
        return ResponseEntity.status(404).body(Collections.singletonMap("error", "User not found"));
    }

    // List all users (admin-only, with filters for roles/status)
    @GetMapping("/list")
    public ResponseEntity<List<User>> listAllUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    // Find user by email
    @GetMapping("/email/{email}")
    public ResponseEntity<User> findUserByEmail(@PathVariable String email) {
        return userService.findUserByEmail(email)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Update user details
    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(@PathVariable Long id, @RequestBody User user) {
        return userService.updateUser(id, user)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Change user password
    @PutMapping("/{id}/change-password")
    public ResponseEntity<Map<String, String>> changeUserPassword(@PathVariable Long id, @RequestBody String newPassword) {
        boolean isPasswordChanged = userService.changeUserPassword(id, newPassword);
        if (isPasswordChanged) {
            return ResponseEntity.ok(Collections.singletonMap("message", "Password changed successfully"));
        }
        return ResponseEntity.status(404).body(Collections.singletonMap("error", "User not found"));
    }

    // Delete user by ID
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteUser(@PathVariable Long id) {
        if (userService.deleteUser(id)) {
            return ResponseEntity.ok(Collections.singletonMap("message", "User deleted successfully"));
        }
        return ResponseEntity.status(404).body(Collections.singletonMap("error", "User not found"));
    }
}
