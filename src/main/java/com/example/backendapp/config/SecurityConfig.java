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
            .authorizeHttpRequests(auth -> auth                // Public endpoints - no authentication required
                .requestMatchers("/api/users/register", "/api/users/login").permitAll()
                .requestMatchers("/api/test/**").permitAll() // Allow test endpoints
                  // Profile endpoint - accessible to all authenticated users
                .requestMatchers("/api/users/profile").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN", "ROLE_EMPLOYEE")
                
                // User management endpoints - superadmin and admin only
                .requestMatchers("/api/users/all", "/api/users/{id}").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN")
                .requestMatchers("/api/users/{id}/change-password").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN")
                .requestMatchers("/api/users/deactivate/**").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN")
                
                // Admin endpoints with additional restrictions
                .requestMatchers("/api/admin/**").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN")
                
                // SuperAdmin only endpoints
                .requestMatchers("/api/system/**").hasAuthority("ROLE_SUPERADMIN")
                
                // Employee process tracking endpoints
                .requestMatchers("/api/process-tracking/**").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN", "ROLE_EMPLOYEE")
                .requestMatchers("/api/security/**").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN", "ROLE_EMPLOYEE")
                
                // Analytics endpoints with role-based access
                .requestMatchers("/api/analytics/user/**").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN", "ROLE_EMPLOYEE")
                .requestMatchers("/api/analytics/admin/**").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN")
                .requestMatchers("/api/analytics/system/**").hasAuthority("ROLE_SUPERADMIN")
                
                // Activities endpoints
                .requestMatchers("/api/activities/user/**").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN", "ROLE_EMPLOYEE")
                .requestMatchers("/api/activities/all").hasAnyAuthority("ROLE_SUPERADMIN", "ROLE_ADMIN")
                
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
