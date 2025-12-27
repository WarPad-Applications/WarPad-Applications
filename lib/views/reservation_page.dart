import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  // 0 = Form Buat Reservasi, 1 = Info Status
  int _activeTab = 0;

  // Controller Form
  final _formKey = GlobalKey<FormState>();
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final dateC = TextEditingController();
  final timeC = TextEditingController();
  final paxC = TextEditingController();

  // --- VARIABEL MEJA ---
  int? _selectedTable; // GANTI JADI INT (ANGKA)
  List<int> _occupiedTables = []; // Daftar meja yang sudah Approved
  // Kita buat manual 1-10 biar pasti
  final List<int> _allTables = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Get.find<AuthController>().userProfile.value;
    if (user != null) {
      nameC.text = user['full_name'] ?? '';
      phoneC.text = user['phone'] ?? '';
    }
  }

  // --- LOGIKA CEK MEJA KOSONG ---
  Future<void> _checkTableAvailability(String date) async {
    setState(
      () => _isLoading = true,
    ); // Loading sebentar biar user tau lg ngecek

    try {
      final supabase = Get.find<SupabaseService>();

      // Ambil reservasi yang APPROVED di tanggal itu
      final response = await supabase.client
          .from('reservations')
          .select('table_number')
          .eq('date', date)
          .eq('status', 'Approved');

      // Konversi data ke List Integer
      final List<dynamic> data = response as List<dynamic>;
      final List<int> booked = data
          .map((e) => e['table_number'] as int?) // Ambil nomor meja
          .where((e) => e != null) // Buang yang null
          .cast<int>()
          .toList();

      setState(() {
        _occupiedTables = booked;

        // Kalau meja yang dipilih ternyata udah dipake orang, reset pilihan
        if (_selectedTable != null &&
            _occupiedTables.contains(_selectedTable)) {
          _selectedTable = null;
          Get.snackbar(
            "Maaf",
            "Meja yang kamu pilih barusan sudah diambil orang lain.",
          );
        }
      });
    } catch (e) {
      print("Error cek meja: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA KIRIM RESERVASI ---
  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    if (dateC.text.isEmpty) {
      Get.snackbar("Pilih Tanggal", "Harap pilih tanggal kedatangan dulu.");
      return;
    }

    if (_selectedTable == null) {
      Get.snackbar("Pilih Meja", "Silakan pilih nomor meja yang tersedia.");
      return;
    }

    setState(() => _isLoading = true);

    final supabase = Get.find<SupabaseService>();
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;

    if (user == null) {
      Get.snackbar("Error", "Sesi habis, silakan login ulang.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      await supabase.client.from('reservations').insert({
        'user_id': user.id,
        'name': nameC.text,
        'phone': phoneC.text,
        'date': dateC.text,
        'time': timeC.text,
        'pax': int.parse(paxC.text),
        'table_number': _selectedTable, // Kirim Int
        'status': 'Pending',
      });

      Get.snackbar(
        "Sukses",
        "Reservasi dikirim! Cek status di tab Info.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Reset Form
      nameC.clear();
      phoneC.clear();
      dateC.clear();
      timeC.clear();
      paxC.clear();
      setState(() {
        _selectedTable = null;
        _activeTab = 1; // Pindah ke tab status
      });
    } catch (e) {
      Get.snackbar(
        "Gagal",
        "Terjadi kesalahan: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reservasi Meja")),
      body: Column(
        children: [
          // --- TAB BUTTONS ---
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabBtn("Buat Reservasi", 0),
                _buildTabBtn("Info Status", 1),
              ],
            ),
          ),

          // --- KONTEN ---
          Expanded(
            child: _activeTab == 0 ? _buildFormInput() : _buildStatusList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, int index) {
    bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.deepOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  // === TAB 1: FORM ===
  Widget _buildFormInput() {
    // Filter Meja: Yang ADA di _allTables TAPI TIDAK ADA di _occupiedTables
    final availableTables = _allTables
        .where((m) => !_occupiedTables.contains(m))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameC,
              decoration: const InputDecoration(
                labelText: "Nama Pemesan",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneC,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Nomor WhatsApp",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
            ),
            const SizedBox(height: 12),

            // --- TANGGAL (PENTING) ---
            TextFormField(
              controller: dateC,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Tanggal Booking",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                helperText: "Pilih tanggal dulu untuk melihat meja tersedia",
                helperStyle: TextStyle(color: Colors.deepOrange),
              ),
              validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  String formatted = DateFormat('yyyy-MM-dd').format(picked);
                  dateC.text = formatted;
                  // Trigger cek meja
                  await _checkTableAvailability(formatted);
                }
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: timeC,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Jam",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        timeC.text =
                            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: paxC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Jml Orang",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- DROPDOWN MEJA ---
            const Text(
              "Pilih Meja (1-10):",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            // Logika Tampilan Dropdown
            dateC.text.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "📅 Pilih tanggal diatas dulu...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : DropdownButtonFormField<int>(
                    value: _selectedTable,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.table_restaurant),
                    ),
                    hint: const Text("Pilih Nomor Meja Kosong"),
                    // Item Dropdown
                    items: availableTables.map((meja) {
                      return DropdownMenuItem<int>(
                        value: meja,
                        child: Text("Meja $meja"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedTable = val);
                    },
                    validator: (val) => val == null ? "Pilih meja dulu" : null,
                  ),

            if (dateC.text.isNotEmpty && availableTables.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Waduh! Semua meja penuh di tanggal ini.",
                  style: TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "AJUKAN RESERVASI",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === TAB 2: STATUS LIST (Sama seperti sebelumnya) ===
  Widget _buildStatusList() {
    final supabase = Get.find<SupabaseService>();
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;

    if (user == null) {
      return const Center(child: Text("Silakan login dulu"));
    }

    final myStream = supabase.client
        .from('reservations')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at');

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: myStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text("Belum ada riwayat reservasi"),
              ],
            ),
          );
        }

        final data = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            final status = item['status'] ?? 'Pending';

            Color color = Colors.orange;
            String statusText = "Menunggu Konfirmasi";
            IconData icon = Icons.hourglass_empty;

            if (status == 'Approved') {
              color = Colors.green;
              statusText = "DITERIMA ✅";
              icon = Icons.check_circle;
            } else if (status == 'Rejected') {
              color = Colors.red;
              statusText = "DITOLAK ❌";
              icon = Icons.cancel;
            } else if (status == 'Selesai') {
              color = Colors.blue;
              statusText = "SELESAI";
              icon = Icons.done_all;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tgl: ${item['date']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                          child: Row(
                            children: [
                              Icon(icon, size: 14, color: color),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: Text("Jam: ${item['time']}")),
                        Expanded(
                          child: Text("Meja: ${item['table_number'] ?? '-'}"),
                        ),
                        Expanded(child: Text("Org: ${item['pax']}")),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
