package com.example.backendapp.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import javax.sql.DataSource;
import java.sql.Connection;

@Configuration
public class DatabaseConfig {

    @Autowired
    private DataSource dataSource;

    @Bean
    public CommandLineRunner checkDatabaseConnection() {
        return args -> {
            System.out.println("\n=== Checking Database Connection ===");
            try (Connection conn = dataSource.getConnection()) {
                System.out.println("Database connection successful!");
                System.out.println("URL: " + conn.getMetaData().getURL());
                System.out.println("Schema: " + conn.getSchema());
                System.out.println("================================\n");
            } catch (Exception e) {
                System.err.println("Database connection failed!");
                e.printStackTrace();
                throw e;
            }
        };
    }
}
