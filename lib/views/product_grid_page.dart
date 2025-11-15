// Lokasi: lib/views/product_grid_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Ganti 'flutter_application' dengan nama proyekmu
import 'package:flutter_application/controllers/product_controller.dart';
import 'package:flutter_application/models/product_model.dart';

class ProductGridPage extends StatelessWidget {
  ProductGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    // "Nyalakan" atau "Temukan" Otak kita.
    final ProductController controller = Get.put(ProductController());

    return Scaffold(
      appBar: AppBar(title: const Text('Nasi Padang Mart'), centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Obx ini membungkus UI yang bergantung pada state
            return Obx(() {
              // Tampilkan loading jika isLoading true
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Jika selesai loading, tampilkan grid
              final width = constraints.maxWidth;
              final crossAxisCount = controller.calculateCrossAxisCount(width);
              final childAspectRatio = controller.calculateChildAspectRatio(
                crossAxisCount,
                width,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8,
                ),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final p = controller.products[index];
                    return ProductCard(
                      product: p,
                      priceLabel: controller.formatRupiah(p.price),
                      onTap: () => controller.showProductDialog(p),
                    );
                  },
                ),
              );
            });
          },
        ),
      ),
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            onPressed: controller.openCartDialog,
            child: const Icon(Icons.shopping_cart),
          ),
          // Obx untuk meng-update badge keranjang
          Obx(
            () => controller.cart.isEmpty
                ? const SizedBox.shrink()
                : Positioned(
                    right: -6,
                    top: -6,
                    child: Material(
                      elevation: 2,
                      shape: const CircleBorder(),
                      color: Colors.redAccent,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          '${controller.cart.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// KODE ProductCard LENGKAP
// ===================================================================
class ProductCard extends StatelessWidget {
  final Product product;
  final String priceLabel;
  final VoidCallback onTap;
  const ProductCard({
    super.key,
    required this.product,
    required this.priceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.brown,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
