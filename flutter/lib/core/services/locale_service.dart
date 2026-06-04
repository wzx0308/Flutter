import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocaleService extends GetxService {
  static LocaleService get to => Get.find();
  final _box = GetStorage();
  final _key = 'locale';

  final currentLocale = const Locale('zh', 'CN').obs;

  LocaleService init() {
    final saved = _box.read<String>(_key);
    if (saved != null) {
      final parts = saved.split('_');
      if (parts.length == 2) {
        currentLocale.value = Locale(parts[0], parts[1]);
      }
    }
    Get.updateLocale(currentLocale.value);
    return this;
  }

  Future<void> setLocale(Locale locale) async {
    currentLocale.value = locale;
    Get.updateLocale(locale);
    await _box.write(_key, '${locale.languageCode}_${locale.countryCode}');
  }

  static const supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
  ];

  static const localeNames = {
    'zh_CN': '中文',
    'en_US': 'English',
    'ja_JP': '日本語',
  };
}
