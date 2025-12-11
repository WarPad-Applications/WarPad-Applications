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

// Background handler for Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // handling background message
  debugPrint("Background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2) Init Supabase (using your url & anon key)
  await Supabase.initialize(
    url: "https://cffzpiijnxcfrpvtqbta.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmZnpwaWlqbnhjZnJwdnRxYnRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzMTA2ODYsImV4cCI6MjA3ODg4NjY4Nn0.2htwdoXWQgcidpEVq78AuhB_aAYscmmcOm1JMI1WbU4",
  );

  // 3) Init local storage & services
  await Hive.initFlutter();

  // Register adapters (pastikan ProductAdapter sudah digenerate)
  // e.g. Hive.registerAdapter(ProductAdapter());
  // jika belum: jalankan `flutter pub run build_runner build --delete-conflicting-outputs`
  // (pastikan file generated ada)
  try {
    Hive.registerAdapter(ProductAdapter());
  } catch (_) {
    // ignore if already registered or adapter not ready yet
  }

  // Init services via Get
  await Get.putAsync(() => SharedPrefService().init());
  await Get.putAsync(() => HiveService().init());
  await Get.putAsync(() => SupabaseService().init());

  final notif = NotificationService();
  await notif.init();
  Get.put(notif);

  // Option A (safe): register ProductController immediately to avoid "not found" on startup
  // We'll also add the binding so other routes can lazy put as well.
  Get.put(
    ProductBinding().dependenciesReturnInstance(),
  ); // helper to ensure controller exists

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

        // set initialBinding so pages get their bindings automatically (optional)
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

        // Use ProductGridPage as home (controller already bound by initialBinding)
        home: const ProductGridPage(),
      );
    });
  }
}
