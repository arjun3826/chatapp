import 'package:flutter/material.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('My Status'),
            subtitle: const Text('Tap to add status update'),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recent updates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: const Text('Alex'),
            subtitle: const Text('Today, 9:30 AM'),
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: const Text('Maria'),
            subtitle: const Text('Yesterday, 8:10 PM'),
          ),
        ],
      ),
    );
  }
}
