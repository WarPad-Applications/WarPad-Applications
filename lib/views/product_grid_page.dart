import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../controllers/auth_controller.dart'; // Import Auth
import '../widgets/product_card.dart';
import 'product_detail_page.dart';
import 'checkout_page.dart';

class ProductGridPage extends StatelessWidget {
  const ProductGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductController controller = Get.find<ProductController>();
    final AuthController authC = Get.find<AuthController>(); // Instance Auth

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.arguments != null && Get.arguments is String) {
        controller.scrollToSection(Get.arguments);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Menu'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: ['Makanan', 'Minuman', 'Paket'].map((cat) {
                return Obx(() {
                  bool isActive = controller.activeTab.value == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isActive,
                      selectedColor: Colors.deepOrange,
                      labelStyle: TextStyle(
                        color: isActive ? Colors.white : Colors.black,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => controller.scrollToSection(cat),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: false,
                    ),
                  );
                });
              }).toList(),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          controller: controller.menuScrollController,
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _buildSection(controller, 'Makanan'),
            _buildSection(controller, 'Minuman'),
            _buildSection(controller, 'Paket'),
          ],
        );
      }),
      // --- PERBAIKAN LOGIK LOGIN DISINI ---
      floatingActionButton: Obx(() {
        if (controller.cartItems.isEmpty) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          backgroundColor: Colors.deepOrange,
          onPressed: () {
            // CEK LOGIN DULU SEBELUM KE CHECKOUT
            if (!authC.isLoggedIn) {
              Get.snackbar(
                "Belum Login",
                "Silakan login untuk melanjutkan pemesanan",
              );
              Get.toNamed('/login');
            } else {
              Get.to(() => const CheckoutPage());
            }
          },
          label: Text(
            "${controller.cartItems.length} Item - Rp ${controller.subTotal.toStringAsFixed(0)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          icon: const Icon(Icons.shopping_basket, color: Colors.white),
        );
      }),
    );
  }

  Widget _buildSection(ProductController c, String category) {
    final list = c.products.where((p) => p.category == category).toList();
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            category,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (ctx, i) {
            final p = list[i];
            return GestureDetector(
              onTap: () => Get.to(() => ProductDetailPage(product: p)),
              child: ProductCard(
                product: p,
                priceLabel: "Rp ${p.price.toStringAsFixed(0)}",
              ),
            );
          },
        ),
      ],
    );
  }
}
