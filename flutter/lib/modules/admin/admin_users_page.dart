import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/admin_provider.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _provider = AdminProvider();
  final _users = <dynamic>[].obs;
  final _isLoading = false.obs;
  final _total = 0.obs;
  int _page = 1;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({int page = 1, String? keyword}) async {
    _isLoading.value = true;
    try {
      final res = await _provider.getUsers(page: page, keyword: keyword);
      if (res['code'] == 0) {
        _users.value = res['data']['users'] ?? [];
        _total.value = res['data']['total'] ?? 0;
        _page = page;
      }
    } catch (_) {} finally {
      _isLoading.value = false;
    }
  }

  Future<void> _updateStatus(String userId, String status) async {
    try {
      await _provider.updateUserStatus(userId, status);
      Get.snackbar('success'.tr, 'user_status_updated'.tr);
      _loadUsers(page: _page, keyword: _searchCtrl.text.trim());
    } catch (e) {
      Get.snackbar('failed'.tr, e.toString());
    }
  }

  Future<void> _updateRole(String userId, String role) async {
    try {
      await _provider.updateUserRole(userId, role);
      Get.snackbar('success'.tr, 'user_role_updated'.tr);
      _loadUsers(page: _page, keyword: _searchCtrl.text.trim());
    } catch (e) {
      Get.snackbar('failed'.tr, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text('user_management'.tr)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'search_hint'.tr,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                    ),
                    onSubmitted: (v) => _loadUsers(keyword: v.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _loadUsers(keyword: _searchCtrl.text.trim()),
                  child: Text('search'.tr),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_isLoading.value) return const Center(child: CircularProgressIndicator());
              if (_users.isEmpty) return Center(child: Text('no_data'.tr));
              return ListView.separated(
                itemCount: _users.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                itemBuilder: (_, i) {
                  final user = _users[i];
                  return Material(
                    color: cardColor,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text((user['nickname'] ?? user['username'] ?? 'U')[0].toUpperCase()),
                      ),
                      title: Text(user['nickname'] ?? user['username'] ?? '', style: TextStyle(color: textColor)),
                      subtitle: Text('${user['email'] ?? ''} | ${user['role']} | ${user['status']}', style: TextStyle(color: Colors.grey[400])),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${'posts_count_label'.tr}:${user['postCount'] ?? 0} ${'fans_count_label'.tr}:${user['followerCount'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'ban') _updateStatus(user['id'], 'BANNED');
                              if (v == 'unban') _updateStatus(user['id'], 'NORMAL');
                              if (v == 'admin') _updateRole(user['id'], 'ADMIN');
                            },
                            itemBuilder: (_) => [
                              if (user['status'] != 'BANNED') PopupMenuItem(value: 'ban', child: Text('ban_user'.tr)),
                              if (user['status'] == 'BANNED') PopupMenuItem(value: 'unban', child: Text('unban_user'.tr)),
                              if (user['role'] != 'ADMIN') PopupMenuItem(value: 'admin', child: Text('set_admin'.tr)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() => Padding(
                padding: const EdgeInsets.all(8),
                child: Text('total_users_count'.trParams({'count': '${_total.value}'}), style: TextStyle(color: Colors.grey[400])),
              )),
        ],
      ),
    );
  }
}
