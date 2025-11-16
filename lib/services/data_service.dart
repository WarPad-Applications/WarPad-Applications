import 'dart:async';
// import 'dart:convert'; // [FIXED] Unused import removed

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class DataService extends GetxService {
  final SupabaseClient _supabase = Get.find<SupabaseClient>();
  final SharedPreferences _prefs = Get.find<SharedPreferences>();
  final _productBox = Hive.box<Product>('productBox');

  // Stream Controller untuk data real-time
  final _productStreamController = StreamController<List<Product>>.broadcast();
  Stream<List<Product>> get productStream => _productStreamController.stream;

  @override
  void onInit() {
    super.onInit();
    _startSupabaseListener();
  }

  // =======================================================
  // Supabase Real-time Listener & Sync
  // =======================================================

  void _startSupabaseListener() {
    // 1. Setup Realtime Channel
    _supabase.from('products').stream(primaryKey: ['id']).listen((dataList) {
      if (dataList.isNotEmpty) {
        // Map data JSON dari Supabase ke list Product
        final products = dataList
            // [FIXED] Unnecessary cast removed
            .map((map) => Product.fromJson(map)) 
            .toList();

        _productStreamController.add(products);
        _saveProductsToHive(products);
        _prefs.setString('lastSynced', DateTime.now().toIso8601String());
        debugPrint('DATA SERVICE: Data berhasil disinkronisasi ke Hive.');
      } else {
        debugPrint('DATA SERVICE: Supabase stream kosong.');
        _productStreamController.add([]);
      }
    });
  }

  // =======================================================
  // Hive Cache (Offline Data)
  // =======================================================

  Future<void> _saveProductsToHive(List<Product> products) async {
    // 1. Clear Box yang lama
    await _productBox.clear();
    // 2. Isi Box dengan data baru
    await _productBox.addAll(products);
    debugPrint('DATA SERVICE: ${products.length} produk disimpan di Hive.');
  }

  Future<List<Product>> fetchProductsFromHive() async {
    debugPrint('DATA SERVICE: Memuat produk dari Hive...');
    return _productBox.values.toList();
  }

  // =======================================================
  // Supabase CRUD Operations (for Multi-Device Test)
  // =======================================================

  Future<void> addProduct(Product product) async {
    try {
      final dataToSend = product.toMap();
      await _supabase.from('products').insert(dataToSend);
      debugPrint('DATA SERVICE: Produk berhasil ditambahkan.');
    } on PostgrestException catch (e) {
      debugPrint('DATA SERVICE ERROR: Gagal menambah produk: ${e.message}');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final dataToUpdate = product.toMap();
      await _supabase
          .from('products')
          .update(dataToUpdate)
          .eq('id', product.id);
      
      debugPrint('DATA SERVICE: Produk berhasil diperbarui: ${product.id}');
    } on PostgrestException catch (e) {
      debugPrint('DATA SERVICE ERROR: Gagal memperbarui produk: ${e.message}');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
      debugPrint('DATA SERVICE: Produk berhasil dihapus: $id');
    } on PostgrestException catch (e) {
      debugPrint('DATA SERVICE ERROR: Gagal menghapus produk: ${e.message}');
    }
  }
}