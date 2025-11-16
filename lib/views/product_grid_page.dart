import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/product_controller.dart';
import '../services/shared_pref_service.dart';
import 'product_detail_page.dart';
import '../widgets/product_card.dart';

class ProductGridPage extends StatelessWidget {
  const ProductGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductController controller = Get.find<ProductController>();
    final SharedPrefService themeService = Get.find<SharedPrefService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nasi Padang Mart'),
        centerTitle: true,
        actions: [
          // Theme toggle
          IconButton(
            icon: Obx(
              () => Icon(
                themeService.isDarkMode.value
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
            ),
            onPressed: themeService.toggleTheme,
          ),
        ],
      ),

      // =========================
      //         PRODUCT GRID
      // =========================
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = controller.products;

        if (items.isEmpty) {
          return const Center(child: Text('Tidak ada produk'));
        }

        // Responsive grid
        final width = MediaQuery.of(context).size.width;
        final crossAxisCount = width < 600 ? 2 : (width < 900 ? 3 : 4);

        final tileWidth = width / crossAxisCount;
        final tileHeight = (tileWidth * 0.75) + 60;
        final childAspectRatio = tileWidth / tileHeight;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final p = items[index];
              return GestureDetector(
                onTap: () =>
                    Get.to(() => ProductDetailPage(product: p, index: index)),
                child: ProductCard(
                  product: p,
                  priceLabel: 'Rp ${p.price.toStringAsFixed(0)}',
                ),
              );
            },
          ),
        );
      }),

      // =========================
      //         CART BUTTON
      // =========================
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (_) => _CartDialog());
        },
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }
}

// =============================
//       CART DIALOG
// =============================
class _CartDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ProductController c = Get.find<ProductController>();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Keranjang'),
          Obx(() => Text('(${c.cart.length})')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Obx(() {
          if (c.cart.isEmpty) return const Text('Keranjang kosong');

          return ListView.separated(
            shrinkWrap: true,
            itemCount: c.cart.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final it = c.cart[i];
              return ListTile(
                leading: Image.network(
                  it.imageUrl,
                  width: 56,
                  fit: BoxFit.cover,
                ),
                title: Text(it.title),
                subtitle: Text('Rp ${it.price.toStringAsFixed(0)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => c.removeFromCart(i),
                ),
              );
            },
          );
        }),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        Obx(
          () => ElevatedButton(
            onPressed: c.cart.isEmpty
                ? null
                : () {
                    c.checkout();
                    Get.back();
                  },
            child: Text(c.cart.isEmpty ? 'Kosong' : 'Checkout'),
          ),
        ),
      ],
    );
  }
}
