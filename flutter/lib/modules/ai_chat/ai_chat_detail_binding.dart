import 'package:get/get.dart';
import 'ai_chat_detail_controller.dart';

class AiChatDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiChatDetailController>(() => AiChatDetailController());
  }
}
