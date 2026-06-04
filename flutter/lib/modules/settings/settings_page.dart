import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'settings_controller.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/locale_service.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('settings'.tr),
        backgroundColor: const Color(0xFF2D2B55),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            _buildSection('account_security'.tr, cardColor, [
              _buildMenuItem(Icons.lock_outline, 'password_change'.tr, const Color(0xFF607D8B), textColor, () => Get.toNamed('/settings/change-password')),
              _buildMenuItem(Icons.pin_outlined, 'payment_password'.tr, const Color(0xFFFF9800), textColor, () => Get.toNamed('/wallet/set-password')),
              _buildMenuItem(Icons.security_outlined, 'account_security'.tr, const Color(0xFF2196F3), textColor, () {}),
              _buildMenuItem(Icons.phonelink_lock_outlined, 'device_management'.tr, const Color(0xFF9C27B0), textColor, () {}),
            ]),

            _buildSection('general'.tr, cardColor, [
              _buildMenuItem(Icons.notifications_outlined, 'notification_settings'.tr, const Color(0xFFFF9800), textColor, () {}),
              _buildLanguageItem(cardColor, textColor),
              _buildThemeItem(cardColor, textColor),
            ]),

            _buildSection('storage'.tr, cardColor, [
              _buildMenuItem(Icons.cloud_upload_outlined, 'system_update'.tr, const Color(0xFF2196F3), textColor, () => _checkUpdate()),
              _buildMenuItem(Icons.delete_outline, 'clear_cache'.tr, const Color(0xFFE91E63), textColor, () => _clearCache()),
            ]),

            _buildSection('about_section'.tr, cardColor, [
              _buildMenuItem(Icons.info_outline, 'about_us'.tr, const Color(0xFF2D2B55), textColor, () => _showAbout(context)),
              _buildMenuItem(Icons.description_outlined, 'user_agreement'.tr, const Color(0xFF607D8B), textColor, () {}),
              _buildMenuItem(Icons.privacy_tip_outlined, 'privacy_policy'.tr, const Color(0xFF607D8B), textColor, () {}),
              _buildMenuItem(Icons.star_outline, 'give_rating'.tr, const Color(0xFFFF9800), textColor, () {}),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Color cardColor, List<Widget> children) {
    final isDark = Get.isDarkMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[500])),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color iconColor, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, color: textColor)),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeItem(Color cardColor, Color textColor) {
    return Obx(() {
      final isDark = ThemeService.to.isDark;
      return InkWell(
        onTap: () => ThemeService.to.toggleTheme(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF607D8B)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? const Color(0xFF7C4DFF) : const Color(0xFF607D8B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(isDark ? 'light_mode'.tr : 'dark_mode'.tr, style: TextStyle(fontSize: 15, color: textColor)),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isDark,
                  onChanged: (_) => ThemeService.to.toggleTheme(),
                  activeThumbColor: const Color(0xFF2D2B55),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLanguageItem(Color cardColor, Color textColor) {
    return InkWell(
      onTap: () => _showLanguageSheet(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.language_rounded, color: Color(0xFF4CAF50), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('language_settings'.tr, style: TextStyle(fontSize: 15, color: textColor)),
            ),
            Obx(() {
              final locale = LocaleService.to.currentLocale.value;
              final name = LocaleService.localeNames['${locale.languageCode}_${locale.countryCode}'] ?? locale.languageCode;
              return Text(name, style: TextStyle(color: Colors.grey[400], fontSize: 14));
            }),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
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

  void _checkUpdate() {
    Get.snackbar('check_update'.tr, 'latest_version'.tr);
  }

  void _clearCache() {
    Get.defaultDialog(
      title: 'clear_cache'.tr,
      middleText: 'clear_cache_confirm'.tr,
      textConfirm: 'confirm'.tr,
      textCancel: 'cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF2D2B55),
      onConfirm: () {
        Get.back();
        Get.snackbar('success'.tr, 'cache_cleared'.tr);
      },
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'app_name'.tr,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D2B55), Color(0xFF4A4580)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.home_outlined, size: 28, color: Colors.white),
      ),
      children: [
        Text('app_description'.tr, style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.6)),
        const SizedBox(height: 8),
        Text('app_tech'.tr, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }
}
