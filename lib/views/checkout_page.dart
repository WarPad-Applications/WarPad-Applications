import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../controllers/auth_controller.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductController pc = Get.find<ProductController>();
    final AuthController ac = Get.find<AuthController>();
    final promoC = TextEditingController();

    // Controller untuk Catatan / No Meja
    // Default isi dengan Nama User biar gampang
    final noteC = TextEditingController(
      text: ac.userProfile.value?['full_name'] ?? '',
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Konfirmasi Pesanan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TIPE PESANAN & INFO
            const Text(
              "Info Pemesanan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Obx(
                      () => DropdownButtonFormField<String>(
                        value: pc.serviceType.value,
                        // HAPUS DELIVERY DARI SINI
                        items: ['Dine In', 'Takeaway']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => pc.serviceType.value = v!,
                        decoration: const InputDecoration(
                          labelText: "Tipe Pesanan",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // GANTI LABEL ALAMAT JADI CATATAN/MEJA
                    TextFormField(
                      controller: noteC,
                      decoration: const InputDecoration(
                        labelText: "Nomor Meja / Nama Pemesan",
                        hintText: "Contoh: Meja 5 atau Atas Nama Fajar",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. DAFTAR ITEM
            const Text(
              "Item Pesanan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Column(
                children: pc.cartItems
                    .map(
                      (item) => ListTile(
                        title: Text(item.product.title),
                        subtitle: Text(
                          "Rp ${item.product.price.toStringAsFixed(0)}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "x${item.qty.value}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Rp ${(item.product.price * item.qty.value).toStringAsFixed(0)}",
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const Divider(),

            // 3. PROMO
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promoC,
                    decoration: const InputDecoration(hintText: "Kode Promo"),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    pc.promoCode.value = promoC.text;
                    pc.applyPromo();
                  },
                  child: const Text("Pakai"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. TOTAL
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(
                  () => Column(
                    children: [
                      _rowSum("Subtotal", pc.subTotal),
                      _rowSum("Diskon", pc.discountAmount.value, isMinus: true),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TOTAL BAYAR",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "Rp ${pc.grandTotal.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      // --- BAGIAN INI YANG DIREVISI AGAR TIDAK TERLALU BAWAH ---
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 50,
              child: Obx(
                () => ElevatedButton(
                  onPressed: pc.isLoading.value
                      ? null
                      : () {
                          if (noteC.text.isEmpty) {
                            Get.snackbar(
                              "Info Kurang",
                              "Harap isi Nomor Meja / Nama Pemesan",
                            );
                            return;
                          }
                          pc.processCheckout(noteC.text);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  child: pc.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "PESAN SEKARANG",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowSum(String label, double val, {bool isMinus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "${isMinus ? '-' : ''} Rp ${val.toStringAsFixed(0)}",
            style: TextStyle(color: isMinus ? Colors.green : Colors.black),
          ),
        ],
      ),
    );
  }
}
