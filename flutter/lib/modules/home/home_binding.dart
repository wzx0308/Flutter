import 'package:get/get.dart';
import 'home_controller.dart';
import '../feed/feed_controller.dart';
import '../discover/discover_controller.dart';
import '../chat/chat_list_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => FeedController());
    Get.lazyPut(() => DiscoverController());
    Get.lazyPut(() => ChatListController());
  }
}
