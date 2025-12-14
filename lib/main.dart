// path: lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// services & views & bindings
import 'services/shared_pref_service.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'bindings/product_binding.dart';
import 'views/product_grid_page.dart';
import 'models/product_model.dart';
import 'routes.dart'; // <--- (PENTING) Import file routes.dart

// Background handler for Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2) Init Supabase
  await Supabase.initialize(
    url: "https://cffzpiijnxcfrpvtqbta.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmZnpwaWlqbnhjZnJwdnRxYnRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzMTA2ODYsImV4cCI6MjA3ODg4NjY4Nn0.2htwdoXWQgcidpEVq78AuhB_aAYscmmcOm1JMI1WbU4",
  );

  // 3) Init local storage & services
  await Hive.initFlutter();

  try {
    Hive.registerAdapter(ProductAdapter());
  } catch (_) {
    // ignore if already registered
  }

  // Init services via Get
  await Get.putAsync(() => SharedPrefService().init());
  await Get.putAsync(() => HiveService().init());
  await Get.putAsync(() => SupabaseService().init());

  final notif = NotificationService();
  await notif.init();
  Get.put(notif);

  // Register Controller
  Get.put(ProductBinding().dependenciesReturnInstance());

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

        // --- BAGIAN INI YANG DITAMBAHKAN UNTUK MEMPERBAIKI ERROR ---
        initialRoute: AppPages.INITIAL, // Halaman awal ('/')
        getPages: AppPages.pages, // Daftar rute (termasuk '/location')
        // -----------------------------------------------------------
        initialBinding: ProductBinding(),

        themeMode: themeService.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,

        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.amber,
          scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.amber,
        ),
      );
    });
  }
}
