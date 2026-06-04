import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/splash/splash_page.dart';
import '../../modules/splash/splash_binding.dart';
import '../../modules/auth/login_page.dart';
import '../../modules/auth/login_binding.dart';
import '../../modules/auth/register_page.dart';
import '../../modules/auth/register_binding.dart';
import '../../modules/home/home_page.dart';
import '../../modules/home/home_binding.dart';
import '../../modules/post/create_post_page.dart';
import '../../modules/post/create_post_binding.dart';
import '../../modules/post/post_detail_page.dart';
import '../../modules/post/post_detail_binding.dart';
import '../../modules/chat/chat_detail_page.dart';
import '../../modules/chat/chat_detail_binding.dart';
import '../../modules/discover/search_page.dart';
import '../../modules/admin/admin_dashboard_page.dart';
import '../../modules/admin/admin_binding.dart';
import '../../modules/profile/edit_profile_page.dart';
import '../../modules/profile/edit_profile_binding.dart';
import '../../modules/settings/settings_page.dart';
import '../../modules/settings/settings_binding.dart';
import '../../modules/settings/change_password_page.dart';
import '../../modules/settings/change_password_binding.dart';
import '../../modules/wallet/wallet_page.dart';
import '../../modules/wallet/wallet_binding.dart';
import '../../modules/profile/my_posts_page.dart';
import '../../modules/profile/my_posts_binding.dart';
import '../../modules/channel/channel_page.dart';
import '../../modules/channel/channel_controller.dart';
import '../../modules/profile/user_detail_page.dart';
import '../../modules/profile/user_detail_controller.dart';
import '../../modules/profile/follow_list_page.dart';
import '../../modules/profile/follow_list_controller.dart';
import '../../modules/profile/my_bookmarks_page.dart';
import '../../modules/profile/my_bookmarks_controller.dart';
import '../../modules/profile/browse_history_page.dart';
import '../../modules/profile/browse_history_controller.dart';
import '../../modules/notification/notification_page.dart';
import '../../modules/notification/notification_controller.dart';
import '../../modules/profile/friends_list_page.dart';
import '../../modules/profile/friends_list_controller.dart';
import '../../modules/ai_chat/ai_chat_list_page.dart';
import '../../modules/ai_chat/ai_chat_list_binding.dart';
import '../../modules/ai_chat/ai_chat_detail_page.dart';
import '../../modules/ai_chat/ai_chat_detail_binding.dart';
import '../../modules/transfer/transfer_page.dart';
import '../../modules/transfer/transfer_binding.dart';
import '../../modules/transfer/transfer_success_page.dart';
import '../../modules/wallet/set_password_page.dart';
import '../../modules/wallet/set_password_binding.dart';
import '../../modules/call/call_page.dart';
import '../../modules/call/call_binding.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.createPost,
      page: () => const CreatePostPage(),
      binding: CreatePostBinding(),
    ),
    GetPage(
      name: '${AppRoutes.postDetail}/:id',
      page: () => const PostDetailPage(),
      binding: PostDetailBinding(),
    ),
    GetPage(
      name: '${AppRoutes.chatDetail}/:id',
      page: () => const ChatDetailPage(),
      binding: ChatDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminDashboardPage(),
      binding: AdminBinding(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfilePage(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordPage(),
      binding: ChangePasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.wallet,
      page: () => const WalletPage(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: AppRoutes.setPaymentPassword,
      page: () => const SetPasswordPage(),
      binding: SetPasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.transfer,
      page: () => const TransferPage(),
      binding: TransferBinding(),
    ),
    GetPage(
      name: AppRoutes.transferSuccess,
      page: () => const TransferSuccessPage(),
    ),
    GetPage(
      name: AppRoutes.myPosts,
      page: () => const MyPostsPage(),
      binding: MyPostsBinding(),
    ),
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
    GetPage(
      name: AppRoutes.followList,
      page: () => const FollowListPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FollowListController());
      }),
    ),
    GetPage(
      name: AppRoutes.myBookmarks,
      page: () => const MyBookmarksPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MyBookmarksController());
      }),
    ),
    GetPage(
      name: AppRoutes.browseHistory,
      page: () => const BrowseHistoryPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => BrowseHistoryController());
      }),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NotificationController());
      }),
    ),
    GetPage(
      name: AppRoutes.friendsList,
      page: () => const FriendsListPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FriendsListController());
      }),
    ),
    GetPage(
      name: AppRoutes.aiChatList,
      page: () => const AiChatListPage(),
      binding: AiChatListBinding(),
    ),
    GetPage(
      name: '${AppRoutes.aiChatDetail}/:id',
      page: () => const AiChatDetailPage(),
      binding: AiChatDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.call,
      page: () => const CallPage(),
      binding: CallBinding(),
    ),
  ];
}
