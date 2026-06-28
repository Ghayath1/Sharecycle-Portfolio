class ChatRoom {
  final String id;
  final String orderId;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ChatRoom({
    required this.id,
    required this.orderId,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
    };
  }
}
