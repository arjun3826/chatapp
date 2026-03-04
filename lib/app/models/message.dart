enum MessageType { text, image }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.type,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final content = json['content']?.toString() ?? '';
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: content,
      type: _inferType(content),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static MessageType _inferType(String content) {
    final lower = content.toLowerCase();
    if (lower.startsWith('http') &&
        (lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.gif'))) {
      return MessageType.image;
    }
    return MessageType.text;
  }
}
