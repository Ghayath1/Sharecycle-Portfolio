package com.Shrecycle.Sharecycle_backend.service;

import com.Shrecycle.Sharecycle_backend.ResponseException;
import com.Shrecycle.Sharecycle_backend.dto.FCMTokenRequest;
import com.Shrecycle.Sharecycle_backend.entity.User;
import com.Shrecycle.Sharecycle_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service for managing FCM tokens
 * Following Single Responsibility Principle - handles only FCM token management
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FCMTokenService {

    private final UserRepository userRepository;

    /**
     * Register or update FCM token for a user
     * @param userId User ID
     * @param request FCM token request
     * @throws ResponseException if user not found
     */
    @Transactional
    public void registerToken(Long userId, FCMTokenRequest request) throws ResponseException {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseException("User not found", 404));

        // Remove token from any other user who might have it (device switched users)
        userRepository.findByFcmToken(request.getFcmToken()).ifPresent(existingUser -> {
            if (!existingUser.getId().equals(userId)) {
                log.info("Removing FCM token from user {} as it's being registered to user {}", 
                        existingUser.getId(), userId);
                existingUser.setFcmToken(null);
                existingUser.setDeviceId(null);
                userRepository.save(existingUser);
            }
        });

        user.setFcmToken(request.getFcmToken());
        user.setDeviceId(request.getDeviceId());
        userRepository.save(user);
        
        log.info("FCM token registered successfully for user: {}", userId);
    }

    /**
     * Remove FCM token for a user (logout)
     * @param userId User ID
     * @throws ResponseException if user not found
     */
    @Transactional
    public void removeToken(Long userId) throws ResponseException {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseException("User not found", 404));

        user.setFcmToken(null);
        user.setDeviceId(null);
        userRepository.save(user);
        
        log.info("FCM token removed for user: {}", userId);
    }

    /**
     * Check if user has FCM token registered
     * @param userId User ID
     * @return true if token exists, false otherwise
     */
    public boolean hasToken(Long userId) {
        return userRepository.findById(userId)
                .map(user -> user.getFcmToken() != null && !user.getFcmToken().isEmpty())
                .orElse(false);
    }
}
