import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../chat/home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Obx(
      () {
        if (!authController.isReady.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return authController.isLoggedIn
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
