import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'friends_list_controller.dart';
import '../../data/models/user_model.dart';
import '../../app/routes/app_routes.dart';
import '../../core/network/api_client.dart';

class FriendsListPage extends GetView<FriendsListController> {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text('friends_list'.tr)),
      body: Column(
        children: [
          _buildSearchBar(cardColor, textColor, subTextColor, accentColor),
          Expanded(child: _buildBody(cardColor, textColor, subTextColor, accentColor)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color cardColor, Color textColor, Color subTextColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: cardColor,
      child: TextField(
        onChanged: controller.onSearchChanged,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: '搜索用户名...'.tr,
          hintStyle: TextStyle(color: subTextColor, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: subTextColor, size: 20),
          suffixIcon: Obx(() {
            if (controller.searchKeyword.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(Icons.clear, color: subTextColor, size: 18),
              onPressed: () {
                controller.onSearchChanged('');
              },
            );
          }),
          filled: true,
          fillColor: Get.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Color cardColor, Color textColor, Color subTextColor, Color accentColor) {
    return Obx(() {
      // Show search results
      if (controller.isSearching.value) {
        if (controller.isLoading.value && controller.searchResults.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (controller.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('未找到相关用户'.tr, style: TextStyle(color: subTextColor, fontSize: 16)),
              ],
            ),
          );
        }
        return _buildUserList(controller.searchResults, cardColor, textColor, subTextColor, accentColor);
      }

      // Show friends list
      if (controller.isLoading.value && controller.users.isEmpty) {
        return Center(child: CircularProgressIndicator(color: accentColor));
      }
      if (controller.users.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('no_friends'.tr, style: TextStyle(color: subTextColor, fontSize: 16)),
            ],
          ),
        );
      }
      return _buildUserList(controller.users, cardColor, textColor, subTextColor, accentColor);
    });
  }

  Widget _buildUserList(List<UserModel> list, Color cardColor, Color textColor, Color subTextColor, Color accentColor) {
    return RefreshIndicator(
      onRefresh: controller.isSearching.value
          ? () => controller.searchUsers(controller.searchKeyword.value)
          : controller.loadFriends,
      color: accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: list.length + (controller.hasMore.value ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == list.length) {
            controller.loadMore();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildUserItem(list[i], cardColor, textColor, subTextColor, accentColor);
        },
      ),
    );
  }

  Widget _buildUserItem(UserModel user, Color cardColor, Color textColor, Color subTextColor, Color accentColor) {
    return GestureDetector(
      onTap: () => Get.toNamed('${AppRoutes.userDetail}/${user.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: accentColor.withOpacity(0.1),
              backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                  ? NetworkImage(user.avatar!)
                  : null,
              child: (user.avatar == null || user.avatar!.isEmpty)
                  ? Text(
                      user.displayName[0].toUpperCase(),
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
                  ),
                  if (user.username != null && user.username!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '@${user.username}',
                        style: TextStyle(color: subTextColor, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (user.bio != null && user.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        user.bio!,
                        style: TextStyle(color: subTextColor, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                try {
                  final api = ApiClient();
                  final res = await api.dio.post('/conversations', data: {
                    'type': 'PRIVATE',
                    'userIds': [user.id],
                  });
                  if (res.data['code'] == 0) {
                    final conv = res.data['data'];
                    Get.toNamed('${AppRoutes.chatDetail}/${conv['id']}', arguments: {'name': conv['name'] ?? user.displayName});
                  }
                } catch (e) {
                  Get.snackbar('Error', e.toString());
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.chat_bubble_outline, size: 16, color: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
