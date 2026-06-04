import 'package:get/get.dart';
import 'transfer_controller.dart';

class TransferBinding extends BindingsBuilder {
  TransferBinding() : super(() {
    Get.lazyPut(() => TransferController());
  });
}
