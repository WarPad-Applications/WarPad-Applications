import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../controllers/product_controller.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final ProductController controller = Get.find<ProductController>();

    // Cek apakah gambar dari Internet atau Lokal
    bool isOnline = product.imageUrl.startsWith('http');

    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // --- AREA GAMBAR ---
                  Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: isOnline
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.contain, // Gambar utuh
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey),
                          )
                        : Image.asset(
                            product.imageUrl,
                            fit: BoxFit.contain, // Gambar utuh
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey),
                          ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Rp ${product.price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Deskripsi:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description ?? "Tidak ada deskripsi",
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTTOM BAR (Tombol Tambah) ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  var cartItem = controller.cartItems.firstWhereOrNull(
                    (e) => e.product.id == product.id,
                  );

                  if (cartItem == null) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        // --- REVISI LOGIKA TOMBOL ---
                        onPressed: () {
                          // Panggil fungsi addToCart dan cek hasilnya
                          bool success = controller.addToCart(product);

                          // HANYA tutup halaman jika user berhasil nambah (sudah login)
                          if (success) {
                            Get.back();
                          }
                          // Jika belum login, controller akan redirect ke '/login'
                          // dan halaman ini tetap terbuka di stack bawahnya
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Tambah ke Pesanan",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _circleButton(
                          Icons.remove,
                          Colors.red,
                          () => controller.decreaseQty(cartItem),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          "${cartItem.qty.value}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 24),
                        _circleButton(
                          Icons.add,
                          Colors.green,
                          () => controller.increaseQty(cartItem),
                        ),
                      ],
                    );
                  }
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
