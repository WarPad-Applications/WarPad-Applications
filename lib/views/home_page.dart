import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/promo_banner.dart';
import '../controllers/auth_controller.dart';
import '../controllers/product_controller.dart';
import 'product_detail_page.dart';
import 'reservation_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authC = Get.find<AuthController>();
    final productC = Get.find<ProductController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(
                            () => Text(
                              "Halo, ${authC.userProfile.value?['full_name'] ?? 'Pelanggan'} 👋",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Mau makan apa hari ini?",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const PromoBanner(),
              const SizedBox(height: 20),

              // 2. MENU ICON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMenuIcon(
                      Icons.rice_bowl,
                      "Makanan",
                      Colors.orange,
                      () => Get.toNamed('/menu', arguments: 'Makanan'),
                    ),
                    _buildMenuIcon(
                      Icons.local_drink,
                      "Minuman",
                      Colors.blue,
                      () => Get.toNamed('/menu', arguments: 'Minuman'),
                    ),
                    // Menu Reservasi
                    _buildMenuIcon(
                      Icons.calendar_month,
                      "Reservasi",
                      Colors.pink,
                      () => Get.to(() => const ReservationPage()),
                    ),
                    // Menu Paket (Pengganti Promo)
                    _buildMenuIcon(
                      Icons.local_offer,
                      "Paket",
                      Colors.purple,
                      () => Get.toNamed('/menu', arguments: 'Paket'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. REKOMENDASI (FIX GAMBAR DISINI)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Rekomendasi 🔥",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed('/menu'),
                      child: const Text("Lihat Semua"),
                    ),
                  ],
                ),
              ),

              Obx(() {
                if (productC.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final teaserProducts = productC.products.take(4).toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: teaserProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final product = teaserProducts[index];

                    // --- LOGIKA BARU: CEK GAMBAR ONLINE/LOKAL ---
                    bool isOnline = product.imageUrl.startsWith('http');

                    return GestureDetector(
                      onTap: () =>
                          Get.to(() => ProductDetailPage(product: product)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: isOnline
                                    ? Image.network(
                                        product.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: Colors.grey[200]),
                                      )
                                    : Image.asset(
                                        // Pakai Asset jika lokal
                                        product.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: Colors.grey[200]),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Rp ${product.price.toStringAsFixed(0)}",
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
                  },
                );
              }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
