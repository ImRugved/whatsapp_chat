import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
  }
}
