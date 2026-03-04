import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/chat_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/chat_list_tile.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            onPressed: chatController.loadRooms,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => Get.toNamed(Routes.settings),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Obx(
        () {
          if (chatController.isLoadingRooms.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chatController.rooms.isEmpty) {
            return Center(
              child: Text(
                'No chats yet',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return ListView.separated(
            itemCount: chatController.rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final room = chatController.rooms[index];
              return ChatListTile(
                room: room,
                onTap: () {
                  Get.toNamed(Routes.chatRoom, arguments: room);
                },
              );
            },
          );
        },
      ),
    );
  }
}
