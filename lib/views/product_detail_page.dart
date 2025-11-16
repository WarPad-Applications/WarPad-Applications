import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../controllers/product_controller.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final int index;
  const ProductDetailPage({
    super.key,
    required this.product,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final ProductController controller = Get.find<ProductController>();
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Image.network(product.imageUrl, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Text(
              'Harga: Rp ${product.price.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(product.description ?? '-', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.addToCart(product);
                Get.back();
              },
              child: const Text('Tambah ke Keranjang'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                // contoh: hapus produk (hanya untuk testing/admin)
                await controller.deleteProduct(index);
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Hapus Produk'),
            ),
          ],
        ),
      ),
    );
  }
}
