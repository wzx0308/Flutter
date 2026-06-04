import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../app/routes/app_routes.dart';

class RegisterController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final username = ''.obs;
  final email = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final isLoading = false.obs;

  Future<void> register() async {
    if (username.value.isEmpty) {
      Get.snackbar('错误', '请输入用户名');
      return;
    }
    if (password.value.isEmpty) {
      Get.snackbar('错误', '请输入密码');
      return;
    }
    if (password.value != confirmPassword.value) {
      Get.snackbar('错误', '两次密码不一致');
      return;
    }

    isLoading.value = true;
    try {
      await _authRepo.register(
        username: username.value,
        email: email.value.isNotEmpty ? email.value : null,
        password: password.value,
        nickname: username.value,
      );
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar('注册失败', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  void goToLogin() {
    Get.back();
  }
}
