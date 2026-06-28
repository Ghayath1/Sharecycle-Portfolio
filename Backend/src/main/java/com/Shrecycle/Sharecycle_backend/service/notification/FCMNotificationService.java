package com.Shrecycle.Sharecycle_backend.service.notification;

import com.Shrecycle.Sharecycle_backend.dto.NotificationDTO;
import com.Shrecycle.Sharecycle_backend.entity.User;
import com.Shrecycle.Sharecycle_backend.repository.UserRepository;
import com.google.firebase.ErrorCode;
import com.google.firebase.messaging.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * FCM implementation of NotificationService
 * Following Single Responsibility Principle - handles only FCM notifications
 * Following Dependency Inversion Principle - depends on abstraction (NotificationService)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FCMNotificationService implements NotificationService {

    private final UserRepository userRepository;

    @Override
    public boolean sendNotificationToUser(Long userId, NotificationDTO notification) {
        User user = userRepository.findById(userId).orElse(null);

        if (user == null) {
            log.warn("User not found with ID: {}", userId);
            return false;
        }

        if (user.getFcmToken() == null || user.getFcmToken().isEmpty()) {
            log.warn("User {} has no FCM token registered", userId);
            return false;
        }

        return sendNotificationToToken(user.getFcmToken(), notification);
    }

    @Override
    public boolean sendNotificationToToken(String token, NotificationDTO notification) {
        try {
            Message message = buildMessage(token, notification);
            String response = FirebaseMessaging.getInstance().send(message);
            log.info("Successfully sent FCM message: {}", response);
            return true;
        } catch (FirebaseMessagingException e) {
            log.error("Failed to send FCM notification to token {}: {}", token, e.getMessage());
            handleFirebaseException(e, token);
            return false;
        } catch (Exception e) {
            log.error("Unexpected error sending FCM notification: {}", e.getMessage());
            return false;
        }
    }

    @Override
    public void sendNotificationToMultipleUsers(Iterable<Long> userIds, NotificationDTO notification) {
        List<String> tokens = new ArrayList<>();

        for (Long userId : userIds) {
            User user = userRepository.findById(userId).orElse(null);
            if (user != null && user.getFcmToken() != null && !user.getFcmToken().isEmpty()) {
                tokens.add(user.getFcmToken());
            }
        }

        if (tokens.isEmpty()) {
            log.warn("No valid FCM tokens found for the provided user IDs");
            return;
        }

        sendToMultipleTokens(tokens, notification);
    }

    /**
     * Send notification to multiple tokens using multicast
     */
    private void sendToMultipleTokens(List<String> tokens, NotificationDTO notification) {
        try {
            MulticastMessage message = buildMulticastMessage(tokens, notification);
            BatchResponse response = FirebaseMessaging.getInstance().sendMulticast(message);

            log.info("Successfully sent {} messages, {} failures",
                    response.getSuccessCount(), response.getFailureCount());

            // Handle failed tokens
            if (response.getFailureCount() > 0) {
                List<SendResponse> responses = response.getResponses();
                for (int i = 0; i < responses.size(); i++) {
                    if (!responses.get(i).isSuccessful()) {
                        log.error("Failed to send to token {}: {}",
                                tokens.get(i), responses.get(i).getException().getMessage());
                    }
                }
            }
        } catch (FirebaseMessagingException e) {
            log.error("Failed to send multicast FCM notification: {}", e.getMessage());
        }
    }

    /**
     * Build FCM message with notification and data payload
     */
    private Message buildMessage(String token, NotificationDTO notificationDTO) {
        Notification notification = Notification.builder()
                .setTitle(notificationDTO.getTitle())
                .setBody(notificationDTO.getBody())
                .setImage(notificationDTO.getImageUrl())
                .build();

        Message.Builder messageBuilder = Message.builder()
                .setToken(token)
                .setNotification(notification);

        // Add custom data if provided
        if (notificationDTO.getData() != null && !notificationDTO.getData().isEmpty()) {
            messageBuilder.putAllData(notificationDTO.getData());
        }

        // Android-specific configuration
        AndroidConfig androidConfig = AndroidConfig.builder()
                .setPriority(AndroidConfig.Priority.HIGH)
                .setNotification(AndroidNotification.builder()
                        .setSound("default")
                        .setChannelId("sharecycle_messages")
                        .build())
                .build();

        // iOS-specific configuration
        ApnsConfig apnsConfig = ApnsConfig.builder()
                .setAps(Aps.builder()
                        .setSound("default")
                        .setBadge(1)
                        .build())
                .build();

        messageBuilder.setAndroidConfig(androidConfig);
        messageBuilder.setApnsConfig(apnsConfig);

        return messageBuilder.build();
    }

    /**
     * Build multicast message for multiple tokens
     */
    private MulticastMessage buildMulticastMessage(List<String> tokens, NotificationDTO notificationDTO) {
        Notification notification = Notification.builder()
                .setTitle(notificationDTO.getTitle())
                .setBody(notificationDTO.getBody())
                .setImage(notificationDTO.getImageUrl())
                .build();

        MulticastMessage.Builder messageBuilder = MulticastMessage.builder()
                .addAllTokens(tokens)
                .setNotification(notification);

        if (notificationDTO.getData() != null && !notificationDTO.getData().isEmpty()) {
            messageBuilder.putAllData(notificationDTO.getData());
        }

        return messageBuilder.build();
    }

    /**
     * Handle Firebase exceptions and clean up invalid tokens
     */
    private void handleFirebaseException(FirebaseMessagingException e, String token) {
        ErrorCode errorCode = e.getErrorCode();

        // Remove invalid or unregistered tokens
        if (ErrorCode.INVALID_ARGUMENT.equals(errorCode) || ErrorCode.NOT_FOUND.equals(errorCode)) {
            log.warn("Removing invalid FCM token: {}", token);
            removeInvalidToken(token);
        }
    }

    /**
     * Remove invalid token from database
     */
    private void removeInvalidToken(String token) {
        userRepository.findByFcmToken(token).ifPresent(user -> {
            user.setFcmToken(null);
            user.setDeviceId(null);
            userRepository.save(user);
            log.info("Removed invalid FCM token for user: {}", user.getId());
        });
    }
}
