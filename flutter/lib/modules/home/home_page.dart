import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/locale_service.dart';
import '../feed/feed_page.dart';
import '../chat/chat_list_page.dart';
import '../discover/discover_page.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../core/network/upload_service.dart';
import 'widgets/channel_grid.dart';
import '../widgets/floating_3d_avatar.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安隅'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => Get.toNamed(AppRoutes.search)),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const ChannelGrid(),
              const DiscoverPage(),
              const SizedBox(), // placeholder for create tab
              const ChatListPage(),
              _buildProfileTab(context),
            ],
          ),
          const Floating3dAvatar(),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final isDark = Get.isDarkMode;
        final navBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        return Container(
          decoration: BoxDecoration(
            color: navBg,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2)),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: navBg,
            selectedItemColor: isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55),
            unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: 'tab_home'.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.explore_outlined), activeIcon: const Icon(Icons.explore), label: 'tab_discover'.tr),
              BottomNavigationBarItem(icon: const Icon(Icons.add_box_outlined), activeIcon: const Icon(Icons.add_box), label: 'tab_publish'.tr),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: controller.unreadConversationCount.value > 0,
                  label: Text(controller.unreadConversationCount.value > 99 ? '99+' : '${controller.unreadConversationCount.value}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                activeIcon: Badge(
                  isLabelVisible: controller.unreadConversationCount.value > 0,
                  label: Text(controller.unreadConversationCount.value > 99 ? '99+' : '${controller.unreadConversationCount.value}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  child: const Icon(Icons.chat_bubble),
                ),
                label: 'tab_message'.tr,
              ),
              BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: 'tab_profile'.tr),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 头部用户信息 ──
            Obx(() {
              final customUrl = controller.customBackgroundUrl.value;
              final bgIndex = controller.bgIndex.value;
              final bgColors = controller.bgGradients[bgIndex];
              final hasCustomImage = customUrl.isNotEmpty;
              return Stack(
                children: [
                  // 基础渐变背景（始终渲染，作为 fallback）
                  Container(
                    width: double.infinity,
                    height: 320.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: bgColors,
                      ),
                    ),
                  ),
                  // 自定义背景图片（覆盖在渐变之上，加载失败时渐变自然露出）
                  if (hasCustomImage)
                    Positioned.fill(
                      child: Image.network(
                        customUrl,
                        key: ValueKey(customUrl),
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.3),
                        colorBlendMode: BlendMode.darken,
                        loadingBuilder: (ctx, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox.shrink();
                        },
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  // 内容区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 48, bottom: 28, left: 24, right: 24),
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 头像
                    Obx(() {
                      final user = controller.user.value;
                      final avatar = user?.avatar;
                      return GestureDetector(
                        onTap: () => Get.toNamed('/profile/edit'),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                child: avatar == null || avatar.isEmpty
                                    ? const Icon(Icons.person, size: 42, color: Colors.white)
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF2D2B55)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    // 用户名
                    Obx(() => Text(
                          controller.user.value?.displayName ?? '用户',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        )),
                    const SizedBox(height: 6),
                    // 个性签名
                    Obx(() => Text(
                          controller.user.value?.bio ?? '这个人很懒，什么都没写',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.65)),
                        )),
                    const SizedBox(height: 20),
                    // 统计数据
                    Obx(() {
                          final u = controller.user.value;
                          final uid = u?.id ?? '';
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: uid.isNotEmpty ? () => Get.toNamed(AppRoutes.followList, arguments: {'userId': uid, 'type': 'followers'}) : null,
                                  child: _statItem('${u?.followerCount ?? 0}', 'fans'.tr),
                                ),
                                Container(width: 1, height: 24, color: Colors.white.withOpacity(0.2)),
                                GestureDetector(
                                  onTap: uid.isNotEmpty ? () => Get.toNamed(AppRoutes.followList, arguments: {'userId': uid, 'type': 'following'}) : null,
                                  child: _statItem('${u?.followingCount ?? 0}', 'following'.tr),
                                ),
                                Container(width: 1, height: 24, color: Colors.white.withOpacity(0.2)),
                                GestureDetector(
                                  onTap: uid.isNotEmpty ? () => Get.toNamed(AppRoutes.myPosts) : null,
                                  child: _statItem('${u?.postCount ?? 0}', 'posts'.tr),
                                ),
                              ],
                            ),
                          );
                        }),
                    const SizedBox(height: 16),
                    // 自定义背景按钮
                    GestureDetector(
                      onTap: () => _showBgPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.palette_outlined, size: 14, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(width: 6),
                            Text('switch_background'.tr, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ],
              );
            }),

            // ── 余额卡片 ──
            Transform.translate(
              offset: const Offset(0, -16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => Get.toNamed('/wallet'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D2B55).withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFFF9800), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('my_balance'.tr, style: TextStyle(fontSize: 13, color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[500])),
                              const SizedBox(height: 2),
                              Obx(() => Text(
                                    '¥ ${controller.balance.value.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Get.isDarkMode ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: Get.isDarkMode ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('recharge'.tr, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 个人信息 ──
            _buildSection('personal_info'.tr, [
              _buildMenuItem(Icons.edit_outlined, 'edit_profile'.tr, Get.isDarkMode ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55), () => Get.toNamed('/profile/edit')),
              _buildMenuItem(Icons.article_outlined, 'my_posts'.tr, const Color(0xFF4CAF50), () => Get.toNamed(AppRoutes.myPosts)),
              _buildMenuItem(Icons.verified_outlined, 'real_name_auth'.tr, const Color(0xFFFF9800), () => _showRealNameAuth(context)),
            ]),

            // ── 我的服务 ──
            _buildSection('my_services'.tr, [
              _buildMenuItem(Icons.account_balance_wallet_outlined, 'my_wallet'.tr, const Color(0xFF4CAF50), () => Get.toNamed('/wallet')),
              _buildMenuItem(Icons.star_border_rounded, 'my_favorites'.tr, const Color(0xFFFF9800), () => Get.toNamed(AppRoutes.myBookmarks)),
              _buildMenuItem(Icons.history_rounded, 'browse_history'.tr, const Color(0xFF2196F3), () => Get.toNamed(AppRoutes.browseHistory)),
              _buildMenuItem(Icons.people_outline, 'friends_list'.tr, const Color(0xFF00BCD4), () => Get.toNamed(AppRoutes.friendsList)),
              _buildMenuItem(Icons.location_on_outlined, 'my_address'.tr, const Color(0xFFE91E63), () {}),
            ]),

            // ── 设置 ──
            _buildSection('settings_section'.tr, [
              _buildMenuItem(Icons.lock_outline, 'password_change'.tr, const Color(0xFF607D8B), () => Get.toNamed('/settings/change-password')),
              _buildMenuItem(Icons.notifications_outlined, 'notifications'.tr, const Color(0xFF9C27B0), () => Get.toNamed(AppRoutes.notifications)),
              _buildThemeToggle(),
              _buildLanguagePicker(),
              _buildMenuItem(Icons.settings_outlined, 'settings'.tr, const Color(0xFF607D8B), () => Get.toNamed('/settings')),
              Obx(() {
                if (controller.user.value?.role == 'ADMIN') {
                  return _buildMenuItem(Icons.admin_panel_settings, 'admin_dashboard'.tr, Colors.red, () => Get.toNamed(AppRoutes.admin));
                }
                return const SizedBox.shrink();
              }),
            ]),

            const SizedBox(height: 8),

            // ── 退出登录 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Get.defaultDialog(
                    title: 'logout_title'.tr,
                    middleText: 'logout_confirm'.tr,
                    textConfirm: 'confirm_btn'.tr,
                    textCancel: 'cancel_btn'.tr,
                    confirmTextColor: Colors.white,
                    buttonColor: const Color(0xFF2D2B55),
                    onConfirm: () {
                      Get.back();
                      controller.logout();
                    },
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red[400], size: 18),
                      const SizedBox(width: 6),
                      Text('logout'.tr, style: TextStyle(color: Colors.red[400], fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Obx(() {
      final isDark = ThemeService.to.isDark;
      return InkWell(
        onTap: () => ThemeService.to.toggleTheme(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF607D8B)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? const Color(0xFF7C4DFF) : const Color(0xFF607D8B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(isDark ? 'dark_mode'.tr : 'light_mode'.tr, style: TextStyle(fontSize: 15, color: Get.isDarkMode ? Colors.white70 : const Color(0xFF212121))),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isDark,
                  onChanged: (_) => ThemeService.to.toggleTheme(),
                  activeThumbColor: const Color(0xFF2D2B55),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLanguagePicker() {
    return InkWell(
      onTap: () => _showLanguageSheet(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.language_rounded, color: Color(0xFF2196F3), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('language'.tr, style: TextStyle(fontSize: 15, color: Get.isDarkMode ? Colors.white70 : const Color(0xFF212121))),
            ),
            Obx(() {
              final locale = LocaleService.to.currentLocale.value;
              final name = LocaleService.localeNames['${locale.languageCode}_${locale.countryCode}'] ?? locale.languageCode;
              return Text(name, style: TextStyle(color: Colors.grey[400], fontSize: 14));
            }),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final isDark = Get.isDarkMode;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('select_language'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF212121))),
            const SizedBox(height: 6),
            Text('select_language_hint'.tr, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 20),
            ...LocaleService.supportedLocales.map((locale) {
              final key = '${locale.languageCode}_${locale.countryCode}';
              final name = LocaleService.localeNames[key] ?? locale.languageCode;
              return Obx(() {
                final selected = LocaleService.to.currentLocale.value == locale;
                return InkWell(
                  onTap: () {
                    LocaleService.to.setLocale(locale);
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2D2B55).withOpacity(0.08)
                          : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? const Color(0xFF2D2B55) : Colors.grey[200]!,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(name, style: TextStyle(
                          fontSize: 16,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected ? const Color(0xFF2D2B55) : (isDark ? Colors.white70 : const Color(0xFF212121)),
                        )),
                        const Spacer(),
                        if (selected) const Icon(Icons.check_rounded, color: Color(0xFF2D2B55), size: 20),
                      ],
                    ),
                  ),
                );
              });
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showBgPicker(BuildContext context) {
    final isDark = Get.isDarkMode;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('select_background'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF212121))),
            const SizedBox(height: 6),
            Text('select_background_hint'.tr, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 4,
                mainAxisSpacing: 10.w,
                crossAxisSpacing: 10.w,
              ),
              itemCount: controller.bgGradients.length,
              itemBuilder: (_, i) {
                return Obx(() {
                  final selected = controller.bgIndex.value == i;
                  return GestureDetector(
                    onTap: () {
                      controller.setBgIndex(i);
                      Get.back();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: controller.bgGradients[i],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: controller.bgGradients[i][0].withOpacity(0.4), blurRadius: 8)]
                            : [],
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                });
              },
            ),
            const SizedBox(height: 12),
            // Custom image upload button
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (picked != null) {
                  try {
                    final bytes = await picked.readAsBytes();
                    final uploadService = UploadService();
                    final url = await uploadService.uploadImageBytes(bytes, picked.name);
                    controller.saveBackground(url);
                    Get.back();
                    Get.snackbar('Success', 'Background updated');
                  } catch (e) {
                    Get.snackbar('Error', 'Upload failed: $e');
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[500], size: 20),
                    const SizedBox(width: 8),
                    Text('Upload Custom', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showRealNameAuth(BuildContext context) {
    final isDark = Get.isDarkMode;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('real_name_auth'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF212121))),
            const SizedBox(height: 6),
            Text('完成实名认证后可解锁更多功能', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 24),
            _buildBottomSheetField('真实姓名', Icons.person_outline),
            const SizedBox(height: 14),
            _buildBottomSheetField('身份证号', Icons.credit_card_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.snackbar('提示', '实名认证功能开发中');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2B55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('提交认证', style: TextStyle(fontSize: 15, color: Colors.white)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetField(String hint, IconData icon) {
    final isDark = Get.isDarkMode;
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: const Color(0xFF2D2B55), size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8FA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D2B55), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final isDark = Get.isDarkMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[500])),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color iconColor, VoidCallback onTap) {
    final isDark = Get.isDarkMode;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: isDark ? Colors.white70 : const Color(0xFF212121))),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }
}
