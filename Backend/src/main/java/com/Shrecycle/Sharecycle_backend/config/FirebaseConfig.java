package com.Shrecycle.Sharecycle_backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import jakarta.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * Firebase Configuration
 * Following Single Responsibility Principle - handles only Firebase initialization
 */
@Configuration
@Slf4j
public class FirebaseConfig {

    @Value("${firebase.config.path:firebase-service-account.json}")
    private String firebaseConfigPath;

    @PostConstruct
    public void initialize() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                InputStream serviceAccount = getServiceAccountStream();
                
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
                log.info("Firebase application initialized successfully");
            }
        } catch (IOException e) {
            log.error("Failed to initialize Firebase: {}", e.getMessage());
            log.warn("FCM notifications will not be available. Please configure firebase-service-account.json");
        }
    }

    private InputStream getServiceAccountStream() throws IOException {
        try {
            // Try to load from classpath (resources folder)
            return new ClassPathResource(firebaseConfigPath).getInputStream();
        } catch (IOException e) {
            // Try to load from file system
            log.warn("Could not load from classpath, trying file system: {}", firebaseConfigPath);
            return new FileInputStream(firebaseConfigPath);
        }
    }
}
