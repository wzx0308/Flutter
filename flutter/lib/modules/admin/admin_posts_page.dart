import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/admin_provider.dart';

class AdminPostsPage extends StatefulWidget {
  const AdminPostsPage({super.key});

  @override
  State<AdminPostsPage> createState() => _AdminPostsPageState();
}

class _AdminPostsPageState extends State<AdminPostsPage> {
  final _provider = AdminProvider();
  final _posts = <dynamic>[].obs;
  final _isLoading = false.obs;
  int _page = 1;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts({int page = 1, String? status}) async {
    _isLoading.value = true;
    _statusFilter = status;
    try {
      final res = await _provider.getPosts(page: page, status: status);
      if (res['code'] == 0) {
        _posts.value = res['data']['posts'] ?? [];
        _page = page;
      }
    } catch (_) {} finally {
      _isLoading.value = false;
    }
  }

  Future<void> _updateStatus(String postId, String status) async {
    try {
      await _provider.updatePostStatus(postId, status);
      Get.snackbar('success'.tr, 'post_status_updated'.tr);
      _loadPosts(page: _page, status: _statusFilter);
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
      appBar: AppBar(title: Text('content_management'.tr)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _filterChip('all'.tr, null, isDark),
                const SizedBox(width: 8),
                _filterChip('published'.tr, 'PUBLISHED', isDark),
                const SizedBox(width: 8),
                _filterChip('reviewing'.tr, 'REVIEWING', isDark),
                const SizedBox(width: 8),
                _filterChip('hidden'.tr, 'HIDDEN', isDark),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_isLoading.value) return const Center(child: CircularProgressIndicator());
              if (_posts.isEmpty) return Center(child: Text('no_data'.tr));
              return ListView.separated(
                itemCount: _posts.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                itemBuilder: (_, i) {
                  final post = _posts[i];
                  final author = post['author'];
                  return Material(
                    color: cardColor,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(author?['nickname']?[0]?.toUpperCase() ?? 'U'),
                      ),
                      title: Text(post['title'] ?? post['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor)),
                      subtitle: Text('${author?['nickname'] ?? ''} | ${post['status']} | ${'likes_count'.tr}:${post['likeCount'] ?? 0} ${'comments_count'.tr}:${post['commentCount'] ?? 0}', style: TextStyle(color: Colors.grey[400])),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) => _updateStatus(post['id'], v),
                        itemBuilder: (_) => [
                          if (post['status'] != 'PUBLISHED') PopupMenuItem(value: 'PUBLISHED', child: Text('approve_post'.tr)),
                          if (post['status'] != 'HIDDEN') PopupMenuItem(value: 'HIDDEN', child: Text('hide_post'.tr)),
                          if (post['status'] != 'DELETED') PopupMenuItem(value: 'DELETED', child: Text('delete_post'.tr)),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? status, bool isDark) {
    final selected = _statusFilter == status;
    return GestureDetector(
      onTap: () => _loadPosts(status: status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.orange : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey[400], fontSize: 13)),
      ),
    );
  }
}
