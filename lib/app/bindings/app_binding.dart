import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ApiService(), permanent: true);
    Get.put(WebSocketService(), permanent: true);
    Get.put(ChatController(), permanent: true);
    Get.put(AuthController(), permanent: true);
  }
}
