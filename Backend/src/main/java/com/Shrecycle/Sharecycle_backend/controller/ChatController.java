package com.Shrecycle.Sharecycle_backend.controller;

import com.Shrecycle.Sharecycle_backend.ResponseException;
import com.Shrecycle.Sharecycle_backend.dto.NotificationDTO;
import com.Shrecycle.Sharecycle_backend.entity.ChatMessage;
import com.Shrecycle.Sharecycle_backend.entity.ChatRoom;
import com.Shrecycle.Sharecycle_backend.entity.User;
import com.Shrecycle.Sharecycle_backend.repository.UserRepository;
import com.Shrecycle.Sharecycle_backend.service.ChatMessageService;
import com.Shrecycle.Sharecycle_backend.service.ChatRoomService;
import com.Shrecycle.Sharecycle_backend.service.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequiredArgsConstructor
@Slf4j
public class ChatController {
    private final ChatMessageService chatMessageService;
    private final ChatRoomService chatRoomService;
    private final SimpMessagingTemplate messagingTemplate;
    private final NotificationService notificationService;
    private final UserRepository userRepository;

    @GetMapping("/messages/{senderId}/{receiverId}")
    public ResponseEntity<List<ChatMessage>> getChatMessages(@PathVariable Long senderId, @PathVariable Long receiverId) {
        return ResponseEntity.ok(chatMessageService.getChatMessages(senderId, receiverId));
    }

    @GetMapping("/chat-rooms/{userId}")
    public ResponseEntity<List<ChatRoom>> getUserChatRooms(@PathVariable Long userId) {
        return ResponseEntity.ok(chatRoomService.getUserChatRooms(userId));
    }

    @GetMapping("/chat-rooms")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<ChatRoom>> getUniqueChatRooms() {
        return ResponseEntity.ok(chatRoomService.getUniqueChatRooms());
    }

    @MessageMapping("/chat.sendMessage")
    public void processMessage(@Payload ChatMessage chatMessage) throws ResponseException {
        ChatMessage newMessage = chatMessageService.save(chatMessage);

        // Send to receiver via WebSocket (if online)
        messagingTemplate.convertAndSendToUser(
                chatMessage.getReceiverId().toString(),
                "/queue/messages",
                newMessage
        );

        // Send confirmation to sender via WebSocket
        messagingTemplate.convertAndSendToUser(
                chatMessage.getSenderId().toString(),
                "/queue/messages",
                newMessage
        );

        // Send FCM push notification to receiver (works even if app is closed)
        sendPushNotification(chatMessage);
    }

    /**
     * Send FCM push notification for new message
     * Following Single Responsibility Principle - extracted notification logic
     */
    private void sendPushNotification(ChatMessage chatMessage) {
        try {
            // Get sender information
            User sender = userRepository.findById(chatMessage.getSenderId()).orElse(null);
            if (sender == null) {
                log.warn("Sender not found for message notification: {}", chatMessage.getSenderId());
                return;
            }

            // Build notification data
            Map<String, String> data = new HashMap<>();
            data.put("type", "chat_message");
            data.put("senderId", chatMessage.getSenderId().toString());
            data.put("chatRoomId", chatMessage.getChatRoomId());
            data.put("messageId", chatMessage.getId() != null ? chatMessage.getId().toString() : "");

            NotificationDTO notification = NotificationDTO.builder()
                    .title("New message from " + sender.getName())
                    .body(chatMessage.getContent())
                    .imageUrl(sender.getImageUrl())
                    .data(data)
                    .build();

            // Send notification asynchronously (non-blocking)
            notificationService.sendNotificationToUser(chatMessage.getReceiverId(), notification);

        } catch (Exception e) {
            // Log error but don't fail the message sending
            log.error("Failed to send push notification for message: {}", e.getMessage());
        }
    }
}
