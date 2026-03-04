import 'package:get/get.dart';

import '../screens/auth/auth_gate.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/chat/chat_room_screen.dart';
import '../screens/chat/home_screen.dart';
import '../screens/chat/select_contact_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: Routes.authGate,
      page: () => const AuthGate(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: Routes.chatRoom,
      page: () => const ChatRoomScreen(),
    ),
    GetPage(
      name: Routes.selectContact,
      page: () => const SelectContactScreen(),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsScreen(),
    ),
  ];
}
