// Lokasi: lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Penting untuk inisialisasi DB
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Ganti import sesuai proyekmu
import 'package:flutter_application/views/product_grid_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================
  // WAJIB! (Windows & Linux)
  // ==========================
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const NasiPadangMartApp());
}

class NasiPadangMartApp extends StatelessWidget {
  const NasiPadangMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Nasi Padang Mart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFC107),
          foregroundColor: Colors.brown,
        ),
      ),
      home: ProductGridPage(),
    );
  }
}
