import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/user.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class SelectContactScreen extends StatefulWidget {
  const SelectContactScreen({super.key});

  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<AppUser> _contacts = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final authController = Get.find<AuthController>();
    final apiService = Get.find<ApiService>();
    final currentUser = authController.currentUser.value;
    if (currentUser == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final users = await apiService.listUsers(excludeId: currentUser.id);
      if (!mounted) return;
      _contacts
        ..clear()
        ..addAll(users);
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<AppUser> get _filteredContacts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _contacts;
    }
    return _contacts
        .where(
          (user) =>
              user.name.toLowerCase().contains(query) ||
              user.phone.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select contact'),
        actions: [
          IconButton(
            onPressed: _loadContacts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_error.isNotEmpty) {
                  return Center(
                    child: Text(
                      _error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }
                final contacts = _filteredContacts;
                if (contacts.isEmpty) {
                  return Center(
                    child: Text(
                      'No contacts found',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final initial =
                        contact.name.isNotEmpty ? contact.name[0] : '?';
                    return ListTile(
                      leading: CircleAvatar(child: Text(initial)),
                      title: Text(contact.name),
                      subtitle: Text(contact.phone),
                      onTap: () async {
                        final chatController = Get.find<ChatController>();
                        final room =
                            await chatController.createDirectRoom(contact.id);
                        if (!mounted) return;
                        if (room != null) {
                          Get.toNamed(Routes.chatRoom, arguments: room);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
