package com.Shrecycle.Sharecycle_backend.service;

import com.Shrecycle.Sharecycle_backend.ResponseException;
import com.Shrecycle.Sharecycle_backend.dto.UserDTO;
import com.Shrecycle.Sharecycle_backend.entity.ChatMessage;
import com.Shrecycle.Sharecycle_backend.entity.User;
import com.Shrecycle.Sharecycle_backend.repository.ChatMessageRepository;
import com.Shrecycle.Sharecycle_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ChatMessageService {
    private final ChatMessageRepository chatMessageRepository;
    private final ChatRoomService chatRoomService;
    private final UserRepository userRepository;

    public ChatMessage save(ChatMessage chatMessage) throws ResponseException {
        var chatRoomId = chatRoomService.getChatRoomId(chatMessage.getSenderId(), chatMessage.getReceiverId(), true)
                .orElseThrow(() -> new ResponseException("Can't get or create chat room", 400));
        chatMessage.setChatRoomId(chatRoomId);
        ChatMessage savedMessage = chatMessageRepository.save(chatMessage);
        
        // Populate user DTOs
        populateUserDTOs(savedMessage);
        
        return savedMessage;
    }

    public List<ChatMessage> getChatMessages(Long senderId, Long receiverId) {
        var chatRoomId = chatRoomService.getChatRoomId(senderId, receiverId, false);
        // No room created yet between these two users
        if (chatRoomId.isEmpty()) {
            return new ArrayList<>();
        }

        List<ChatMessage> messages = chatMessageRepository.findByChatRoomIdOrderByCreatedAtAsc(chatRoomId.get());
        
        // Populate user DTOs for all messages
        messages.forEach(this::populateUserDTOs);
        
        return messages;
    }
    
    private void populateUserDTOs(ChatMessage chatMessage) {
        if (chatMessage.getSenderId() != null) {
            userRepository.findById(chatMessage.getSenderId())
                    .ifPresent(sender -> chatMessage.setSenderUser(new UserDTO(sender)));
        }
        
        if (chatMessage.getReceiverId() != null) {
            userRepository.findById(chatMessage.getReceiverId())
                    .ifPresent(receiver -> chatMessage.setReceiverUser(new UserDTO(receiver)));
        }
    }
}
