import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final RxBool isDark = false.obs;

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    isDark.value = !isDark.value;
    Get.changeThemeMode(themeMode);
  }
}
