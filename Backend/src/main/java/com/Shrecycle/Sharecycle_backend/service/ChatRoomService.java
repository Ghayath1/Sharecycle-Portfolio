package com.Shrecycle.Sharecycle_backend.service;

import com.Shrecycle.Sharecycle_backend.entity.ChatRoom;
import com.Shrecycle.Sharecycle_backend.repository.ChatRoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ChatRoomService {
    private final ChatRoomRepository chatRoomRepository;
    
    public Optional<String> getChatRoomId(Long senderId, Long receiverId, boolean createIfNotFound) {
        return chatRoomRepository.findFirstBySenderIdAndReceiverId(senderId, receiverId)
                .map(ChatRoom::getChatRoomId)
                .or(() -> {
                    if (!createIfNotFound) {
                        return Optional.empty();
                    }
                    var newChatRoomId = createChatRoom(senderId, receiverId);
                    return Optional.of(newChatRoomId);
                });
    }

    private String createChatRoom(Long senderId, Long receiverId) {
        String roomId = String.format("%s_%s", senderId, receiverId);

        ChatRoom receiverSenderRoom = ChatRoom
                .builder()
                .chatRoomId(roomId)
                .senderId(receiverId)
                .receiverId(senderId)
                .build();

        ChatRoom senderReceiverRoom = ChatRoom
                .builder()
                .chatRoomId(roomId)
                .senderId(senderId)
                .receiverId(receiverId)
                .build();

        chatRoomRepository.saveAll(List.of(receiverSenderRoom, senderReceiverRoom));
        return roomId;
    }

    public List<ChatRoom> getUserChatRooms(Long userId) {
        return chatRoomRepository.findBySenderIdOrReceiverId(userId, userId);
    }

    public List<ChatRoom> getUniqueChatRooms() {
        List<ChatRoom> allChatRooms = chatRoomRepository.findAll();
        Map<String, ChatRoom> uniqueChatRoomsMap = new HashMap<>();
        for (ChatRoom chatRoom : allChatRooms) {
            uniqueChatRoomsMap.putIfAbsent(chatRoom.getChatRoomId(), chatRoom);
        }
        return new ArrayList<>(uniqueChatRoomsMap.values());
    }
}
