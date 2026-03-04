import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/room.dart';
import '../../services/websocket_service.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _textController = TextEditingController();
  late final ChatRoom _room;

  @override
  void initState() {
    super.initState();
    _room = Get.arguments as ChatRoom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ChatController>().openRoom(_room);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final authController = Get.find<AuthController>();
    final room = _room;
    final userId = authController.currentUser.value?.id ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.name),
            Obx(
              () => Text(
                _statusLabel(chatController.socketStatus),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(
              () {
                final messages = chatController.messagesForRoom(room.id);
                if (chatController.isLoadingMessages.value && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == userId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          ChatBubble(message: message, isMe: isMe),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ChatInput(
            controller: _textController,
            onEmojiTap: () => _openEmojiPicker(context),
            onAttachTap: () => _openAttachmentSheet(context),
            onSend: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty) {
                chatController.sendText(text);
                _textController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  String _statusLabel(SocketStatus status) {
    switch (status) {
      case SocketStatus.connected:
        return 'Online';
      case SocketStatus.connecting:
        return 'Connecting...';
      case SocketStatus.disconnected:
        return 'Offline';
    }
  }

  Future<void> _openEmojiPicker(BuildContext context) async {
    final emojis = ['😀', '😂', '😍', '😎', '😭', '👍', '🙏', '🎉'];
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 180,
          child: GridView.count(
            crossAxisCount: 4,
            children: emojis
                .map(
                  (emoji) => InkWell(
                    onTap: () => Navigator.pop(context, emoji),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (chosen != null) {
      _textController.text = '${_textController.text}$chosen';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
  }

  Future<void> _openAttachmentSheet(BuildContext context) async {
    final chatController = Get.find<ChatController>();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Send sample image'),
                onTap: () => Navigator.pop(context, 'sample'),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Send image URL'),
                onTap: () => Navigator.pop(context, 'url'),
              ),
            ],
          ),
        );
      },
    );
    if (action == 'sample') {
      chatController.sendImage(
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
      );
    }
    if (action == 'url') {
      final controller = TextEditingController();
      final url = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Image URL'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'https://'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Send'),
              ),
            ],
          );
        },
      );
      if (url != null && url.trim().isNotEmpty) {
        chatController.sendImage(url.trim());
      }
    }
  }
}
