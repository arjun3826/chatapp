import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onEmojiTap,
    required this.onAttachTap,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onEmojiTap;
  final VoidCallback onAttachTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            IconButton(
              onPressed: onAttachTap,
              icon: const Icon(Icons.attach_file),
            ),
            IconButton(
              onPressed: onEmojiTap,
              icon: const Icon(Icons.emoji_emotions_outlined),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onSend,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
