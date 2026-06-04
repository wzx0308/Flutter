import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'change_password_controller.dart';
import '../../app/theme/app_colors.dart';

class ChangePasswordPage extends GetView<ChangePasswordController> {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text('change_password_title'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('change_password_title'.tr, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text('change_password_hint'.tr, style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 32),
            _buildPasswordField('old_password'.tr, controller.oldPasswordCtrl, obscure: true),
            const SizedBox(height: 16),
            _buildPasswordField('new_password'.tr, controller.newPasswordCtrl, obscure: true),
            const SizedBox(height: 16),
            _buildPasswordField('confirm_new_password'.tr, controller.confirmPasswordCtrl, obscure: true),
            const SizedBox(height: 32),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value ? null : controller.changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('confirm_change'.tr, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController ctrl, {bool obscure = false}) {
    final isDark = Get.isDarkMode;
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF212121)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D2B55), width: 1.5),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
