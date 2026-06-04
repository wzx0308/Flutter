import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/network/api_client.dart';

class ChangePasswordController extends GetxController {
  final oldPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final isSaving = false.obs;

  @override
  void onClose() {
    oldPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }

  Future<void> changePassword() async {
    final oldPwd = oldPasswordCtrl.text.trim();
    final newPwd = newPasswordCtrl.text.trim();
    final confirmPwd = confirmPasswordCtrl.text.trim();

    if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      Get.snackbar('提示', '请填写所有字段');
      return;
    }
    if (newPwd.length < 6) {
      Get.snackbar('提示', '新密码至少6位');
      return;
    }
    if (newPwd != confirmPwd) {
      Get.snackbar('提示', '两次密码不一致');
      return;
    }

    isSaving.value = true;
    try {
      final api = ApiClient();
      await api.dio.patch('/auth/change-password', data: {
        'oldPassword': oldPwd,
        'newPassword': newPwd,
      });
      Get.back();
      Get.snackbar('成功', '密码已修改');
    } catch (e) {
      Get.snackbar('失败', e.toString());
    } finally {
      isSaving.value = false;
    }
  }
}
