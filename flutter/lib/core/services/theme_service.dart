import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService extends GetxService {
  static ThemeService get to => Get.find();
  final _box = GetStorage();
  final _key = 'theme_mode';

  final themeMode = ThemeMode.system.obs;

  ThemeService init() {
    final saved = _box.read<String>(_key);
    if (saved == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (saved == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.system;
    }
    return this;
  }

  bool get isDark => themeMode.value == ThemeMode.dark;

  Future<void> toggleTheme() async {
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
      await _box.write(_key, 'dark');
    } else {
      themeMode.value = ThemeMode.light;
      await _box.write(_key, 'light');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _box.write(_key, mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system');
  }
}
