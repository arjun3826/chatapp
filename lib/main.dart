import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/app_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/services/local_storage_service.dart';
import 'app/services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = LocalStorageService();
  await storage.init();
  Get.put(storage, permanent: true);
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController(), permanent: true);
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ChatApp',
        initialBinding: AppBinding(),
        initialRoute: Routes.authGate,
        getPages: AppPages.pages,
        themeMode: themeController.themeMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF25D366),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF075E54),
            foregroundColor: Colors.white,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF25D366),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0B141A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF202C33),
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
