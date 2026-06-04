import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'set_password_controller.dart';
import 'widgets/payment_password_dialog.dart';

class SetPasswordPage extends GetView<SetPasswordController> {
  const SetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(controller.hasPassword.value ? '修改支付密码' : '设置支付密码'),
        backgroundColor: const Color(0xFF2D2B55),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        final step = controller.step.value;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 步骤指示器
              if (controller.hasPassword.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stepIndicator(1, step >= 1, '验证旧密码', accentColor),
                      _stepLine(step >= 2, accentColor),
                      _stepIndicator(2, step >= 2, '设置新密码', accentColor),
                      _stepLine(step >= 3, accentColor),
                      _stepIndicator(3, step >= 3, '确认密码', accentColor),
                    ],
                  ),
                ),
              Icon(Icons.lock_outline, size: 48, color: accentColor),
              const SizedBox(height: 20),
              Text(controller.title, style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : const Color(0xFF212121))),
              const SizedBox(height: 8),
              Text(controller.hintText, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 32),
              PinInputWidget(
                key: ValueKey('pin_step_$step'),
                onSubmit: (pin) => controller.onPasswordComplete(pin),
              ),
              if (controller.isLoading.value) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _stepIndicator(int num, bool active, String label, Color accentColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? accentColor : Colors.grey[300],
          ),
          child: Center(
            child: Text('$num', style: TextStyle(color: active ? Colors.white : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: active ? accentColor : Colors.grey[500])),
      ],
    );
  }

  Widget _stepLine(bool active, Color accentColor) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: active ? accentColor : Colors.grey[300],
    );
  }
}
