import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../controllers/auth_controller.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    // Pastikan AuthController ada, jika belum
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
    Get.lazyPut<ProductController>(() => ProductController());
  }
}
