package com.example.backendapp.service;

import org.springframework.stereotype.Service;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AntiTamperingService {
    private final ConcurrentHashMap<String, String> processHashes = new ConcurrentHashMap<>();
    
    public String calculateHash(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes());
            return Base64.getEncoder().encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Hash calculation failed", e);
        }
    }

    public boolean validateActivityHash(String activityId, String hash) {
        String storedHash = processHashes.get(activityId);
        return storedHash != null && storedHash.equals(hash);
    }

    public void storeProcessHash(String processId, String hash) {
        processHashes.put(processId, hash);
    }

    public boolean isValidProcess(String processId, String machineId) {
        // Implement process validation logic
        return true; // Placeholder
    }
}
