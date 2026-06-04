import 'package:get/get.dart';
import '../../data/providers/admin_provider.dart';

class AdminDashboardController extends GetxController {
  final AdminProvider _provider = AdminProvider();

  final stats = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      final res = await _provider.getDashboard();
      if (res['code'] == 0) {
        stats.value = Map<String, dynamic>.from(res['data']);
      }
    } catch (_) {} finally {
      isLoading.value = false;
    }
  }
}
