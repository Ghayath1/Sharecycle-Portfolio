class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: "$json['id']",
      chatRoomId: "$json['chatRoomId']",
      senderId: "${json['senderId']}",
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt'] as String),
      isMe: "${json['senderId']}" == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isMe': isMe,
    };
  }
}
