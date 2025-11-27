// path: lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/shared_pref_service.dart';
import 'services/hive_service.dart';
import 'services/supabase_service.dart';
import 'controllers/product_controller.dart';
import 'routes.dart';

Future<void> initServices() async {
  await Supabase.initialize(
    url: "https://cffzpiijnxcfrpvtqbta.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmZnpwaWlqbnhjZnJwdnRxYnRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzMTA2ODYsImV4cCI6MjA3ODg4NjY4Nn0.2htwdoXWQgcidpEVq78AuhB_aAYscmmcOm1JMI1WbU4",
  );

  await Get.putAsync(() => SharedPrefService().init());
  await Get.putAsync(() => HiveService().init());
  await Get.putAsync(() => SupabaseService().init());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServices();
  Get.put(ProductController()); // keep product controller global as before
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<SharedPrefService>();
    return Obx(() {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nasi Padang Mart',
        themeMode: themeService.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        theme: ThemeData(
          primarySwatch: Colors.amber,
          scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        ),
        darkTheme: ThemeData.dark(),
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.pages,
      );
    });
  }
}
