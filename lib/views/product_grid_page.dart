import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/product_controller.dart';

import '../models/product_model.dart'; 



// Menggunakan StatelessWidget dan GetView<ProductController> tidak diperlukan jika Get.find() digunakan di build.

// Lebih baik menggunakan StatelessWidget sederhana.

class ProductGridPage extends StatelessWidget {

  const ProductGridPage({super.key});



  @override

  Widget build(BuildContext context) {

    // Controller dijamin sudah di-put di main.dart atau di inisiasi lain

    final controller = Get.find<ProductController>();

    final screenWidth = MediaQuery.of(context).size.width;



    return Scaffold(

      appBar: AppBar(

        title: const Text('Nasi Padang Mart'),

        actions: [

          // Tombol Keranjang (Menggunakan Badge yang lebih ringkas)

          Obx(

            () => IconButton(

              icon: Badge(

                label: Text(controller.totalCartItems.value.toString()),

                isLabelVisible: controller.totalCartItems.value > 0,

                child: const Icon(Icons.shopping_cart),

              ),

              onPressed: controller.openCartDialog,

            ),

          ),

        ],

      ),

      body: Column(

        children: [

          // Status Bar

          _buildStatusBar(controller),

          Expanded(

            child: Obx(() {

              if (controller.isLoading.value) {

                return const Center(child: CircularProgressIndicator());

              }



              if (controller.productList.isEmpty) {

                return Center(

                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      const Text('Tidak ada produk yang tersedia.'),

                      const SizedBox(height: 10),

                      if (!controller.isOnline.value)

                        const Text('Anda sedang offline. Cache kosong.', style: TextStyle(color: Colors.red)),

                    ],

                  ),

                );

              }



              return GridView.builder(

                padding: const EdgeInsets.all(8.0),

                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

                  crossAxisCount: controller.calculateCrossAxisCount(screenWidth),

                  childAspectRatio: controller.calculateChildAspectRatio(screenWidth),

                  crossAxisSpacing: 10,

                  mainAxisSpacing: 10,

                ),

                itemCount: controller.productList.length,

                itemBuilder: (context, index) {

                  final product = controller.productList[index];

                  return ProductCard(

                    product: product,

                    controller: controller,

                  );

                },

              );

            }),

          ),

        ],

      ),

      // Tombol Uji CRUD Real-time

      bottomNavigationBar: _buildTestButtons(controller),

    );

  }



  // --- Status Bar (Online/Offline) ---

  Widget _buildStatusBar(ProductController controller) {

    return Obx(() {

      final isOnline = controller.isOnline.value;

      return Container(

        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),

        color: isOnline ? Colors.green.shade100 : Colors.red.shade100,

        child: Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            Row(

              children: [

                Icon(isOnline ? Icons.cloud_done : Icons.cloud_off, size: 20, color: isOnline ? Colors.green.shade900 : Colors.red.shade900),

                const SizedBox(width: 5),

                Text(

                  isOnline ? 'Status: ONLINE' : 'Status: OFFLINE',

                  style: TextStyle(

                    fontWeight: FontWeight.bold,

                    color: isOnline ? Colors.green.shade900 : Colors.red.shade900,

                  ),

                ),

              ],

            ),

            Text(

              'Sinkronisasi Terakhir: ${controller.lastSynced.value}',

              style: const TextStyle(fontSize: 12),

            ),

            // Tombol refresh dihapus karena menggunakan Stream

          ],

        ),

      );

    });

  }



  // --- Tombol Uji CRUD Real-time ---

  Widget _buildTestButtons(ProductController controller) {

    return Obx(() {

      final isOnline = controller.isOnline.value;

      return Padding(

        padding: const EdgeInsets.all(8.0),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            const Divider(),

            const Text(

              'Uji Sinkronisasi Real-time (CRUD)', 

              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), 

              textAlign: TextAlign.center

            ),

            const SizedBox(height: 8),

            Row(

              mainAxisAlignment: MainAxisAlignment.spaceAround,

              children: [

                Expanded(

                  child: ElevatedButton(

                    // Menggantikan runHiveModificationTest

                    onPressed: isOnline ? controller.addTestProduct : null, 

                    style: ElevatedButton.styleFrom(

                      backgroundColor: Colors.green.shade100,

                      disabledBackgroundColor: Colors.grey.shade300,

                    ),

                    child: Text('Tambah (C)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isOnline ? Colors.green : Colors.grey.shade600)),

                  ),

                ),

                const SizedBox(width: 8),

                Expanded(

                  child: ElevatedButton(

                    // Menggantikan runSharedPreferencesTest

                    onPressed: isOnline ? controller.updateFirstProduct : null,

                    style: ElevatedButton.styleFrom(

                      backgroundColor: Colors.blue.shade100,

                      disabledBackgroundColor: Colors.grey.shade300,

                    ),

                    child: Text('Edit Item 1 (U)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isOnline ? Colors.blue : Colors.grey.shade600)),

                  ),

                ),

                const SizedBox(width: 8),

                Expanded(

                  child: ElevatedButton(

                    // Menggantikan runSupabaseInsertTest

                    onPressed: isOnline ? controller.deleteFirstProduct : null,

                    style: ElevatedButton.styleFrom(

                      backgroundColor: Colors.red.shade100,

                      disabledBackgroundColor: Colors.grey.shade300,

                    ),

                    child: Text('Hapus Item 1 (D)', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isOnline ? Colors.red : Colors.grey.shade600)),

                  ),

                ),

              ],

            ),

          ],

        ),

      );

    });

  }

}



class ProductCard extends StatelessWidget {

  final Product product;

  final ProductController controller;



  const ProductCard({

    required this.product,

    required this.controller,

    super.key,

  });



  @override

  Widget build(BuildContext context) {

    // Definisikan URL placeholder yang aman

    const String placeholderUrl = 'https://placehold.co/150x100/EEEEEE/333333?text=NO+IMAGE';



    return GestureDetector( 

      onTap: () => controller.showProductDialog(product),

      child: Card(

        elevation: 4,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            // Gambar Produk (Menggunakan URL produk yang sebenarnya)

            ClipRRect(

              borderRadius: const BorderRadius.only(

                topLeft: Radius.circular(12),

                topRight: Radius.circular(12),

              ),

              child: Image.network(

                // [FIXED] Ganti product.image_url menjadi product.imageUrl 

                // dan gunakan Null Aware Operator (??) untuk fallback

                product.imageUrl ?? placeholderUrl, // Baris 209 di kode asli

                height: 100, 

                width: double.infinity,

                fit: BoxFit.cover,

                errorBuilder: (context, error, stackTrace) {

                  return Container(

                    height: 100,

                    color: Colors.grey.shade200,

                    alignment: Alignment.center,

                    child: const Icon(Icons.broken_image, color: Colors.grey),

                  );

                },

              ),

            ),

            

            // Konten Teks

            Expanded(

              child: Padding(

                padding: const EdgeInsets.all(8.0),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      product.name, 

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(fontWeight: FontWeight.bold),

                    ),

                    const SizedBox(height: 4),

                    Text(

                      controller.formatRupiah(product.price),

                      style: TextStyle(

                          color: Colors.red.shade700, fontWeight: FontWeight.bold),

                    ),



                    const Spacer(),

                    Center(

                      child: OutlinedButton.icon(

                        onPressed: () => controller.addToCart(product),

                        icon: const Icon(Icons.add_shopping_cart, size: 18),

                        label: const Text('Beli', style: TextStyle(fontSize: 12)),

                        style: OutlinedButton.styleFrom(

                          foregroundColor: Colors.brown,

                          side: BorderSide(color: Colors.brown.shade200),

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}