import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../../core/storage/storage_service.dart';
import '../../core/network/socket_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../app/routes/app_routes.dart';
import '../chat/chat_list_controller.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final UserRepository _userRepo = UserRepository();
  final currentIndex = 0.obs;
  final user = Rxn<UserModel>();
  final bgIndex = 0.obs;
  final customBackgroundUrl = ''.obs;
  final balance = 0.0.obs;
  final unreadNotificationCount = 0.obs;
  final unreadConversationCount = 0.obs;
  late final PageController pageController;

  final List<List<Color>> bgGradients = const [
    [Color(0xFF2D2B55), Color(0xFF3D3B70), Color(0xFF4A4580)],
    [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    [Color(0xFF2D1B69), Color(0xFF6B3FA0), Color(0xFF8B5CF6)],
    [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
    [Color(0xFF3C1642), Color(0xFF7B2D8E), Color(0xFFB83B5E)],
    [Color(0xFF2C003E), Color(0xFF512B58), Color(0xFF8174A0)],
    [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF2E4057)],
  ];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    pageController = PageController();
    // 先从本地加载用户和背景，确保重启后立即显示
    _loadUserLocal();
    _loadBackground();
    // 再异步刷新用户信息（API 失败不影响本地数据）
    // 刷新成功后重新加载背景（用户ID可能在首次加载时为空）
    _refreshUserFromApi().then((_) => _loadBackground());
    _loadBalance();
    SocketService.to.connect();
    _listenNotifications();
  }

  String get _userId => user.value?.id ?? '';

  String _resolveUserId() {
    var userId = _userId;
    if (userId.isEmpty) {
      final userData = StorageService.to.getUser();
      userId = userData?['id'] ?? '';
    }
    return userId;
  }

  void _loadBackground() {
    final userId = _resolveUserId();
    if (userId.isEmpty) return;
    final bg = StorageService.to.getUserBackground(userId);
    final savedUrl = bg['customBackgroundUrl'] ?? '';
    final hasPath = savedUrl.contains('/uploads/') || savedUrl.contains('/images/');
    customBackgroundUrl.value = hasPath ? savedUrl : '';
    bgIndex.value = bg['bgIndex'] ?? 0;
  }

  /// Validate that URL points to an actual uploaded file (not just a bare domain)
  static bool _isValidBackgroundUrl(String url) {
    if (url.isEmpty) return false;
    final base = AppConstants.baseUrl.replaceAll('/api', '');
    // Reject bare domain or domain-with-slash
    if (url == base || url == '$base/') return false;
    // Must contain a path segment after the domain
    final afterBase = url.substring(base.length);
    return afterBase.isNotEmpty && afterBase != '/';
  }

  Future<void> saveBackground(String url) async {
    if (!_isValidBackgroundUrl(url)) return;
    customBackgroundUrl.value = url;
    final userId = _resolveUserId();
    if (userId.isNotEmpty) {
      await StorageService.to.saveUserBackground(userId, customUrl: url);
    }
  }

  void setBgIndex(int index) {
    bgIndex.value = index;
    customBackgroundUrl.value = '';
    _persistBg();
  }

  void clearCustomBackground() {
    customBackgroundUrl.value = '';
    _persistBg();
  }

  Future<void> _persistBg() async {
    final userId = _resolveUserId();
    if (userId.isEmpty) return;
    await StorageService.to.saveUserBackground(
      userId,
      bgIndex: bgIndex.value,
      customUrl: customBackgroundUrl.value,
    );
  }

  void _listenNotifications() {
    SocketService.to.onNotificationCount((data) {
      if (data is Map) {
        unreadNotificationCount.value = data['count'] ?? 0;
      }
    });
    SocketService.to.onNotification((_) {
      unreadNotificationCount.value++;
    });
  }

  void updateUnreadConversationCount() {
    try {
      final chatController = Get.find<ChatListController>();
      int total = 0;
      for (final conv in chatController.conversations) {
        total += conv.unreadCount;
      }
      unreadConversationCount.value = total;
    } catch (_) {}
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBalance();
    }
  }

  /// 从本地存储加载用户（同步，确保重启后立即可用）
  void _loadUserLocal() {
    try {
      final userData = StorageService.to.getUser();
      if (userData != null) {
        user.value = UserModel.fromJson(userData);
      }
    } catch (_) {}
  }

  /// 从 API 刷新用户信息（异步，失败不影响本地数据）
  Future<void> _refreshUserFromApi() async {
    try {
      final freshUser = await _userRepo.getMe();
      if (freshUser != null) {
        user.value = freshUser;
        // 更新本地缓存
        await StorageService.to.saveUser(freshUser.toJson());
      }
    } catch (_) {}
  }

  Future<void> _loadUser() async {
    _loadUserLocal();
    await _refreshUserFromApi();
  }

  Future<void> _loadBalance() async {
    try {
      final api = ApiClient();
      final res = await api.dio.get(ApiEndpoints.walletBalance);
      if (res.data['code'] == 0) {
        balance.value = (res.data['data']['balance'] ?? 0).toDouble();
      }
    } catch (_) {}
  }

  Future<void> refreshUser() async {
    _loadUserLocal();
    await _refreshUserFromApi();
  }

  void changeTab(int index) {
    if (index == 2) {
      Get.toNamed(AppRoutes.createPost);
      return;
    }
    currentIndex.value = index;
    pageController.jumpToPage(index);
    // Reload conversations when switching to chat tab
    if (index == 3) {
      try {
        Get.find<ChatListController>().loadConversations();
      } catch (_) {}
    }
    // 切换到我的页面时刷新余额
    if (index == 4) {
      _loadBalance();
    }
  }

  Future<void> logout() async {
    SocketService.to.disconnect();
    await StorageService.to.clearAll();
    Get.offAllNamed(AppRoutes.login);
  }
}
