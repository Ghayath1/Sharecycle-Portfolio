package com.Shrecycle.Sharecycle_backend.controller;

import com.Shrecycle.Sharecycle_backend.Response;
import com.Shrecycle.Sharecycle_backend.ResponseException;
import com.Shrecycle.Sharecycle_backend.dto.FCMTokenRequest;
import com.Shrecycle.Sharecycle_backend.dto.NotificationDTO;
import com.Shrecycle.Sharecycle_backend.service.FCMTokenService;
import com.Shrecycle.Sharecycle_backend.service.UserService;
import com.Shrecycle.Sharecycle_backend.service.notification.FCMNotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for FCM token management
 * Following Single Responsibility Principle - handles only FCM token endpoints
 */
@RestController
@RequestMapping("/api/fcm")
@RequiredArgsConstructor
@Tag(name = "FCM", description = "Firebase Cloud Messaging token management")
public class FCMController {

    private final FCMTokenService fcmTokenService;
    private final FCMNotificationService notificationService;
    private final UserService userService;

    @PostMapping("/test")
    @Profile("dev")
    public String test(@AuthenticationPrincipal UserDetails userDetails, @RequestBody Long receiverID) {
        //send test notification to user
        NotificationDTO notification = NotificationDTO.builder()
                .title("New message from the devil!")
                .body("Sub mate")
                .build();

        try {
            // Send notification asynchronously (non-blocking)
            notificationService.sendNotificationToUser(receiverID, notification);
            return "Notification sent successfully";
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    /**
     * Register or update FCM token for the authenticated user
     */
    @PostMapping("/token")
    @Operation(summary = "Register FCM token", description = "Register or update FCM device token for push notifications")
    public ResponseEntity<String> registerToken(
            @Valid @RequestBody FCMTokenRequest request,
            @AuthenticationPrincipal UserDetails userDetails) throws ResponseException {

        Long userId = getUserIdFromEmail(userDetails.getUsername());
        fcmTokenService.registerToken(userId, request);

        return ResponseEntity.ok("FCM token registered successfully");
    }

    /**
     * Remove FCM token (logout)
     */
    @DeleteMapping("/token")
    @Operation(summary = "Remove FCM token", description = "Remove FCM token when user logs out")
    public ResponseEntity<String> removeToken(
            @AuthenticationPrincipal UserDetails userDetails) throws ResponseException {

        Long userId = getUserIdFromEmail(userDetails.getUsername());
        fcmTokenService.removeToken(userId);

        return ResponseEntity.ok(
                "FCM token removed successfully"
        );
    }

    /**
     * Check if user has FCM token registered
     */
    @GetMapping("/token/status")
    @Operation(summary = "Check FCM token status", description = "Check if user has an active FCM token")
    public ResponseEntity<String> checkTokenStatus(
            @AuthenticationPrincipal UserDetails userDetails) {

        Long userId = getUserIdFromEmail(userDetails.getUsername());
        boolean hasToken = fcmTokenService.hasToken(userId);

        return ResponseEntity.ok(hasToken ? "Token registered" : "No token registered");
    }

    /**
     * Extract user ID from email
     */
    private Long getUserIdFromEmail(String email) {
        return userService.getUserByEmail(email).getId();
    }
}
