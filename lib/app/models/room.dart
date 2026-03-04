import 'message.dart';

class ChatRoom {
  ChatRoom({
    required this.id,
    required this.name,
    required this.createdBy,
    this.isDirect = false,
    this.peerId,
    this.createdAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final String id;
  final String name;
  final String createdBy;
  final bool isDirect;
  final String? peerId;
  final DateTime? createdAt;
  ChatMessage? lastMessage;
  int unreadCount;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      isDirect: json['is_direct'] == true,
      peerId: json['peer_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  ChatRoom copyWith({
    ChatMessage? lastMessage,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id,
      name: name,
      createdBy: createdBy,
      isDirect: isDirect,
      peerId: peerId,
      createdAt: createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
