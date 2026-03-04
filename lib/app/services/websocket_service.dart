import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/message.dart';

enum SocketStatus { disconnected, connecting, connected }

class WebSocketService extends GetxService {
  final Rx<SocketStatus> status = SocketStatus.disconnected.obs;
  final StreamController<ChatMessage> _messageController =
      StreamController.broadcast();

  WebSocketChannel? _channel;

  Stream<ChatMessage> get messagesStream => _messageController.stream;

  Future<void> connect({
    required String baseUrl,
    required String roomId,
    required String userId,
  }) async {
    disconnect();
    status.value = SocketStatus.connecting;
    final wsUrl = baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsUrl/ws/$roomId/$userId');
    _channel = WebSocketChannel.connect(uri);
    status.value = SocketStatus.connected;
    _channel?.stream.listen(
      (event) {
        try {
          final data = jsonDecode(event.toString()) as Map<String, dynamic>;
          _messageController.add(ChatMessage.fromJson(data));
        } catch (_) {}
      },
      onDone: () {
        status.value = SocketStatus.disconnected;
      },
      onError: (_) {
        status.value = SocketStatus.disconnected;
      },
    );
  }

  void send(String content) {
    _channel?.sink.add(content);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    status.value = SocketStatus.disconnected;
  }

  @override
  void onClose() {
    disconnect();
    _messageController.close();
    super.onClose();
  }
}
