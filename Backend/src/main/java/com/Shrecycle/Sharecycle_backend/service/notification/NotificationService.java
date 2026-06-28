package com.Shrecycle.Sharecycle_backend.service.notification;

import com.Shrecycle.Sharecycle_backend.dto.NotificationDTO;

/**
 * Interface for notification services
 * Following Interface Segregation Principle and Dependency Inversion Principle
 * Allows for multiple notification implementations (FCM, Email, SMS, etc.)
 */
public interface NotificationService {
    
    /**
     * Send notification to a specific user
     * @param userId Target user ID
     * @param notification Notification content
     * @return true if sent successfully, false otherwise
     */
    boolean sendNotificationToUser(Long userId, NotificationDTO notification);
    
    /**
     * Send notification to a specific device token
     * @param token FCM device token
     * @param notification Notification content
     * @return true if sent successfully, false otherwise
     */
    boolean sendNotificationToToken(String token, NotificationDTO notification);
    
    /**
     * Send notification to multiple users
     * @param userIds List of user IDs
     * @param notification Notification content
     */
    void sendNotificationToMultipleUsers(Iterable<Long> userIds, NotificationDTO notification);
}
