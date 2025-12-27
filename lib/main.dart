// path: lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Import services & bindings
import 'services/shared_pref_service.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'bindings/product_binding.dart';
import 'models/product_model.dart';
import 'routes.dart';

// Background Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Init Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. Init Supabase (Gunakan URL & Key Kamu)
  await Supabase.initialize(
    url: "https://cffzpiijnxcfrpvtqbta.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmZnpwaWlqbnhjZnJwdnRxYnRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzMTA2ODYsImV4cCI6MjA3ODg4NjY4Nn0.2htwdoXWQgcidpEVq78AuhB_aAYscmmcOm1JMI1WbU4",
  );

  // 3. Init Services
  await Get.putAsync(() => SharedPrefService().init());

  // Hive Service (Pastikan model adapter sudah dibuat oleh build_runner nanti)
  final hiveService = HiveService();
  await hiveService.init();
  Get.put(hiveService);

  await Get.putAsync(() => SupabaseService().init());

  final notif = NotificationService();
  await notif.init();
  Get.put(notif);

  runApp(const NasiPadangMartApp());
}

class NasiPadangMartApp extends StatelessWidget {
  const NasiPadangMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SharedPrefService themeService = Get.find<SharedPrefService>();

    return Obx(() {
      return GetMaterialApp(
        title: 'WarPad',
        debugShowCheckedModeBanner: false,

        // Rute
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.pages,

        // Binding Awal (Akan memuat ProductController & AuthController)
        initialBinding: ProductBinding(),

        // Tema
        themeMode: themeService.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF5722),
          ), // Deep Orange
          scaffoldBackgroundColor: Colors.grey[50],
        ),
        darkTheme: ThemeData.dark(),
      );
    });
  }
}
