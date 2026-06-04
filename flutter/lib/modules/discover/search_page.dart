import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/services/post_service.dart';
import '../../app/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../feed/widgets/post_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repo = SearchRepository();
  final _ctrl = TextEditingController();
  final _results = <dynamic>[].obs;
  final _isLoading = false.obs;
  final _searchType = 'all'.obs;
  final _history = <String>[].obs;
  String _query = '';
  bool _isTagSearch = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    final args = Get.arguments?['query'];
    if (args != null) {
      _ctrl.text = args; // 保留 # 前缀，用于标识标签搜索
      _search();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _loadHistory() {
    _history.value = StorageService.to.getSearchHistory();
  }

  Future<void> _search() async {
    _query = _ctrl.text.trim();
    if (_query.isEmpty) return;

    // 检测是否为标签搜索（以 # 开头）
    _isTagSearch = _query.startsWith('#');
    final searchQuery = _isTagSearch ? _query.substring(1) : _query;

    StorageService.to.addSearchHistory(_query);
    _loadHistory();

    _isLoading.value = true;
    try {
      if (_isTagSearch) {
        // 标签搜索：使用标签专用接口
        final posts = await _repo.getTagPosts(searchQuery);
        _results.clear();
        _results.addAll(posts);
      } else {
        // 通用搜索
        final result = await _repo.search(_query, type: _searchType.value == 'all' ? null : _searchType.value);
        _results.clear();
        if (result['users'] != null) _results.addAll(result['users']);
        if (result['posts'] != null) _results.addAll(result['posts']);
      }
    } catch (_) {} finally {
      _isLoading.value = false;
    }
  }

  void _selectHistory(String query) {
    _ctrl.text = query;
    _search();
  }

  Future<void> _removeHistory(String query) async {
    await StorageService.to.removeSearchHistory(query);
    _loadHistory();
  }

  Future<void> _clearHistory() async {
    await StorageService.to.clearSearchHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final hintColor = isDark ? Colors.grey[500]! : Colors.grey[400]!;
    final fillColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]!;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'search_placeholder'.tr,
            hintStyle: TextStyle(color: hintColor),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: textColor, size: 20),
              onPressed: () {
                _ctrl.clear();
                setState(() {});
              },
            ),
          TextButton(onPressed: _search, child: Text('search'.tr, style: TextStyle(color: accentColor))),
        ],
      ),
      body: Column(
        children: [
          if (!_isTagSearch) _buildTypeFilter(isDark, fillColor, accentColor),
          Expanded(child: Obx(() {
            if (_results.isNotEmpty || _query.isNotEmpty) {
              return _buildResults(isDark, textColor, accentColor);
            }
            return _buildHistory(isDark, textColor, accentColor, cardColor);
          })),
        ],
      ),
    );
  }

  // ═══════════════ Search History ═══════════════

  Widget _buildHistory(bool isDark, Color textColor, Color accentColor, Color cardColor) {
    return Obx(() {
      if (_history.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('暂无搜索记录', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('搜索历史', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                GestureDetector(
                  onTap: () {
                    Get.defaultDialog(
                      title: '提示',
                      middleText: '确定清空所有搜索历史？',
                      textConfirm: '清空',
                      textCancel: '取消',
                      confirmTextColor: Colors.white,
                      onConfirm: () {
                        _clearHistory();
                        Get.back();
                      },
                    );
                  },
                  child: Text('清空', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (_, i) {
                final query = _history[i];
                return Material(
                  color: cardColor,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.history, size: 20, color: Colors.grey[400]),
                    title: Text(query, style: TextStyle(fontSize: 14, color: textColor)),
                    trailing: IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                      onPressed: () => _removeHistory(query),
                    ),
                    onTap: () => _selectHistory(query),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  // ═══════════════ Type Filter ═══════════════

  Widget _buildTypeFilter(bool isDark, Color fillColor, Color accentColor) {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _filterChip('all'.tr, 'all', isDark, fillColor, accentColor),
              const SizedBox(width: 8),
              _filterChip('users'.tr, 'user', isDark, fillColor, accentColor),
              const SizedBox(width: 8),
              _filterChip('posts_label'.tr, 'post', isDark, fillColor, accentColor),
            ],
          ),
        ));
  }

  Widget _filterChip(String label, String type, bool isDark, Color fillColor, Color accentColor) {
    final selected = _searchType.value == type;
    return GestureDetector(
      onTap: () {
        _searchType.value = type;
        if (_query.isNotEmpty) _search();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accentColor : fillColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]), fontSize: 13)),
      ),
    );
  }

  // ═══════════════ Results ═══════════════

  Widget _buildResults(bool isDark, Color textColor, Color accentColor) {
    return Obx(() {
      if (_isLoading.value) return Center(child: CircularProgressIndicator(color: accentColor));
      if (_results.isEmpty && _query.isNotEmpty) {
        return Center(child: Text('search_result_empty'.tr, style: TextStyle(color: Colors.grey)));
      }
      return ListView.builder(
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final item = _results[i];
          if (item is UserModel) return _buildUserItem(item, isDark, textColor, accentColor);
          if (item is PostModel) return _buildPostItem(item, isDark, textColor);
          return const SizedBox.shrink();
        },
      );
    });
  }

  Widget _buildUserItem(UserModel user, bool isDark, Color textColor, Color accentColor) {
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor.withValues(alpha: 0.1),
          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
          child: user.avatar == null
              ? Text((user.nickname ?? user.username ?? 'U')[0].toUpperCase(), style: TextStyle(color: accentColor))
              : null,
        ),
        title: Text(user.displayName, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: user.bio != null ? Text(user.bio!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400])) : null,
        onTap: () => Get.toNamed('${AppRoutes.userDetail}/${user.id}'),
      ),
    );
  }

  Widget _buildPostItem(PostModel post, bool isDark, Color textColor) {
    return PostCard(
      post: post,
      onTap: () => Get.toNamed('${AppRoutes.postDetail}/${post.id}'),
      onLike: () {
        try {
          Get.find<PostService>().toggleLike(post);
        } catch (_) {}
      },
      onBookmark: () {
        try {
          Get.find<PostService>().toggleBookmark(post);
        } catch (_) {}
      },
    );
  }
}
