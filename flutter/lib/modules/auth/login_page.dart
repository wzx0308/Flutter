import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/locale_service.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeService.to.isDark;
      final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
      final hintColor = isDark ? Colors.grey[500]! : Colors.grey[400]!;
      final fillColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8FA);
      final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
      final bottomColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
      final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2D2B55),
                const Color(0xFF3D3B70),
                bottomColor,
              ],
              stops: const [0.0, 0.35, 0.35],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildTopActions(isDark),
                  const SizedBox(height: 40),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.home_outlined, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'app_name'.tr,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: 10),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'app_slogan'.tr,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6), letterSpacing: 2),
                  ),
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('welcome_back'.tr, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor)),
                        const SizedBox(height: 6),
                        Text('login_subtitle'.tr, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                        const SizedBox(height: 28),
                        TextField(
                          onChanged: (v) => controller.account.value = v,
                          style: TextStyle(fontSize: 15, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'username'.tr,
                            hintStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(Icons.person_outline, color: accentColor),
                            filled: true,
                            fillColor: fillColor,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accentColor, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (v) => controller.password.value = v,
                          obscureText: true,
                          style: TextStyle(fontSize: 15, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'password'.tr,
                            hintStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(Icons.lock_outline, color: accentColor),
                            filled: true,
                            fillColor: fillColor,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accentColor, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value ? null : controller.login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('login'.tr, style: const TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: controller.goToRegister,
                          child: Text('no_account_hint'.tr, style: TextStyle(color: accentColor)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('app_slogan_long'.tr, style: TextStyle(fontSize: 12, color: Colors.grey[400], letterSpacing: 1)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopActions(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => _showLanguageSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language_rounded, size: 16, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Obx(() {
                  final locale = LocaleService.to.currentLocale.value;
                  final name = LocaleService.localeNames['${locale.languageCode}_${locale.countryCode}'] ?? locale.languageCode;
                  return Text(name, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)));
                }),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => ThemeService.to.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageSheet() {
    final isDark = Get.isDarkMode;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('select_language'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF212121))),
            const SizedBox(height: 6),
            Text('select_language_hint'.tr, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 20),
            ...LocaleService.supportedLocales.map((locale) {
              final key = '${locale.languageCode}_${locale.countryCode}';
              final name = LocaleService.localeNames[key] ?? locale.languageCode;
              return Obx(() {
                final selected = LocaleService.to.currentLocale.value == locale;
                return InkWell(
                  onTap: () {
                    LocaleService.to.setLocale(locale);
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2D2B55).withOpacity(0.08)
                          : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? const Color(0xFF2D2B55) : Colors.grey[200]!,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(name, style: TextStyle(
                          fontSize: 16,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected ? const Color(0xFF2D2B55) : (isDark ? Colors.white70 : const Color(0xFF212121)),
                        )),
                        const Spacer(),
                        if (selected) const Icon(Icons.check_rounded, color: Color(0xFF2D2B55), size: 20),
                      ],
                    ),
                  ),
                );
              });
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
