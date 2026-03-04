import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/room.dart';

class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.room,
    required this.onTap,
  });

  final ChatRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastMessage = room.lastMessage?.content ?? 'Tap to start chatting';
    final timestamp = room.lastMessage?.createdAt;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: room.lastMessage?.content.startsWith('http') == true
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: room.lastMessage?.content ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : Text(
                room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      title: Text(
        room.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (timestamp != null)
            Text(
              DateFormat('HH:mm').format(timestamp),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          if (room.unreadCount > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                room.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
