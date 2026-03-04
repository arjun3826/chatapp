import 'package:get/get.dart';

import '../models/user.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import 'chat_controller.dart';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final LocalStorageService _storage = Get.find<LocalStorageService>();

  final Rxn<AppUser> currentUser = Rxn<AppUser>();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString token = ''.obs;
  final RxBool isReady = false.obs;

  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final data = _storage.readAuth();
      if (data != null) {
        token.value = data['token']?.toString() ?? '';
        final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        currentUser.value = user;
        Get.find<ChatController>().initForUser(user);
      }
    } finally {
      isReady.value = true;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      final user = await _apiService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      currentUser.value = user;
      await _storage.saveAuth(token: token.value, user: user.toJson());
      Get.find<ChatController>().initForUser(user);
      Get.offAllNamed(Routes.home);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      final data =
          await _apiService.login(identifier: identifier, password: password);
      token.value = data['access_token']?.toString() ?? '';
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      currentUser.value = user;
      await _storage.saveAuth(token: token.value, user: user.toJson());
      Get.find<ChatController>().initForUser(user);
      Get.offAllNamed(Routes.home);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    currentUser.value = null;
    token.value = '';
    _storage.clearAuth();
    Get.find<ChatController>().reset();
    Get.offAllNamed(Routes.login);
  }

  void updateProfile({
    required String name,
    String? status,
    String? avatarUrl,
  }) {
    final user = currentUser.value;
    if (user == null) return;
    final updated = user.copyWith(
      name: name,
      status: status ?? user.status,
      avatarUrl: avatarUrl ?? user.avatarUrl,
    );
    currentUser.value = updated;
    _storage.saveAuth(token: token.value, user: updated.toJson());
  }
}
