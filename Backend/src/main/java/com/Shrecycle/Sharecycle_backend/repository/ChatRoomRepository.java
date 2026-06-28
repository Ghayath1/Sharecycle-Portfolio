package com.Shrecycle.Sharecycle_backend.repository;

import com.Shrecycle.Sharecycle_backend.entity.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
    Optional<ChatRoom> findFirstBySenderIdAndReceiverId(Long senderId, Long receiverId);
    List<ChatRoom> findBySenderIdOrReceiverId(Long senderId, Long receiverId);
}
