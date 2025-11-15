// Lokasi: lib/controllers/product_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/database_service.dart'; // Import DatabaseService

class ProductController extends GetxController {
  // --- "INGATAN" / STATE ---
  var products = <Product>[].obs;
  var isLoading = true.obs;
  var cart = <Product>[].obs;

  // --- SERVICE ---
  final DatabaseService _dbService =
      DatabaseService(); // Buat "Petugas Database"

  // --- FUNGSI INIT ---
  // Otomatis dipanggil saat controller dibuat
  @override
  void onInit() {
    super.onInit();
    // Ganti fetchProducts dari API menjadi dari Database
    loadProductsFromDB();
  }

  // --- FUNGSI DATABASE (PENGGANTI API CALL) ---
  Future<void> loadProductsFromDB() async {
    try {
      isLoading(true);
      // Minta data ke Petugas Database
      final productList = await _dbService.getProducts();
      print("Controller: dapat ${productList.length} produk dari DB");
      products.value = productList;
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data dari database: $e');
    } finally {
      isLoading(false);
    }
  }

  // --- FUNGSI HELPER (LOGIKA MURNI) ---
  String formatRupiah(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write('.');
    }
    final reversed = buf.toString().split('').reversed.join();
    return 'Rp $reversed';
  }

  int calculateCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  double calculateChildAspectRatio(int crossAxisCount, double width) {
    final tileWidth = width / crossAxisCount;
    final tileHeight = (tileWidth * 0.75) + 60;
    return tileWidth / tileHeight;
  }

  // --- FUNGSI AKSI (MENGUBAH STATE) ---
  void addToCart(Product p) {
    cart.add(p);
    Get.back(); // Tutup dialog
    Get.snackbar(
      'Sukses',
      '${p.title} ditambahkan ke keranjang',
      backgroundColor: Colors.amber[700],
      colorText: Colors.black,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void removeFromCart(int index) {
    cart.removeAt(index);
    Get.back(); // Tutup dialog lama
    openCartDialog(); // Buka lagi dialog keranjang (agar UI-nya update)
  }

  void checkout() {
    final total = cart.fold<int>(0, (prev, item) => prev + item.price);
    final itemCount = cart.length;

    cart.clear();
    Get.back(); // Tutup dialog
    Get.snackbar(
      'Checkout Berhasil',
      '$itemCount item, total ${formatRupiah(total)}',
      backgroundColor: Colors.amber[700],
      colorText: Colors.black,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // --- FUNGSI UNTUK MENAMPILKAN DIALOG (PAKAI GETX) ---
  void showProductDialog(Product p) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFFFF3CD),
        title: Text(
          p.title,
          style: const TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Image.network(
                p.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Harga: ${formatRupiah(p.price)}'),
            const SizedBox(height: 8),
            const Text(
              'Menu khas Padang — nikmati cita rasa rendang, gulai, dan sambal khas kami.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup', style: TextStyle(color: Colors.brown)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () => addToCart(p),
            child: const Text('Tambah ke Keranjang'),
          ),
        ],
      ),
    );
  }

  void openCartDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFFFF3CD),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Keranjang',
              style: TextStyle(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(() => Text('(${cart.length})')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(
            () => cart.isEmpty
                ? const Text(
                    'Keranjang kosong',
                    style: TextStyle(color: Colors.brown),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return ListTile(
                        leading: SizedBox(
                          width: 56,
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(item.title),
                        subtitle: Text(formatRupiah(item.price)),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.brown,
                          ),
                          onPressed: () => removeFromCart(index),
                        ),
                      );
                    },
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup', style: TextStyle(color: Colors.brown)),
          ),
          Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: cart.isEmpty ? null : checkout,
              child: Text(
                cart.isEmpty
                    ? 'Kosong'
                    : 'Checkout (${formatRupiah(cart.fold(0, (prev, item) => prev + item.price))})',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
