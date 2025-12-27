import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import 'reservation_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _reservationSubTab = 0;
  int _historySubTab = 0;

  @override
  Widget build(BuildContext context) {
    final supabase = Get.find<SupabaseService>();
    final authC = Get.find<AuthController>();
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Dashboard Owner"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [
            IconButton(
              onPressed: () => authC.logout(),
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: "Logout",
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepOrange,
            tabs: [
              Tab(text: "Pesanan Masuk"),
              Tab(text: "Reservasi"),
              Tab(text: "Riwayat"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(supabase, currency, activeOnly: true),
            _buildReservationSection(supabase),
            _buildHistorySection(supabase, currency),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepOrange,
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: "Buat Reservasi Manual",
          onPressed: () => Get.to(() => const ReservationPage()),
        ),
      ),
    );
  }

  // --- TAB 2: RESERVASI ---
  Widget _buildReservationSection(SupabaseService s) {
    return Column(
      children: [
        _buildToggleBtn(
          labels: ["Permintaan Masuk", "Info Meja Booking"],
          selectedIndex: _reservationSubTab,
          onChanged: (val) => setState(() => _reservationSubTab = val),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: s.client
                .from('reservations')
                .stream(primaryKey: ['id'])
                .order('date'),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final allData = snapshot.data!;
              final data = _reservationSubTab == 0
                  ? allData.where((r) => r['status'] == 'Pending').toList()
                  : allData.where((r) => r['status'] == 'Approved').toList();

              if (data.isEmpty) {
                return _buildEmptyState(
                  _reservationSubTab == 0
                      ? Icons.notifications_off
                      : Icons.table_restaurant,
                  _reservationSubTab == 0
                      ? "Tidak ada permintaan baru"
                      : "Belum ada meja dibooking",
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.length,
                itemBuilder: (context, index) =>
                    _buildReservationCard(s, data[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 3: RIWAYAT ---
  Widget _buildHistorySection(SupabaseService s, NumberFormat currency) {
    return Column(
      children: [
        _buildToggleBtn(
          labels: ["Riwayat Pesanan", "Riwayat Reservasi"],
          selectedIndex: _historySubTab,
          onChanged: (val) => setState(() => _historySubTab = val),
        ),
        Expanded(
          child: _historySubTab == 0
              ? _buildOrderList(s, currency, activeOnly: false)
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: s.client
                      .from('reservations')
                      .stream(primaryKey: ['id'])
                      .order('date', ascending: false),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final data = snapshot.data!
                        .where(
                          (r) =>
                              r['status'] == 'Rejected' ||
                              r['status'] == 'Selesai',
                        )
                        .toList();
                    if (data.isEmpty)
                      return _buildEmptyState(
                        Icons.history,
                        "Belum ada riwayat reservasi",
                      );
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.length,
                      itemBuilder: (context, index) => _buildReservationCard(
                        s,
                        data[index],
                        isHistory: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- BUILDER ORDER ---
  Widget _buildOrderList(
    SupabaseService s,
    NumberFormat currency, {
    required bool activeOnly,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: s.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final allOrders = snapshot.data!;
        final orders = activeOnly
            ? allOrders
                  .where(
                    (o) =>
                        o['status'] != 'Selesai' && o['status'] != 'Dibatalkan',
                  )
                  .toList()
            : allOrders
                  .where(
                    (o) =>
                        o['status'] == 'Selesai' || o['status'] == 'Dibatalkan',
                  )
                  .toList();

        if (orders.isEmpty) {
          return _buildEmptyState(
            activeOnly ? Icons.soup_kitchen : Icons.history,
            activeOnly
                ? "Tidak ada pesanan aktif"
                : "Belum ada riwayat pesanan",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
            final status = order['status'] ?? 'Proses';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                initiallyExpanded: activeOnly,
                leading: CircleAvatar(
                  backgroundColor: activeOnly
                      ? Colors.orange
                      : (status == 'Selesai' ? Colors.green : Colors.red),
                  child: Icon(Icons.receipt, color: Colors.white),
                ),
                title: Text(
                  "Info: ${order['delivery_address']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Total: ${currency.format(order['total_price'])} • $status",
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...items.map(
                          (i) => Text(
                            "${i['qty']}x ${i['title']} (${currency.format(i['price'])})",
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (activeOnly)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  // --- TOMBOL TOLAK ORDER DENGAN FEEDBACK ---
                                  onPressed: () async {
                                    try {
                                      await s.client
                                          .from('orders')
                                          .update({'status': 'Dibatalkan'})
                                          .eq('id', order['id']);
                                      Get.snackbar(
                                        "Dibatalkan",
                                        "Pesanan ditolak ❌",
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    } catch (e) {
                                      Get.snackbar(
                                        "Gagal",
                                        "Error: $e",
                                        backgroundColor: Colors.black,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text("TOLAK / BATAL"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  // --- TOMBOL SELESAI ORDER DENGAN FEEDBACK ---
                                  onPressed: () async {
                                    try {
                                      await s.client
                                          .from('orders')
                                          .update({'status': 'Selesai'})
                                          .eq('id', order['id']);
                                      Get.snackbar(
                                        "Berhasil",
                                        "Pesanan Selesai & Notifikasi Terkirim ✅",
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                    } catch (e) {
                                      Get.snackbar(
                                        "Gagal",
                                        "Error: $e",
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("SELESAI"),
                                ),
                              ),
                            ],
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
  }

  // --- BUILDER RESERVASI ---
  Widget _buildReservationCard(
    SupabaseService s,
    Map<String, dynamic> res, {
    bool isHistory = false,
  }) {
    final status = res['status'];
    Color color = status == 'Approved'
        ? Colors.green
        : (status == 'Pending'
              ? Colors.orange
              : (status == 'Selesai' ? Colors.blue : Colors.red));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  res['name'] ?? 'Guest',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text("${res['date']} jam ${res['time']}"),
                const Spacer(),
                Icon(Icons.people, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text("${res['pax']} Orang"),
              ],
            ),
            if (!isHistory) ...[
              const Divider(height: 24),
              if (status == 'Pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        // --- TOMBOL TOLAK RESERVASI ---
                        onPressed: () async {
                          try {
                            await s.client
                                .from('reservations')
                                .update({'status': 'Rejected'})
                                .eq('id', res['id']);
                            Get.snackbar(
                              "Ditolak",
                              "Reservasi ditolak ❌",
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          } catch (e) {
                            Get.snackbar(
                              "Gagal",
                              "Error: $e",
                              backgroundColor: Colors.black,
                              colorText: Colors.white,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("TOLAK"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        // --- TOMBOL ACC RESERVASI ---
                        onPressed: () async {
                          try {
                            await s.client
                                .from('reservations')
                                .update({'status': 'Approved'})
                                .eq('id', res['id']);
                            Get.snackbar(
                              "Diterima",
                              "Reservasi di-ACC ✅",
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } catch (e) {
                            Get.snackbar(
                              "Gagal",
                              "Error: $e",
                              backgroundColor: Colors.black,
                              colorText: Colors.white,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("ACC RESERVASI"),
                      ),
                    ),
                  ],
                ),
              if (status == 'Approved')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    // --- TOMBOL SELESAI RESERVASI ---
                    onPressed: () async {
                      try {
                        await s.client
                            .from('reservations')
                            .update({'status': 'Selesai'})
                            .eq('id', res['id']);
                        Get.snackbar(
                          "Selesai",
                          "Meja kosong kembali ✅",
                          backgroundColor: Colors.blue,
                          colorText: Colors.white,
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Gagal",
                          "Error: $e",
                          backgroundColor: Colors.black,
                          colorText: Colors.white,
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Tamu Pulang (Selesai)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn({
    required List<String> labels,
    required int selectedIndex,
    required Function(int) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          bool isActive = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.deepOrange : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: index == 0 ? const Radius.circular(11) : Radius.zero,
                    right: index == labels.length - 1
                        ? const Radius.circular(11)
                        : Radius.zero,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
