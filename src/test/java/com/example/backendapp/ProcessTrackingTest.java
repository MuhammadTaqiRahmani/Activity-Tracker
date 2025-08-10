package com.example.backendapp;

import com.example.backendapp.entity.ProcessTrack;
import com.example.backendapp.service.ProcessTrackingService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import java.util.Map;  // Add this import
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@SpringBootTest
public class ProcessTrackingTest {

    @Autowired
    private ProcessTrackingService processTrackingService;

    @Test
    public void testProcessTracking() throws Exception {
        // Get running processes using Runtime
        Process process = Runtime.getRuntime().exec("tasklist.exe");
        BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        
        List<ProcessTrack> processes = new ArrayList<>();
        String line;
        
        // Skip the header lines
        reader.readLine();
        reader.readLine();
        
        // Read only first 5 processes
        int count = 0;
        while ((line = reader.readLine()) != null && count < 5) {
            String[] parts = line.split("\\s+");
            if (parts.length >= 2) {
                ProcessTrack pt = new ProcessTrack();
                pt.setUserId(1L); // Use a test user ID
                pt.setProcessName(parts[0]);
                pt.setProcessId(parts[1]);
                pt.setStartTime(LocalDateTime.now());
                pt.setEndTime(LocalDateTime.now().plusMinutes(5));
                pt.setDurationSeconds(300L);
                
                processes.add(pt);
                count++;
            }
        }
        
        // Log each process
        for (ProcessTrack pt : processes) {
            ProcessTrack saved = processTrackingService.logProcess(pt);
            System.out.println("Logged process: " + saved.getProcessName());
        }
        
        // Get analytics
        Map<String, Object> analytics = processTrackingService.getProcessAnalytics(
            1L,
            LocalDateTime.now().minusHours(1),
            LocalDateTime.now()
        );
        
        System.out.println("Analytics: " + analytics);
    }
}
