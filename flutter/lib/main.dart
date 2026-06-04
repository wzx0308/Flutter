import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/storage/storage_service.dart';
import 'core/network/socket_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/locale_service.dart';
import 'core/locales/app_translations.dart';
import 'data/services/post_service.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
// Prevent dart2js tree-shaking from removing page classes
import 'modules/profile/edit_profile_page.dart';
import 'modules/settings/settings_page.dart';
import 'modules/settings/change_password_page.dart';
import 'modules/wallet/wallet_page.dart';
import 'modules/profile/my_posts_page.dart';
import 'modules/profile/edit_profile_controller.dart';
import 'modules/settings/settings_controller.dart';
import 'modules/settings/change_password_controller.dart';
import 'modules/wallet/wallet_controller.dart';
import 'modules/profile/my_posts_controller.dart';
import 'modules/channel/channel_page.dart';
import 'modules/profile/user_detail_page.dart';
import 'modules/channel/channel_controller.dart';
import 'modules/profile/user_detail_controller.dart';
import 'modules/profile/follow_list_page.dart';
import 'modules/profile/follow_list_controller.dart';
import 'modules/profile/my_bookmarks_page.dart';
import 'modules/profile/my_bookmarks_controller.dart';
import 'modules/profile/browse_history_page.dart';
import 'modules/profile/browse_history_controller.dart';
import 'modules/ai_chat/ai_chat_list_page.dart';
import 'modules/ai_chat/ai_chat_list_controller.dart';
import 'modules/ai_chat/ai_chat_detail_page.dart';
import 'modules/ai_chat/ai_chat_detail_controller.dart';
import 'core/web/web_helper.dart';
import 'core/services/image_cache_service.dart';
import 'core/services/rtc_service.dart';
import 'modules/call/call_page.dart';
import 'modules/call/call_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web 端修复 model-viewer CSS 覆盖问题
  initWebFixes();

  // Initialize storage
  await Get.putAsync(() => StorageService().init());
  // Initialize socket service
  await Get.putAsync(() => SocketService().init());
  // Initialize theme service
  Get.put(ThemeService().init());
  // Initialize locale service
  Get.put(LocaleService().init());
  // Initialize post service (shared state for like/bookmark across all lists)
  Get.put(PostService());
  // Initialize image cache service (filesystem storage for AI chat images)
  await Get.putAsync(() => ImageCacheService().init());
  // Register Agora RTC service (engine initialized lazily on first call)
  Get.put(RtcService());

  // Prevent tree-shaking from removing page classes
  _keepAlive();

  runApp(const MyApp());
}

void _keepAlive() {
  // Force compiler to keep these classes
  ignore(EditProfilePage);
  ignore(SettingsPage);
  ignore(ChangePasswordPage);
  ignore(WalletPage);
  ignore(MyPostsPage);
  ignore(ChannelPage);
  ignore(UserDetailPage);
  ignore(AiChatListPage);
  ignore(AiChatDetailPage);
  ignore(CallPage);
}

void ignore(dynamic _) {}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Obx(() {
          final themeService = ThemeService.to;
          final localeService = LocaleService.to;
          return GetMaterialApp(
            title: '安隅',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeService.themeMode.value,
            translations: AppTranslations(),
            locale: localeService.currentLocale.value,
            fallbackLocale: const Locale('en', 'US'),
            initialRoute: AppPages.initial,
            getPages: AppPages.routes,
            defaultTransition: Transition.cupertino,
          );
        });
      },
    );
  }
}
