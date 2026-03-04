import 'package:flutter/material.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: const Text('Jamie'),
            subtitle: const Text('Missed audio call'),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.call),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: const Text('Priya'),
            subtitle: const Text('Video call, 12:45 PM'),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.videocam),
            ),
          ),
        ],
      ),
    );
  }
}
