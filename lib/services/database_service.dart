import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class DataService extends GetxService {
  final supabase = Supabase.instance.client;
  late Box<Product> _productBox;

  // Status ketersediaan data
  var isOnline = true.obs;
  var lastSynced = 'Belum pernah disinkronkan'.obs;

  @override
  void onInit() {
    super.onInit();
    // Mendapatkan box Hive yang sudah dibuka di main.dart
    _productBox = Hive.box<Product>('productBox');
  }

  // =======================================================
  // Fungsi Utama: Mengambil data dengan logika Failover
  // =======================================================
  Future<List<Product>> fetchProducts() async {
    isOnline.value = true; // Asumsikan online di awal

    try {
      // 1. Cek Koneksi Internet (opsional, tapi disarankan untuk failover cepat)
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          isOnline.value = true;
        } else {
          isOnline.value = false;
        }
      } on SocketException catch (_) {
        isOnline.value = false;
      }

      // 2. Jika koneksi tersedia, coba ambil dari Supabase
      if (isOnline.value) {
        print('Mencoba mengambil data dari Supabase (Cloud)...');
        
        // Panggil tabel 'products' dari Supabase
        final List<dynamic> response = await supabase
            .from('products')
            .select('*')
            .order('id', ascending: true);

        final products = response.map((json) => Product.fromJson(json)).toList();

        // 3. Sinkronkan ke Hive (Local Cache)
        await _syncToHive(products);
        lastSynced.value = DateTime.now().toString().substring(0, 16);
        print('Sinkronisasi ke Hive berhasil.');
        
        return products;
      }
    } catch (e) {
      // Logika ini menangkap kegagalan Supabase (misalnya, timeout atau koneksi buruk)
      print('Gagal mengambil dari Supabase ($e). Menggunakan Hive (Lokal).');
      isOnline.value = false;
    }

    // 4. Jika Supabase gagal, ambil dari Hive (Mode Offline/Failover)
    print('Mengambil data dari Hive (Lokal Cache)...');
    return _productBox.values.toList();
  }

  // =======================================================
  // Fungsi Sinkronisasi (Menyimpan data terbaru ke Hive)
  // =======================================================
  Future<void> _syncToHive(List<Product> products) async {
    await _productBox.clear(); // Bersihkan data lama
    await _productBox.addAll(products); // Tambahkan data baru
  }

  // =======================================================
  // Fungsi Modifikasi (Wajib Lulus Eksperimen)
  // =======================================================

  // Uji: Modifikasi item di Hive saat Offline
  Future<void> updateProductLocally(int index, String newName) async {
    final productToUpdate = _productBox.getAt(index);
    if (productToUpdate != null) {
      // Membuat objek baru karena properti 'final'
      final updatedProduct = Product(
        id: productToUpdate.id,
        name: newName,
        description: productToUpdate.description,
        price: productToUpdate.price,
      );
      await _productBox.putAt(index, updatedProduct);
      
      // Catat di sini: Meskipun offline, Hive berhasil diupdate
      print('Produk di Hive (indeks $index) berhasil diupdate menjadi $newName');
    }
  }

  // Uji: Simpan flag ke Shared Preferences saat Offline
  Future<void> setOfflineFlag() async {
    final prefs = Get.find<SharedPreferences>();
    await prefs.setBool('offline_test_flag', true);
    print('Flag Shared Preferences berhasil diset saat offline.');
  }

  // Uji: Baca flag dari Shared Preferences saat Offline
  bool getOfflineFlag() {
    final prefs = Get.find<SharedPreferences>();
    final flag = prefs.getBool('offline_test_flag') ?? false;
    print('Membaca flag Shared Preferences: $flag');
    return flag;
  }
}