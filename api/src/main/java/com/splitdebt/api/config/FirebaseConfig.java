package com.splitdebt.api.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

@Configuration
@Slf4j
public class FirebaseConfig {

    @PostConstruct
    void initializeFirebase() {
        if (!FirebaseApp.getApps().isEmpty()) {
            return;
        }

        try {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(
                            GoogleCredentials.getApplicationDefault()
                    )
                    .build();

            FirebaseApp.initializeApp(options);

            log.info(
                    "Firebase Admin initialized; FCM push is enabled"
            );

        } catch (Exception ex) {
            log.warn(
                    "Firebase credentials not found. " +
                            "Database notifications still work; " +
                            "FCM push is disabled: {}",
                    ex.getMessage()
            );
        }
    }
}