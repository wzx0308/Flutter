import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../app/routes/app_routes.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final account = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;

  Future<void> login() async {
    if (account.value.isEmpty || password.value.isEmpty) {
      Get.snackbar('错误', '请输入账号和密码');
      return;
    }

    isLoading.value = true;
    try {
      await _authRepo.login(
        account: account.value,
        password: password.value,
      );
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar('登录失败', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  void goToRegister() {
    Get.toNamed(AppRoutes.register);
  }
}
