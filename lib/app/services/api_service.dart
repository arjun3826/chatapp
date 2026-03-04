import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/message.dart';
import '../models/room.dart';
import '../models/user.dart';

class ApiService extends GetxService {
  final String baseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');
  final http.Client _client = http.Client();

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final isEmail = identifier.contains('@');
    final response = await _client.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (isEmail) 'email': identifier,
        if (!isEmail) 'phone': identifier,
        'password': password,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data;
  }

  Future<List<ChatRoom>> listUserRooms(String userId) async {
    final response = await _client.get(Uri.parse('$baseUrl/users/$userId/rooms'));
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ChatRoom.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatRoom> createRoom({
    required String name,
    required String createdBy,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/rooms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'created_by': createdBy,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatRoom.fromJson(data);
  }

  Future<List<AppUser>> lookupUsersByPhones({
    required List<String> phones,
    required String requesterId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/users/lookup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phones': phones,
        'requester_id': requesterId,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppUser>> listUsers({String? excludeId}) async {
    final uri = excludeId == null || excludeId.isEmpty
        ? Uri.parse('$baseUrl/users')
        : Uri.parse('$baseUrl/users?exclude_id=$excludeId');
    final response = await _client.get(uri);
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatRoom> createDirectRoom({
    required String userId,
    required String peerId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/rooms/direct'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'peer_id': peerId,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatRoom.fromJson(data);
  }

  Future<List<ChatMessage>> listMessages({
    required String roomId,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/rooms/$roomId/messages?limit=$limit&offset=$offset',
    );
    final response = await _client.get(uri);
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> createMessage({
    required String roomId,
    required String senderId,
    required String content,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/rooms/$roomId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_id': senderId,
        'content': content,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatMessage.fromJson(data);
  }

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['detail']?.toString() ?? 'Request failed';
    } catch (_) {
      return 'Request failed';
    }
  }
}
