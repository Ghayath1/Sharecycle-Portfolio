# Chat Persistence Design

## Context
Currently, chat messages are only stored in memory and are lost when the app is closed. We need to implement local persistence to improve the user experience by maintaining chat history between app sessions.

## Goals
- Persist chat messages locally using GetStorage
- Maintain message history between app sessions
- Support offline message viewing
- Ensure messages are properly scoped to chat rooms
- Maintain message ordering

## Non-Goals
- Full offline message queuing (will be handled in a separate feature)
- Message encryption (can be added later)
- Message synchronization across devices (handled by the backend)

## Technical Decisions

### Storage Structure
```dart
// Key format: 'chat_${min(ownerId, renterId)}_${max(ownerId, renterId)}'
// This ensures the same chat room is always accessed with the same key regardless of user order

// Example storage structure:
{
  'chat_123_456': [
    {
      'id': 'msg1',
      'senderId': '123',
      'content': 'Hello!',
      'timestamp': 1625097600000,
      'status': 'delivered'
    },
    // ... more messages
  ]
}
```

### ChatStorageService API
```dart
class ChatStorageService {
  // Save a single message
  Future<void> saveMessage({
    required String chatRoomId,
    required Map<String, dynamic> message,
    required String currentUserId, // Added to determine message ownership
  });

  // Get all messages for a chat room
  // currentUserId is used to set the isMe flag on messages
  Future<List<ChatMessage>> getMessages(String chatRoomId, String currentUserId);
  
  // Clear all messages for a chat room
  Future<void> clearChat(String chatRoomId);
  
  // Get all chat rooms for the current user
  // currentUserId is used to filter chat rooms
  Future<List<ChatRoom>> getChatRooms(String currentUserId);
}
```

### Integration with ChatService
1. On chat initialization:
   - Get current_user_id from SharedPreferences
   - Load message history from local storage using current_user_id
   - Set isMe flag on messages based on current_user_id
   - Display messages while connecting to WebSocket
   - Update UI when new messages arrive from WebSocket

2. When sending a message:
   - Save to local storage immediately
   - Show message as "sending"
   - Update status when server acknowledges

3. When receiving a message:
   - Save to local storage
   - Update UI

## Data Model
```dart
class StoredMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final bool isMe; // Derived from comparing senderId with current_user_id
  final String content;
  final DateTime timestamp;
  final String status; // 'sending', 'sent', 'delivered', 'read', 'failed'
  
  // ... toMap, fromJson, etc.
}

class ChatRoom {
  final String id; // 'ownerId_renterId' (sorted)
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImageUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  
  // ... toMap, fromJson, etc.
}
```

## Error Handling
- Handle storage full errors
- Handle corrupted data
- Handle version mismatches
- Provide feedback for failed operations

## Performance Considerations
- Limit the number of messages loaded initially
- Implement pagination for older messages
- Use efficient data structures for message storage
- Consider compressing older messages

## Security Considerations
- Store sensitive data securely
- Validate all data before storage
- Sanitize message content
- Consider message retention policies

## Testing Strategy
- Unit tests for storage operations
- Widget tests for chat UI
- Integration tests for chat flow
- Performance tests for large message sets
