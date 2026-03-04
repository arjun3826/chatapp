import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _statusController = TextEditingController();
  final _avatarController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(Routes.settings),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Obx(
        () {
          final user = authController.currentUser.value;
          if (user == null) {
            return const Center(child: Text('No profile loaded'));
          }
          _nameController.text = user.name;
          _statusController.text = user.status ?? 'Available';
          _avatarController.text = user.avatarUrl ?? '';
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    IconButton(
                      onPressed: () => _editAvatar(context, authController),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _statusController,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  hintText: user.email,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  authController.updateProfile(
                    name: _nameController.text.trim(),
                    status: _statusController.text.trim(),
                    avatarUrl: _avatarController.text.trim(),
                  );
                },
                child: const Text('Save changes'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: themeController.isDark.value,
                title: const Text('Dark mode'),
                onChanged: (_) => themeController.toggle(),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: authController.logout,
                child: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editAvatar(
    BuildContext context,
    AuthController authController,
  ) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profile photo URL'),
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (url != null && url.trim().isNotEmpty) {
      authController.updateProfile(
        name: authController.currentUser.value?.name ?? '',
        avatarUrl: url.trim(),
        status: authController.currentUser.value?.status ?? '',
      );
    }
  }
}
