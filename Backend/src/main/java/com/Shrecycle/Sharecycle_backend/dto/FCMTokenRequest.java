package com.Shrecycle.Sharecycle_backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.annotation.Nullable;

/**
 * DTO for registering or updating FCM device token
 * Following Single Responsibility Principle - handles only token registration data
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FCMTokenRequest {

    @NotBlank(message = "FCM token is required")
    private String fcmToken;
    @Nullable
    private String deviceId; // Optional: to track multiple devices per user
}
