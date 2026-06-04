import 'package:get/get.dart';
import '../../core/storage/storage_service.dart';
import '../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      final storage = StorageService.to;
      if (storage.isLoggedIn) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      print('⚠️ SplashController._checkAuth error: $e');
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
