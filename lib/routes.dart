// path: lib/routes.dart
import 'package:get/get.dart';
import 'views/product_grid_page.dart';
import 'views/location_view.dart';
import 'bindings/location_binding.dart';
import 'bindings/product_binding.dart';

class AppPages {
  static const INITIAL = '/';
  static final pages = [
    GetPage(
      name: '/',
      page: () => const ProductGridPage(),
      binding: ProductBinding(), // <-- penting
    ),
    GetPage(
      name: '/location',
      page: () => const LocationView(),
      binding: LocationBinding(),
    ),
  ];
}
