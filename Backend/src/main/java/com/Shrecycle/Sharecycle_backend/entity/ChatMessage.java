package com.Shrecycle.Sharecycle_backend.entity;

import com.Shrecycle.Sharecycle_backend.dto.UserDTO;
import com.Shrecycle.Sharecycle_backend.enums.MessageType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
public class ChatMessage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String chatRoomId;
    private Long senderId;
    private Long receiverId;
    @Builder.Default
    private MessageType type = MessageType.CHAT;
    private String content;
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
    
    @Transient
    private UserDTO senderUser;
    
    @Transient
    private UserDTO receiverUser;
}
