package com.Shrecycle.Sharecycle_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

/**
 * DTO for notification payload
 * Following Single Responsibility Principle - encapsulates notification data
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDTO {
    
    private String title;
    private String body;
    private String imageUrl;
    private Map<String, String> data; // Additional custom data
}
