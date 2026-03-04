import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool readReceipts = true;
  bool typingIndicator = true;
  bool pushNotifications = false;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SwitchListTile(
            value: themeController.isDark.value,
            title: const Text('Dark mode'),
            onChanged: (_) => themeController.toggle(),
          ),
          SwitchListTile(
            value: readReceipts,
            title: const Text('Read receipts'),
            onChanged: (value) {
              setState(() {
                readReceipts = value;
              });
            },
          ),
          SwitchListTile(
            value: typingIndicator,
            title: const Text('Typing indicator'),
            onChanged: (value) {
              setState(() {
                typingIndicator = value;
              });
            },
          ),
          SwitchListTile(
            value: pushNotifications,
            title: const Text('Push notifications'),
            onChanged: (value) {
              setState(() {
                pushNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
