import 'package:get/get.dart';
import 'set_password_controller.dart';

class SetPasswordBinding extends BindingsBuilder {
  SetPasswordBinding() : super(() {
    Get.lazyPut(() => SetPasswordController());
  });
}
