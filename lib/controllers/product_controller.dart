import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; 

import '../models/product_model.dart';
import '../services/data_service.dart';

class ProductController extends GetxController {
  // Service Instances
  final DataService _dataService = Get.find<DataService>();
  final SharedPreferences _prefs = Get.find<SharedPreferences>(); 

  // State Reaktif Utama
  var isLoading = true.obs;
  var productList = <Product>[].obs;
  var isOnline = true.obs;
  var lastSynced = 'N/A'.obs;
  
  // State Reaktif Keranjang Belanja
  var cart = <Product, int>{}.obs; 
  var totalCartItems = 0.obs;

  // Subscription untuk mendengarkan stream Supabase
  StreamSubscription<List<Product>>? _productSubscription; 

  @override
  void onInit() {
    super.onInit();
    
    // Muat waktu sync lama dari Shared Preferences
    final storedSyncTime = _prefs.getString('lastSynced');
    if (storedSyncTime != null) {
      final dateTime = DateTime.parse(storedSyncTime).toLocal();
      lastSynced.value = DateFormat('HH:mm:ss').format(dateTime);
    }
    
    // Watcher untuk menghitung total item di keranjang
    ever(cart, (_) => totalCartItems.value = _calculateTotalItems());

    startListeningToProducts(); 
  }
  
  @override
  void onClose() {
    _productSubscription?.cancel();
    super.onClose();
  }


  // =======================================================
  // Fungsi Utama: Real-time Listener & Failover
  // =======================================================

  void startListeningToProducts() {
    isLoading.value = true;
    _productSubscription?.cancel();

    // 1. Pemuatan Awal dari Hive
    _dataService.fetchProductsFromHive().then((localProducts) {
      if (productList.isEmpty) {
        productList.assignAll(localProducts);
        if(localProducts.isNotEmpty) isOnline.value = false;
      }
      isLoading.value = false;
    });

    // 2. Langganan ke Real-time Stream dari Supabase
    _productSubscription = _dataService.productStream.listen(
      (products) {
        // Callback saat data baru tiba (Real-time / Online)
        productList.assignAll(products);
        isOnline.value = true;
        
        final newLastSynced = _prefs.getString('lastSynced');
        if (newLastSynced != null) {
          final dateTime = DateTime.parse(newLastSynced).toLocal();
          lastSynced.value = DateFormat('HH:mm:ss').format(dateTime);
        }
        debugPrint('CONTROLLER: Sinkronisasi Real-time Berhasil. (${products.length} item)');
        isLoading.value = false;
      },
      onError: (error) async {
        debugPrint('CONTROLLER ERROR: Stream Supabase gagal: $error. Memuat dari Hive...');
        isOnline.value = false;
        
        final localProducts = await _dataService.fetchProductsFromHive();
        productList.assignAll(localProducts);
        isLoading.value = false;
        
        Get.snackbar('Mode Offline', 'Menggunakan data cache terakhir. Sinkronisasi terputus.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFFA726),
          colorText: const Color(0xFF212121),
        );
      },
      onDone: () {
        debugPrint('CONTROLLER: Stream selesai.');
      }
    );
  }
  

  // =======================================================
  // Fungsi CRUD (Untuk Pengujian Multi-Perangkat)
  // =======================================================
  
  Future<void> addTestProduct() async {
    if (!isOnline.value) {
      Get.snackbar('Gagal!', 'Anda harus Online untuk menambahkan produk.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final now = DateTime.now();
    final newProduct = Product(
      id: 0, 
      name: 'Catatan Tes (${DateFormat('HH:mm:ss').format(now)})',
      description: 'Dibuat di Perangkat A.',
      price: 1000.0,
      // [FIXED] Menambahkan imageUrl yang dibutuhkan (Baris 125 di kode sebelumnya)
      imageUrl: 'https://placehold.co/150x150/50C878/white?text=SYNC',
    );
    await _dataService.addProduct(newProduct);
  }
  
  Future<void> updateFirstProduct() async {
    if (!isOnline.value) {
      Get.snackbar('Gagal!', 'Anda harus Online untuk mengedit produk.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (productList.isNotEmpty) {
      final productToUpdate = productList.first;
      final now = DateTime.now();
      final updatedProduct = Product(
        id: productToUpdate.id,
        name: productToUpdate.name,
        description: 'DIEDIT di Perangkat A pada ${DateFormat('HH:mm:ss').format(now)}',
        price: productToUpdate.price + 100,
        // [FIXED] Menggunakan imageUrl dan Null Check (Baris 146 di kode sebelumnya)
        // Memberikan URL default jika imageUrl pada objek saat ini null, 
        // karena constructor Product() membutuhkannya (String non-nullable).
        imageUrl: productToUpdate.imageUrl ?? 'https://placehold.co/150x150/CCCCCC/000000?text=NO+IMG', 
      );
      await _dataService.updateProduct(updatedProduct);
    } else {
      Get.snackbar('Gagal!', 'Tambahkan produk tes terlebih dahulu.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteFirstProduct() async {
    if (!isOnline.value) {
      Get.snackbar('Gagal!', 'Anda harus Online untuk menghapus produk.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (productList.isNotEmpty) {
      await _dataService.deleteProduct(productList.first.id);
    } else {
      Get.snackbar('Gagal!', 'Tidak ada produk untuk dihapus.', snackPosition: SnackPosition.BOTTOM);
    }
  }


  // =======================================================
  // Fungsi Utilitas & Keranjang
  // =======================================================
  
  int _calculateTotalItems() {
    return cart.values.fold(0, (sum, quantity) => sum + quantity);
  }
  
  void addToCart(Product product) {
    if (cart.containsKey(product)) {
      cart[product] = cart[product]! + 1;
    } else {
      cart[product] = 1;
    }
    cart.refresh();
    Get.snackbar('Keranjang', '${product.name} ditambahkan!',
        snackPosition: SnackPosition.BOTTOM);
  }

  String formatRupiah(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  int calculateCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 1000) return 3;
    return 4;
  }

  double calculateChildAspectRatio(double width) {
    if (width < 600) return 0.8; 
    if (width < 1000) return 0.85; 
    return 0.9; 
  }
  
  void showProductDialog(Product product) {
    Get.dialog(
      AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.description),
            const SizedBox(height: 10),
            Text(formatRupiah(product.price),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
          ElevatedButton(
            onPressed: () { addToCart(product); Get.back(); },
            child: const Text('Tambah ke Keranjang'),
          ),
        ],
      ),
    );
  }
  
  void openCartDialog() {
    Get.dialog(
      Obx(() => AlertDialog(
        title: const Text("Keranjang Belanja"),
        content: cart.isEmpty
            ? const Text("Keranjang kosong.")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: cart.entries
                    .map((entry) => ListTile(
                          title: Text(entry.key.name),
                          trailing: Text("x${entry.value}"),
                        ))
                    .toList(),
              ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      )),
    );
  }
}