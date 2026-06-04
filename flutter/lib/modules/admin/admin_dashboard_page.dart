import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_dashboard_controller.dart';
import 'admin_users_page.dart';
import 'admin_posts_page.dart';
import 'admin_reports_page.dart';

class AdminDashboardPage extends GetView<AdminDashboardController> {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('admin_title'.tr),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: controller.loadDashboard),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Get.back()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.stats.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = controller.stats.value;
        if (s == null) return Center(child: Text('no_data'.tr));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('data_overview'.tr, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 20),
              _buildStatCards(s, cardColor, textColor),
              const SizedBox(height: 32),
              Text('quick_actions'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 16),
              _buildQuickActions(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCards(Map<String, dynamic> stats, Color cardColor, Color textColor) {
    final cards = [
      _StatData('total_users'.tr, '${stats['totalUsers'] ?? 0}', Icons.people, Colors.blue),
      _StatData('new_users_today'.tr, '${stats['newUsersToday'] ?? 0}', Icons.person_add, Colors.green),
      _StatData('total_posts'.tr, '${stats['totalPosts'] ?? 0}', Icons.article, Colors.orange),
      _StatData('new_posts_today'.tr, '${stats['newPostsToday'] ?? 0}', Icons.post_add, Colors.purple),
      _StatData('total_comments'.tr, '${stats['totalComments'] ?? 0}', Icons.comment, Colors.teal),
      _StatData('pending_reports'.tr, '${stats['pendingReports'] ?? 0}', Icons.flag, Colors.red),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _buildStatCard(cards[i], cardColor),
    );
  }

  Widget _buildStatCard(_StatData data, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(data.icon, color: data.color, size: 28),
              const Spacer(),
              Text(data.value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: data.color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(data.label, style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionCard('user_management'.tr, Icons.people, Colors.blue, () => Get.to(() => const AdminUsersPage())),
        const SizedBox(width: 16),
        _actionCard('content_management'.tr, Icons.article, Colors.orange, () => Get.to(() => const AdminPostsPage())),
        const SizedBox(width: 16),
        _actionCard('report_management'.tr, Icons.flag, Colors.red, () => Get.to(() => const AdminReportsPage())),
      ],
    );
  }

  Widget _actionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}
