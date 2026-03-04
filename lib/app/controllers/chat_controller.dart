import 'dart:async';

import 'package:get/get.dart';

import '../models/message.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class ChatController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final WebSocketService _webSocketService = Get.find<WebSocketService>();

  final RxList<ChatRoom> rooms = <ChatRoom>[].obs;
  final RxMap<String, List<ChatMessage>> messagesByRoom =
      <String, List<ChatMessage>>{}.obs;
  final RxnString activeRoomId = RxnString();
  final RxBool isLoadingRooms = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxString error = ''.obs;

  StreamSubscription<ChatMessage>? _subscription;
  AppUser? _currentUser;

  SocketStatus get socketStatus => _webSocketService.status.value;

  void initForUser(AppUser user) {
    _currentUser = user;
    loadRooms();
    _subscription?.cancel();
    _subscription = _webSocketService.messagesStream.listen(_onIncomingMessage);
  }

  Future<void> loadRooms() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      isLoadingRooms.value = true;
      error.value = '';
      final fetchedRooms = await _apiService.listUserRooms(user.id);
      rooms.assignAll(fetchedRooms);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingRooms.value = false;
    }
  }

  Future<void> createRoom(String name) async {
    final user = _currentUser;
    if (user == null) return;
    try {
      final room = await _apiService.createRoom(
        name: name,
        createdBy: user.id,
      );
      rooms.insert(0, room);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<ChatRoom?> createDirectRoom(String peerId) async {
    final user = _currentUser;
    if (user == null) return null;
    try {
      final room = await _apiService.createDirectRoom(
        userId: user.id,
        peerId: peerId,
      );
      final existingIndex = rooms.indexWhere((item) => item.id == room.id);
      if (existingIndex == -1) {
        rooms.insert(0, room);
      } else {
        rooms[existingIndex] = room;
      }
      return room;
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      return null;
    }
  }

  Future<void> openRoom(ChatRoom room) async {
    activeRoomId.value = room.id;
    await _connectSocket(room.id);
    await loadMessages(room.id);
    _markRoomRead(room.id);
  }

  Future<void> loadMessages(String roomId) async {
    try {
      isLoadingMessages.value = true;
      error.value = '';
      final messages = await _apiService.listMessages(roomId: roomId);
      messagesByRoom[roomId] = messages;
      _updateRoomLastMessage(roomId, messages.isNotEmpty ? messages.last : null);
      messagesByRoom.refresh();
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> sendText(String text) async {
    final roomId = activeRoomId.value;
    if (roomId == null || _currentUser == null || text.trim().isEmpty) return;
    _webSocketService.send(text.trim());
  }

  Future<void> sendImage(String url) async {
    final roomId = activeRoomId.value;
    if (roomId == null || _currentUser == null) return;
    _webSocketService.send(url);
  }

  List<ChatMessage> messagesForRoom(String roomId) {
    return messagesByRoom[roomId] ?? <ChatMessage>[];
  }

  void _onIncomingMessage(ChatMessage message) {
    final list = List<ChatMessage>.from(
      messagesByRoom[message.roomId] ?? <ChatMessage>[],
    );
    list.add(message);
    messagesByRoom[message.roomId] = list;
    messagesByRoom.refresh();
    _updateRoomLastMessage(message.roomId, message);
    if (activeRoomId.value == message.roomId) {
      _markRoomRead(message.roomId);
    } else {
      _incrementUnread(message.roomId);
    }
  }

  Future<void> _connectSocket(String roomId) async {
    final user = _currentUser;
    if (user == null) return;
    await _webSocketService.connect(
      baseUrl: _apiService.baseUrl,
      roomId: roomId,
      userId: user.id,
    );
  }

  void _updateRoomLastMessage(String roomId, ChatMessage? message) {
    final index = rooms.indexWhere((room) => room.id == roomId);
    if (index == -1) return;
    final updatedRoom = rooms[index].copyWith(lastMessage: message);
    rooms[index] = updatedRoom;
  }

  void _incrementUnread(String roomId) {
    final index = rooms.indexWhere((room) => room.id == roomId);
    if (index == -1) return;
    final updatedRoom = rooms[index].copyWith(
      unreadCount: rooms[index].unreadCount + 1,
    );
    rooms[index] = updatedRoom;
  }

  void _markRoomRead(String roomId) {
    final index = rooms.indexWhere((room) => room.id == roomId);
    if (index == -1) return;
    final updatedRoom = rooms[index].copyWith(unreadCount: 0);
    rooms[index] = updatedRoom;
  }

  void reset() {
    rooms.clear();
    messagesByRoom.clear();
    activeRoomId.value = null;
    _webSocketService.disconnect();
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void onClose() {
    reset();
    super.onClose();
  }
}
