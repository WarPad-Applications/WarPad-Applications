// path: lib/bindings/location_binding.dart
import 'package:get/get.dart';
import '../controllers/location_controller.dart';

class LocationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationController>(() => LocationController());
  }
}
