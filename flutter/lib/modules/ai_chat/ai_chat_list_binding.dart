import 'package:get/get.dart';
import 'ai_chat_list_controller.dart';

class AiChatListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiChatListController>(() => AiChatListController());
  }
}
