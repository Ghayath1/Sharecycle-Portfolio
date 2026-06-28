package com.Shrecycle.Sharecycle_backend.repository;

import com.Shrecycle.Sharecycle_backend.entity.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    List<ChatMessage> findByChatRoomIdOrderByCreatedAtAsc(String chatRoomId);
}
