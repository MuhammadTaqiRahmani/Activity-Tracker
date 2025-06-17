package com.example.backendapp.config;

import com.example.backendapp.security.JwtAuthenticationFilter;
import com.example.backendapp.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true) // Enable @PreAuthorize annotations
public class SecurityConfig {

    @Autowired
    private UserService userService;

    @Autowired
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .cors()
            .and()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeHttpRequests(auth -> auth
                // Public endpoints - no authentication required
                .requestMatchers("/api/users/register", "/api/users/login").permitAll()
                .requestMatchers("/api/test/**").permitAll() // Allow test endpoints
                
                // User management endpoints - superadmin and admin only
                .requestMatchers("/api/users/all", "/api/users/{id}").hasAnyRole("SUPERADMIN", "ADMIN")
                .requestMatchers("/api/users/{id}/change-password").hasAnyRole("SUPERADMIN", "ADMIN")
                .requestMatchers("/api/users/deactivate/**").hasAnyRole("SUPERADMIN", "ADMIN")
                
                // Admin endpoints with additional restrictions
                .requestMatchers("/api/admin/**").hasAnyRole("SUPERADMIN", "ADMIN")
                
                // SuperAdmin only endpoints
                .requestMatchers("/api/system/**").hasRole("SUPERADMIN")
                
                // Employee process tracking endpoints
                .requestMatchers("/api/process-tracking/**").hasAnyRole("SUPERADMIN", "ADMIN", "EMPLOYEE")
                .requestMatchers("/api/security/**").hasAnyRole("SUPERADMIN", "ADMIN", "EMPLOYEE")
                
                // Analytics endpoints with role-based access
                .requestMatchers("/api/analytics/user/**").hasAnyRole("SUPERADMIN", "ADMIN", "EMPLOYEE")
                .requestMatchers("/api/analytics/admin/**").hasAnyRole("SUPERADMIN", "ADMIN")
                .requestMatchers("/api/analytics/system/**").hasRole("SUPERADMIN")
                
                // Activities endpoints
                .requestMatchers("/api/activities/user/**").hasAnyRole("SUPERADMIN", "ADMIN", "EMPLOYEE")
                .requestMatchers("/api/activities/all").hasAnyRole("SUPERADMIN", "ADMIN")
                
                // Any other endpoint requires authentication
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
