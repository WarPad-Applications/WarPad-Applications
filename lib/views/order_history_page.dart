import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal/uang
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Get.find<SupabaseService>();
    final auth = Get.find<AuthController>();
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Pesanan"), centerTitle: true),
      // [REVISI] Bungkus dengan Obx agar reaktif terhadap status login
      body: Obx(() {
        // 1. CEK STATUS LOGIN
        if (!auth.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  "Silakan Login untuk melihat pesanan",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  child: const Text(
                    "Login Sekarang",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        // 2. JIKA SUDAH LOGIN, AMBIL DATA
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: supabase.client
              .from('orders')
              .select()
              .eq('user_id', auth.currentUser.value!.id) // ID User pasti ada
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final data = snapshot.data ?? [];

            if (data.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "Belum ada pesanan",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final order = data[index];
                final items = List<Map<String, dynamic>>.from(
                  order['items'] ?? [],
                );

                // Parsing Tanggal dengan aman
                DateTime date;
                try {
                  date = DateTime.parse(order['created_at']).toLocal();
                } catch (_) {
                  date = DateTime.now();
                }
                final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(date);

                // Tentukan Warna Status
                Color statusColor = Colors.orange;
                if (order['status'] == 'Selesai') statusColor = Colors.green;
                if (order['status'] == 'Dibatalkan') statusColor = Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(Icons.restaurant, color: statusColor),
                    ),
                    title: Text(
                      currency.format(order['total_price']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order['status'] ?? 'Proses',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey[50],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rincian Pesanan:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...items.map(
                              (item) => Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${item['qty']}x ${item['title']}"),
                                  Text(
                                    currency.format(
                                      (item['price'] ?? 0) * (item['qty'] ?? 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            Text(
                              "Info: ${order['delivery_address'] ?? '-'}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}
