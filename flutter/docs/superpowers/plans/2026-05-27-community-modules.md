# 社区模块实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 为"安隅"社交应用添加社区模块——首页展示官方频道网格、频道详情页、用户主页、关注/聊天功能

**架构：** Tag-based 频道系统，前端硬编码 8 个官方频道映射到现有标签，复用后端 `/posts?tag=` 端点。用户主页通过关注系统支持互相关注检测和聊天触发。

**技术栈：** Flutter + GetX（状态管理/路由/DI）、Dio（HTTP）、现有后端 API（无需后端修改）

---

## 文件变更清单

### 新建文件（8 个）

| 文件 | 职责 |
|------|------|
| `lib/data/models/channel_model.dart` | 频道静态数据模型（8 个官方频道定义） |
| `lib/modules/channel/channel_page.dart` | 频道详情页（帖子列表） |
| `lib/modules/channel/channel_controller.dart` | 频道页控制器（分页加载帖子） |
| `lib/modules/profile/user_detail_page.dart` | 用户主页（用户信息 + 动态列表） |
| `lib/modules/profile/user_detail_controller.dart` | 用户主页控制器（关注状态、动态加载） |
| `lib/modules/home/widgets/channel_grid.dart` | 首页频道网格组件 |
| `lib/modules/home/widgets/channel_card.dart` | 单个频道卡片组件 |

### 修改文件（7 个）

| 文件 | 修改内容 |
|------|----------|
| `lib/modules/home/home_page.dart` | Tab 0 从 FeedPage 改为 ChannelGrid |
| `lib/modules/post/post_detail_page.dart` | 作者头像/昵称可点击跳转用户主页 |
| `lib/modules/feed/feed_page.dart` | 评论区用户头像可点击跳转 |
| `lib/app/routes/app_routes.dart` | 添加 channel 路由 |
| `lib/app/routes/app_pages.dart` | 添加 channel 和 userDetail 路由映射 |
| `lib/core/locales/zh_cn.dart` | 添加社区模块 i18n 键值 |
| `lib/core/locales/en_us.dart` | 添加社区模块 i18n 键值 |
| `lib/core/locales/ja_jp.dart` | 添加社区模块 i18n 键值 |

---

## 任务 1：创建 ChannelModel

**文件：**
- 创建：`lib/data/models/channel_model.dart`

- [ ] **步骤 1：创建 ChannelModel 类**

```dart
// lib/data/models/channel_model.dart
import 'package:flutter/material.dart';

class ChannelModel {
  final String tag;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const ChannelModel({
    required this.tag,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<ChannelModel> officialChannels = [
    ChannelModel(
      tag: '生活',
      name: '生活',
      description: '分享日常点滴',
      icon: Icons.home,
      color: Color(0xFF4CAF50),
    ),
    ChannelModel(
      tag: '技术',
      name: '技术',
      description: '技术交流讨论',
      icon: Icons.code,
      color: Color(0xFF2196F3),
    ),
    ChannelModel(
      tag: '音乐',
      name: '音乐',
      description: '音乐分享推荐',
      icon: Icons.music_note,
      color: Color(0xFF9C27B0),
    ),
    ChannelModel(
      tag: '摄影',
      name: '摄影',
      description: '摄影作品展示',
      icon: Icons.camera_alt,
      color: Color(0xFFFF9800),
    ),
    ChannelModel(
      tag: '旅行',
      name: '旅行',
      description: '旅行见闻分享',
      icon: Icons.flight,
      color: Color(0xFF00BCD4),
    ),
    ChannelModel(
      tag: '美食',
      name: '美食',
      description: '美食制作与推荐',
      icon: Icons.restaurant,
      color: Color(0xFFE91E63),
    ),
    ChannelModel(
      tag: '运动',
      name: '运动',
      description: '运动健身打卡',
      icon: Icons.fitness_center,
      color: Color(0xFFFF5722),
    ),
    ChannelModel(
      tag: '阅读',
      name: '阅读',
      description: '读书笔记分享',
      icon: Icons.book,
      color: Color(0xFF795548),
    ),
  ];
}
```

- [ ] **步骤 2：Commit**

```bash
git add lib/data/models/channel_model.dart
git commit -m "feat: add ChannelModel with 8 official channels"
```

---

## 任务 2：添加 i18n 键值

**文件：**
- 修改：`lib/core/locales/zh_cn.dart`
- 修改：`lib/core/locales/en_us.dart`
- 修改：`lib/core/locales/ja_jp.dart`

- [ ] **步骤 1：添加中文键值**

在 `zh_cn.dart` 的 Map 中追加以下键值（在最后一个逗号后添加）：

```dart
    // ── 社区模块 ──
    'community': '社区',
    'channel': '频道',
    'channel_posts': '频道动态',
    'fans_count': '粉丝',
    'following_count': '关注',
    'posts_count': '帖子',
    'follow': '关注',
    'unfollow': '取消关注',
    'mutual_follow': '互相关注',
    'send_message': '发消息',
    'user_posts': '动态',
    'no_posts_in_channel': '该频道暂无内容',
    'go_to_user_profile': '查看主页',
```

- [ ] **步骤 2：添加英文键值**

在 `en_us.dart` 的 Map 中追加：

```dart
    // ── Community Module ──
    'community': 'Community',
    'channel': 'Channel',
    'channel_posts': 'Channel Posts',
    'fans_count': 'Fans',
    'following_count': 'Following',
    'posts_count': 'Posts',
    'follow': 'Follow',
    'unfollow': 'Unfollow',
    'mutual_follow': 'Mutual',
    'send_message': 'Message',
    'user_posts': 'Posts',
    'no_posts_in_channel': 'No posts in this channel',
    'go_to_user_profile': 'View Profile',
```

- [ ] **步骤 3：添加日文键值**

在 `ja_jp.dart` 的 Map 中追加：

```dart
    // ── コミュニティモジュール ──
    'community': 'コミュニティ',
    'channel': 'チャンネル',
    'channel_posts': 'チャンネル投稿',
    'fans_count': 'フォロワー',
    'following_count': 'フォロー中',
    'posts_count': '投稿',
    'follow': 'フォロー',
    'unfollow': 'フォロー解除',
    'mutual_follow': '相互フォロー',
    'send_message': 'メッセージ',
    'user_posts': '投稿',
    'no_posts_in_channel': 'このチャンネルにはまだ投稿がありません',
    'go_to_user_profile': 'プロフィールを見る',
```

- [ ] **步骤 4：Commit**

```bash
git add lib/core/locales/zh_cn.dart lib/core/locales/en_us.dart lib/core/locales/ja_jp.dart
git commit -m "feat: add i18n keys for community module"
```

---

## 任务 3：创建路由定义

**文件：**
- 修改：`lib/app/routes/app_routes.dart`
- 修改：`lib/app/routes/app_pages.dart`

- [ ] **步骤 1：添加路由常量**

在 `app_routes.dart` 的 `AppRoutes` 类中添加：

```dart
  static const channel = '/channel';
```

注意：`userDetail` 已存在（`/user/detail`），无需重复添加。

- [ ] **步骤 2：添加路由映射和导入**

在 `app_pages.dart` 中：

1. 在文件顶部添加导入：

```dart
import '../../modules/channel/channel_page.dart';
import '../../modules/channel/channel_controller.dart';
import '../../modules/profile/user_detail_page.dart';
import '../../modules/profile/user_detail_controller.dart';
```

2. 在 `routes` 列表末尾（`myPosts` 的 GetPage 之后）添加：

```dart
    GetPage(
      name: '${AppRoutes.channel}/:tag',
      page: () => const ChannelPage(),
      binding: ChannelBinding(),
    ),
    GetPage(
      name: '${AppRoutes.userDetail}/:id',
      page: () => const UserDetailPage(),
      binding: UserDetailBinding(),
    ),
```

- [ ] **步骤 3：Commit**

```bash
git add lib/app/routes/app_routes.dart lib/app/routes/app_pages.dart
git commit -m "feat: add channel and user detail routes"
```

---

## 任务 4：创建 ChannelController

**文件：**
- 创建：`lib/modules/channel/channel_controller.dart`

- [ ] **步骤 1：创建 ChannelController**

```dart
// lib/modules/channel/channel_controller.dart
import 'package:get/get.dart';
import '../../data/models/post_model.dart';
import '../../data/providers/post_provider.dart';
import '../../data/repositories/post_repository.dart';

class ChannelController extends GetxController {
  final PostRepository _repo = PostRepository();
  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int _page = 1;

  String get tag => Get.parameters['tag'] ?? '';

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  Future<void> loadPosts() async {
    _page = 1;
    isLoading.value = true;
    hasMore.value = true;
    try {
      final result = await _repo.getPosts(tag: tag, page: 1, pageSize: 20);
      posts.value = result;
      hasMore.value = result.length >= 20;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      _page++;
      final result = await _repo.getPosts(tag: tag, page: _page, pageSize: 20);
      posts.addAll(result);
      hasMore.value = result.length >= 20;
    } catch (e) {
      _page--;
    } finally {
      isLoadingMore.value = false;
    }
  }
}

class ChannelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChannelController());
  }
}
```

- [ ] **步骤 2：验证 PostRepository 支持 tag 参数**

读取 `lib/data/repositories/post_repository.dart`，确认 `getPosts` 方法签名是否支持 `tag` 参数。如果需要，添加 `tag` 参数。

确认后，读取 `lib/data/providers/post_provider.dart`，确认 `getPosts` 方法是否支持 `tag` 查询参数。如果需要，在 provider 和 repository 中添加 `tag` 参数支持。

典型 pattern（如果需要修改）：

**PostProvider.getPosts 添加 tag 参数：**
```dart
  Future<Map<String, dynamic>> getPosts({int page = 1, int pageSize = 20, String? tag, String? authorId}) async {
    final response = await _api.dio.get('/posts', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (tag != null) 'tag': tag,
      if (authorId != null) 'authorId': authorId,
    });
    return response.data;
  }
```

**PostRepository.getPosts 添加 tag 参数：**
```dart
  Future<List<PostModel>> getPosts({int page = 1, int pageSize = 20, String? tag, String? authorId}) async {
    final res = await _provider.getPosts(page: page, pageSize: pageSize, tag: tag, authorId: authorId);
    if (res['code'] == 0) {
      final list = res['data']?['items'] ?? res['data'] ?? [];
      return (list as List).map((e) => PostModel.fromJson(e)).toList();
    }
    throw Exception(res['message'] ?? 'Failed to load posts');
  }
```

- [ ] **步骤 3：Commit**

```bash
git add lib/modules/channel/channel_controller.dart
git add lib/data/providers/post_provider.dart lib/data/repositories/post_repository.dart  # if modified
git commit -m "feat: add ChannelController with tag-based post loading"
```

---

## 任务 5：创建 ChannelCard 和 ChannelGrid 组件

**文件：**
- 创建：`lib/modules/home/widgets/channel_card.dart`
- 创建：`lib/modules/home/widgets/channel_grid.dart`

- [ ] **步骤 1：创建 ChannelCard**

```dart
// lib/modules/home/widgets/channel_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/channel_model.dart';

class ChannelCard extends StatelessWidget {
  final ChannelModel channel;
  final VoidCallback onTap;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF212121);
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: channel.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(channel.icon, color: channel.color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              channel.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              channel.description,
              style: TextStyle(fontSize: 12, color: subTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **步骤 2：创建 ChannelGrid**

```dart
// lib/modules/home/widgets/channel_grid.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/channel_model.dart';
import '../../../app/routes/app_routes.dart';
import 'channel_card.dart';

class ChannelGrid extends StatelessWidget {
  const ChannelGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 标题栏 ──
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Text(
                    'community'.tr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF212121),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () => Get.toNamed(AppRoutes.search),
                  ),
                ],
              ),
            ),
            // ── 频道网格 ──
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: ChannelModel.officialChannels.length,
              itemBuilder: (_, i) {
                final channel = ChannelModel.officialChannels[i];
                return ChannelCard(
                  channel: channel,
                  onTap: () => Get.toNamed(
                    '${AppRoutes.channel}/${Uri.encodeComponent(channel.tag)}',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **步骤 3：Commit**

```bash
git add lib/modules/home/widgets/channel_card.dart lib/modules/home/widgets/channel_grid.dart
git commit -m "feat: add ChannelCard and ChannelGrid widgets"
```

---

## 任务 6：修改首页 Tab 0 为频道网格

**文件：**
- 修改：`lib/modules/home/home_page.dart`

- [ ] **步骤 1：添加导入**

在 `home_page.dart` 顶部导入区域添加：

```dart
import '../widgets/channel_grid.dart';
```

注意：这里用的是相对路径 `../widgets/channel_grid.dart`，因为 home_page.dart 在 `modules/home/` 下，而 channel_grid.dart 在 `modules/home/widgets/` 下。实际路径应该是：

```dart
import 'widgets/channel_grid.dart';
```

- [ ] **步骤 2：替换 PageView 中的 FeedPage**

找到 `PageView` 的 `children` 列表，将第一项 `const FeedPage()` 替换为：

```dart
          const ChannelGrid(),  // 首页展示社区频道
```

原来的 `FeedPage` 导入可以保留（不再使用但不影响编译）。

- [ ] **步骤 3：Commit**

```bash
git add lib/modules/home/home_page.dart
git commit -m "feat: replace Tab 0 FeedPage with ChannelGrid"
```

---

## 任务 7：创建 ChannelPage（频道详情页）

**文件：**
- 创建：`lib/modules/channel/channel_page.dart`

- [ ] **步骤 1：创建 ChannelPage**

```dart
// lib/modules/channel/channel_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'channel_controller.dart';
import '../../data/models/channel_model.dart';
import '../../app/routes/app_routes.dart';
import '../feed/widgets/post_card.dart';

class ChannelPage extends GetView<ChannelController> {
  const ChannelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final accentColor = isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55);

    // 根据 tag 查找频道定义
    final tag = Uri.decodeComponent(Get.parameters['tag'] ?? '');
    final channel = ChannelModel.officialChannels.firstWhere(
      (c) => c.tag == tag,
      orElse: () => ChannelModel.officialChannels.first,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(channel.icon, color: channel.color, size: 22),
            const SizedBox(width: 8),
            Text(channel.name),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF212121),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.posts.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        if (controller.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(channel.icon, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'no_posts_in_channel'.tr,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadPosts,
          color: accentColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: controller.posts.length + (controller.hasMore.value ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == controller.posts.length) {
                controller.loadMore();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final post = controller.posts[i];
              return PostCard(
                post: post,
                onLike: () {},
                onTap: () => Get.toNamed('${AppRoutes.postDetail}/${post.id}'),
                onComment: () {},
              );
            },
          ),
        );
      }),
    );
  }
}
```

- [ ] **步骤 2：Commit**

```bash
git add lib/modules/channel/channel_page.dart
git commit -m "feat: add ChannelPage with tag-filtered post list"
```

---

## 任务 8：创建 UserDetailController

**文件：**
- 创建：`lib/modules/profile/user_detail_controller.dart`

- [ ] **步骤 1：创建 UserDetailController**

```dart
// lib/modules/profile/user_detail_controller.dart
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../../data/providers/api_client.dart';
import '../../data/providers/follow_provider.dart';
import '../../data/repositories/post_repository.dart';
import '../../core/storage/storage_service.dart';

class UserDetailController extends GetxController {
  final ApiClient _api = ApiClient();
  final FollowProvider _followProvider = FollowProvider();
  final PostRepository _postRepo = PostRepository();

  final user = Rxn<UserModel>();
  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingPosts = false.obs;
  final isFollowing = false.obs;
  final isMutualFollow = false.obs;
  final currentUserId = ''.obs;
  int _page = 1;
  final hasMore = true.obs;

  String get userId => Get.parameters['id'] ?? '';

  bool get isSelf => currentUserId.value == userId;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
    _loadUser();
    _loadPosts();
  }

  void _loadCurrentUser() {
    final token = StorageService.to.getString('token');
    if (token != null) {
      _api.dio.get('/users/me').then((res) {
        if (res.data['code'] == 0) {
          final data = res.data['data'];
          currentUserId.value = data['id'] ?? '';
          _checkFollowStatus();
        }
      }).catchError((_) {});
    }
  }

  Future<void> _loadUser() async {
    isLoading.value = true;
    try {
      final res = await _api.dio.get('/users/$userId');
      if (res.data['code'] == 0) {
        user.value = UserModel.fromJson(res.data['data']);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPosts() async {
    isLoadingPosts.value = true;
    try {
      final result = await _postRepo.getPosts(authorId: userId, page: 1, pageSize: 20);
      posts.value = result;
      hasMore.value = result.length >= 20;
    } catch (e) {
      // silent
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingPosts.value || !hasMore.value) return;
    isLoadingPosts.value = true;
    try {
      _page++;
      final result = await _postRepo.getPosts(authorId: userId, page: _page, pageSize: 20);
      posts.addAll(result);
      hasMore.value = result.length >= 20;
    } catch (e) {
      _page--;
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> _checkFollowStatus() async {
    if (isSelf || userId.isEmpty) return;
    try {
      final res = await _api.dio.get('/users/me/following');
      if (res.data['code'] == 0) {
        final followingList = res.data['data']?['items'] ?? res.data['data'] ?? [];
        final ids = (followingList as List).map((e) => e['id'] ?? e['followerId'] ?? '').toList();
        isFollowing.value = ids.contains(userId);
      }
    } catch (_) {}

    // 检查互相关注：获取目标用户的关注列表，看是否包含当前用户
    try {
      final res = await _api.dio.get('/users/$userId/following');
      if (res.data['code'] == 0) {
        final followingList = res.data['data']?['items'] ?? res.data['data'] ?? [];
        final ids = (followingList as List).map((e) => e['id'] ?? e['followingId'] ?? '').toList();
        isMutualFollow.value = ids.contains(currentUserId.value);
      }
    } catch (_) {}
  }

  Future<void> toggleFollow() async {
    try {
      if (isFollowing.value) {
        await _followProvider.unfollow(userId);
        isFollowing.value = false;
      } else {
        await _followProvider.toggleFollow(userId);
        isFollowing.value = true;
      }
      // 重新检查互相关注状态
      _checkFollowStatus();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}

class UserDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UserDetailController());
  }
}
```

- [ ] **步骤 2：Commit**

```bash
git add lib/modules/profile/user_detail_controller.dart
git commit -m "feat: add UserDetailController with follow/mutual-follow detection"
```

---

## 任务 9：创建 UserDetailPage（用户主页）

**文件：**
- 创建：`lib/modules/profile/user_detail_page.dart`

- [ ] **步骤 1：创建 UserDetailPage**

```dart
// lib/modules/profile/user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'user_detail_controller.dart';
import '../../app/routes/app_routes.dart';
import '../feed/widgets/post_card.dart';

class UserDetailPage extends GetView<UserDetailController> {
  const UserDetailPage({super.key});

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
      appBar: AppBar(
        title: Obx(() => Text(controller.user.value?.displayName ?? '')),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF212121),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }
        final user = controller.user.value;
        if (user == null) {
          return Center(child: Text('user_not_found'.tr));
        }
        return RefreshIndicator(
          onRefresh: () async {
            await controller._loadUser();
            await controller._loadPosts();
          },
          color: accentColor,
          child: CustomScrollView(
            slivers: [
              // ── 用户信息头部 ──
              SliverToBoxAdapter(child: _buildHeader(user, textColor, subTextColor, accentColor)),
              // ── 动态列表标题 ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('user_posts'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                ),
              ),
              // ── 帖子列表 ──
              if (controller.isLoadingPosts.value && controller.posts.isEmpty)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (controller.posts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text('no_posts_yet'.tr, style: TextStyle(color: subTextColor)),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i == controller.posts.length) {
                        controller.loadMorePosts();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final post = controller.posts[i];
                      return PostCard(
                        post: post,
                        onLike: () {},
                        onTap: () => Get.toNamed('${AppRoutes.postDetail}/${post.id}'),
                        onComment: () {},
                      );
                    },
                    childCount: controller.posts.length + (controller.hasMore.value ? 1 : 0),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(dynamic user, Color textColor, Color subTextColor, Color accentColor) {
    final isDark = Get.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // 头像
          CircleAvatar(
            radius: 44,
            backgroundColor: accentColor.withOpacity(0.1),
            backgroundImage: user.avatar != null && user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
            child: user.avatar == null || user.avatar.isEmpty
                ? Text(
                    (user.displayName)[0].toUpperCase(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          // 昵称
          Text(
            user.displayName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
          ),
          if (user.bio != null && user.bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              user.bio,
              style: TextStyle(fontSize: 13, color: subTextColor),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          // 统计数据
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem('${user.followerCount ?? 0}', 'fans_count'.tr, textColor, subTextColor),
              const SizedBox(width: 32),
              _statItem('${user.followingCount ?? 0}', 'following_count'.tr, textColor, subTextColor),
              const SizedBox(width: 32),
              _statItem('${user.postCount ?? 0}', 'posts_count'.tr, textColor, subTextColor),
            ],
          ),
          const SizedBox(height: 16),
          // 操作按钮
          if (!controller.isSelf) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 关注按钮
                Obx(() {
                  final isFollowing = controller.isFollowing.value;
                  final isMutual = controller.isMutualFollow.value;
                  return SizedBox(
                    width: 120,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: controller.toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? (isDark ? Colors.grey[700] : Colors.grey[300])
                            : accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        isMutual ? 'mutual_follow'.tr : (isFollowing ? 'unfollow'.tr : 'follow'.tr),
                        style: TextStyle(
                          color: isFollowing ? textColor : Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                // 发消息按钮（仅互相关注后显示）
                Obx(() {
                  if (!controller.isMutualFollow.value) return const SizedBox.shrink();
                  return SizedBox(
                    width: 120,
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          final res = await Get.find<UserDetailController>()._api.dio.post('/conversations', data: {
                            'targetUserId': controller.userId,
                          });
                          if (res.data['code'] == 0) {
                            final conversationId = res.data['data']['id'];
                            Get.toNamed('${AppRoutes.chatDetail}/$conversationId');
                          }
                        } catch (e) {
                          Get.snackbar('Error', e.toString());
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('send_message'.tr, style: TextStyle(color: accentColor, fontSize: 14)),
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String count, String label, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: subTextColor)),
      ],
    );
  }

  Color get cardColor => Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
}
```

- [ ] **步骤 2：Commit**

```bash
git add lib/modules/profile/user_detail_page.dart
git commit -m "feat: add UserDetailPage with profile header and post list"
```

---

## 任务 10：修改 PostDetailPage 支持作者头像点击

**文件：**
- 修改：`lib/modules/post/post_detail_page.dart`

- [ ] **步骤 1：添加导入**

在文件顶部添加：

```dart
import '../../app/routes/app_routes.dart';
```

- [ ] **步骤 2：修改 _buildHeader 中的 CircleAvatar**

找到 `_buildHeader` 方法中的 `CircleAvatar`（约第 69-76 行），用 `GestureDetector` 包裹，使作者头像可点击：

将原来的：
```dart
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: post.author?.avatar != null ? NetworkImage(post.author!.avatar!) : null,
            child: post.author?.avatar == null
                ? Text((post.author?.nickname ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                : null,
          ),
```

替换为：
```dart
          GestureDetector(
            onTap: () {
              if (post.author?.id != null) {
                Get.toNamed('${AppRoutes.userDetail}/${post.author!.id}');
              }
            },
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: post.author?.avatar != null ? NetworkImage(post.author!.avatar!) : null,
              child: post.author?.avatar == null
                  ? Text((post.author?.nickname ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
```

- [ ] **步骤 3：修改作者昵称可点击**

找到头像右侧的昵称 `Text` widget（在 `_buildHeader` 方法中，约第 80-85 行附近），同样用 `GestureDetector` 包裹：

将原来的（类似）：
```dart
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.author?.nickname ?? 'User', ...),
                ...
```

在昵称的 Text 外面包裹 GestureDetector：
```dart
                GestureDetector(
                  onTap: () {
                    if (post.author?.id != null) {
                      Get.toNamed('${AppRoutes.userDetail}/${post.author!.id}');
                    }
                  },
                  child: Text(post.author?.nickname ?? 'User', style: TextStyle(...)),
                ),
```

- [ ] **步骤 4：Commit**

```bash
git add lib/modules/post/post_detail_page.dart
git commit -m "feat: make author avatar/nickname clickable on post detail"
```

---

## 任务 11：修改 FeedPage 评论区用户头像可点击

**文件：**
- 修改：`lib/modules/feed/feed_page.dart`

- [ ] **步骤 1：添加导入**

在文件顶部添加：

```dart
import '../../app/routes/app_routes.dart';
```

- [ ] **步骤 2：确认 PostCard 作者头像可点击**

读取 `lib/modules/feed/widgets/post_card.dart`，找到头部的 `CircleAvatar` 和昵称 Text，用 `GestureDetector` 包裹使其可点击跳转用户主页。

在 `post_card.dart` 顶部添加导入：

```dart
import '../../../app/routes/app_routes.dart';
```

找到帖子头部的 `CircleAvatar`（显示作者头像的），用 GestureDetector 包裹：

```dart
GestureDetector(
  onTap: () {
    if (post.author?.id != null) {
      Get.toNamed('${AppRoutes.userDetail}/${post.author!.id}');
    }
  },
  child: CircleAvatar(
    // ... 原来的 CircleAvatar 内容
  ),
),
```

同样处理昵称的 Text widget，使其也可点击跳转。

- [ ] **步骤 3：Commit**

```bash
git add lib/modules/feed/widgets/post_card.dart
git commit -m "feat: make author avatar/nickname clickable on post cards"
```

---

## 任务 12：更新 main.dart 保留新页面

**文件：**
- 修改：`lib/main.dart`

- [ ] **步骤 1：添加导入**

在文件顶部导入区域添加：

```dart
import 'modules/channel/channel_page.dart';
import 'modules/profile/user_detail_page.dart';
import 'modules/channel/channel_controller.dart';
import 'modules/profile/user_detail_controller.dart';
```

- [ ] **步骤 2：在 _keepAlive 中添加**

在 `_keepAlive()` 函数中添加：

```dart
  ignore(ChannelPage);
  ignore(UserDetailPage);
```

- [ ] **步骤 3：Commit**

```bash
git add lib/main.dart
git commit -m "feat: register new pages in main.dart keepAlive"
```

---

## 任务 13：验证编译

- [ ] **步骤 1：运行 flutter analyze**

```bash
cd E:/2506C/zg6/Flutter/flutter
flutter analyze
```

检查是否有编译错误。常见问题：
- 导入路径错误
- 缺少参数
- 类型不匹配

- [ ] **步骤 2：修复发现的编译错误**

根据 analyze 输出逐一修复。

- [ ] **步骤 3：运行 flutter build web --no-tree-shake-icons**

```bash
flutter build web --no-tree-shake-icons
```

确认构建成功。

- [ ] **步骤 4：Commit（如有修复）**

```bash
git add -A
git commit -m "fix: resolve compilation errors for community module"
```

---

## 执行总结

完成以上 13 个任务后，社区模块功能将全部就绪：

| 功能 | 状态 |
|------|------|
| 首页展示 8 个官方频道 | 任务 5, 6 |
| 点击频道进入频道详情页 | 任务 4, 7 |
| 频道详情页帖子列表（分页） | 任务 4, 7 |
| 用户主页展示 | 任务 8, 9 |
| 关注/取消关注 | 任务 8, 9 |
| 互相关注检测 | 任务 8, 9 |
| 互相关注后发消息 | 任务 9 |
| 帖子详情作者可点击 | 任务 10 |
| 帖子卡片作者可点击 | 任务 11 |
| i18n 支持 | 任务 2 |
| 路由注册 | 任务 3 |
| 深色模式适配 | 所有 UI 任务 |
