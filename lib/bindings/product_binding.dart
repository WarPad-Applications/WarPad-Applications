// path: lib/bindings/product_binding.dart
import 'package:get/get.dart';
import '../controllers/product_controller.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductController>(() => ProductController());
  }

  /// helper: instansiasi langsung jika butuh memastikan controller sudah ada
  /// (mengembalikan instance untuk dipasang di main dengan Get.put(...))
  ProductController dependenciesReturnInstance() {
    final controller = ProductController();
    // If another instance existed, this will replace it by default
    Get.put<ProductController>(controller);
    return controller;
  }
}
