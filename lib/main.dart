import 'package:flutter/material.dart';

import 'package:get/get.dart';



// Import untuk Supabase, Hive, Shared Preferences

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';



// Import Model, View, dan Service

import 'package:flutter_application/models/product_model.dart'; 

import 'package:flutter_application/views/product_grid_page.dart';

import 'package:flutter_application/services/data_service.dart';



// [IMPOR TAMBAHAN KRUSIAL]

import 'package:flutter_application/controllers/product_controller.dart';





// =========================================================

// !!! GANTI DENGAN KUNCI ASLI ANDA !!!

// =========================================================

const SUPABASE_URL = 'https://yxndceiediebmpebuqjm.supabase.co'; 

const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl4bmRjZWllZGllYm1wZWJ1cWptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyMTMyMDIsImV4cCI6MjA3ODc4OTIwMn0.H8AuNuLD9zYgp1kpUdDCPtqIRYxWJN2pOGIeo1v0x_I'; // KUNCI ANDA

// =========================================================





void main() async {

  WidgetsFlutterBinding.ensureInitialized();



  // Inisialisasi Hive (Database Lokal NoSQL)

  await Hive.initFlutter();

  Hive.registerAdapter(ProductAdapter()); 

  // Menggunakan 'productBox' sesuai dengan yang Anda definisikan

  await Hive.openBox<Product>('productBox');



  // Inisialisasi Supabase (Cloud Database)

  await Supabase.initialize(

    url: SUPABASE_URL,

    anonKey: SUPABASE_ANON_KEY,

    // [PERBAIKAN KRUSIAL] Parameter 'authFlowType' dihapus karena menyebabkan error.

  );

  

  // Inisialisasi Shared Preferences

  final prefs = await SharedPreferences.getInstance();



  // =========================================================

  // REGISTRASI SERVICE DENGAN GETX (URUTAN KRUSIAL)

  // =========================================================

  

  // 1. Daftarkan SharedPreferences (Dependency DataService)

  Get.put<SharedPreferences>(prefs); 

  

  // 2. Daftarkan SupabaseClient (Dependency DataService)

  // Ini memperbaiki error "SupabaseClient not found"

  Get.put<SupabaseClient>(Supabase.instance.client);

  

  // 3. Daftarkan DataService (Menggunakan SupabaseClient dan SharedPreferences)

  Get.put(DataService()); 



  // 4. Daftarkan ProductController (Dependency ProductGridPage)

  // Ini memastikan controller tersedia saat view memanggil Get.find()

  Get.put(ProductController());



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

      home: const ProductGridPage(),

    );

  }

}