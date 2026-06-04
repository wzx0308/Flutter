import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/transfer_provider.dart';

class SetPasswordController extends GetxController {
  final TransferProvider _provider = TransferProvider();

  final step = 1.obs; // 1=输入旧密码(已有密码时), 2=输入新密码, 3=确认新密码
  final oldPassword = ''.obs;
  final newPassword = ''.obs;
  final confirmPassword = ''.obs;
  final isLoading = false.obs;
  final hasPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final res = await _provider.getPaymentPasswordStatus();
      if (res['code'] == 0) {
        hasPassword.value = res['data']['hasPassword'] ?? false;
        // 已有密码时，第一步是验证旧密码
        step.value = hasPassword.value ? 1 : 2;
      }
    } catch (_) {}
  }

  String get title {
    switch (step.value) {
      case 1:
        return '请输入当前支付密码';
      case 2:
        return '请输入6位新支付密码';
      case 3:
        return '请再次输入新密码确认';
      default:
        return '';
    }
  }

  String get hintText {
    switch (step.value) {
      case 1:
        return '验证旧密码后才能修改';
      case 2:
        return '设置6位数字密码';
      case 3:
        return '再次输入确认';
      default:
        return '';
    }
  }

  void onPasswordComplete(String pin) async {
    switch (step.value) {
      case 1: // 旧密码验证
        await _verifyOldPassword(pin);
        break;
      case 2: // 输入新密码
        newPassword.value = pin;
        step.value = 3;
        break;
      case 3: // 确认新密码
        confirmPassword.value = pin;
        _submit();
        break;
    }
  }

  Future<void> _verifyOldPassword(String pin) async {
    isLoading.value = true;
    try {
      final res = await _provider.verifyPaymentPassword(pin);
      if (res['code'] == 0) {
        oldPassword.value = pin;
        step.value = 2;
      } else {
        Get.snackbar('错误', '支付密码不正确，请重新输入');
      }
    } catch (e) {
      Get.snackbar('错误', '支付密码不正确，请重新输入');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _submit() async {
    if (newPassword.value != confirmPassword.value) {
      Get.snackbar('提示', '两次输入的新密码不一致，请重新设置');
      step.value = 2;
      newPassword.value = '';
      confirmPassword.value = '';
      return;
    }

    isLoading.value = true;
    try {
      final res = await _provider.setPaymentPassword(
        oldPassword: hasPassword.value ? oldPassword.value : null,
        newPassword: newPassword.value,
      );
      if (res['code'] == 0) {
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                const SizedBox(width: 8),
                const Text('设置成功'),
              ],
            ),
            content: Text(hasPassword.value ? '支付密码已修改' : '支付密码设置成功'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // 关闭弹窗
                  Get.back(); // 返回上一页（设置页）
                },
                child: const Text('返回设置'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar('失败', res['message'] ?? '设置失败');
      }
    } catch (e) {
      Get.snackbar('失败', '网络错误');
    } finally {
      isLoading.value = false;
      step.value = hasPassword.value ? 1 : 2;
      oldPassword.value = '';
      newPassword.value = '';
      confirmPassword.value = '';
    }
  }
}
