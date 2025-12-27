import 'package:get/get.dart';
import 'views/dashboard_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/product_grid_page.dart';
import 'views/location_view.dart';
import 'views/checkout_page.dart'; // Import Baru

import 'bindings/product_binding.dart';
import 'bindings/location_binding.dart';
import 'bindings/auth_binding.dart';

class AppPages {
  static const INITIAL = '/';

  static final pages = [
    GetPage(
      name: '/',
      page: () => const DashboardPage(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: '/login',
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: '/register',
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: '/location',
      page: () => const LocationView(),
      binding: LocationBinding(),
    ),
    // RUTE MENU DENGAN ARGUMENT
    GetPage(
      name: '/menu',
      page: () => const ProductGridPage(),
      binding: ProductBinding(),
    ),
    // RUTE CHECKOUT (BARU)
    GetPage(
      name: '/checkout',
      page: () => const CheckoutPage(),
      binding: ProductBinding(),
    ),
  ];
}
