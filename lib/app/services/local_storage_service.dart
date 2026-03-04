import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveAuth({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_userKey, jsonEncode(user));
  }

  Map<String, dynamic>? readAuth() {
    final token = _prefs?.getString(_tokenKey);
    final userRaw = _prefs?.getString(_userKey);
    if (token == null || userRaw == null) return null;
    final user = jsonDecode(userRaw) as Map<String, dynamic>;
    return {
      'token': token,
      'user': user,
    };
  }

  Future<void> clearAuth() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userKey);
  }
}
