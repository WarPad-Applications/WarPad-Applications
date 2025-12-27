import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../views/admin_dashboard_page.dart'; // Pastikan file ini sudah ada

class AuthController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  // State Variables
  var currentUser = Rxn<User>();
  var userProfile = Rxn<Map<String, dynamic>>();
  var isLoading = false.obs;

  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();

    // 1. Cek User Saat Aplikasi Dibuka
    currentUser.value = _supabaseService.client.auth.currentUser;

    if (isLoggedIn) {
      loadProfile();
      _checkAuthRedirection(); // Cek apakah dia admin (Auto Redirect)
    }

    // 2. Listener Perubahan Auth (Login/Logout)
    _supabaseService.client.auth.onAuthStateChange.listen((data) {
      currentUser.value = data.session?.user;
      if (currentUser.value != null) {
        loadProfile();
      } else {
        userProfile.value = null;
      }
    });
  }

  // --- HELPER: CEK ROLE OTOMATIS SAAT APP DIBUKA ---
  Future<void> _checkAuthRedirection() async {
    // Beri jeda sedikit agar splash screen selesai
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      if (currentUser.value == null) return;

      final uid = currentUser.value!.id;
      final data = await _supabaseService.client
          .from('users')
          .select('role')
          .eq('id', uid)
          .single();

      String role = data['role'] ?? 'user';

      if (role == 'admin') {
        Get.offAll(() => const AdminDashboardPage());
      }
      // Kalau user biasa, biarkan di halaman utama (Dashboard)
    } catch (_) {
      // Ignore error jika gagal cek role
    }
  }

  // --- LOAD PROFIL USER ---
  Future<void> loadProfile() async {
    userProfile.value = await _supabaseService.getUserProfile();
  }

  // ==========================================================
  // 1. AUTHENTICATION (LOGIN & REGISTER)
  // ==========================================================

  // REGISTER (DAFTAR)
  Future<void> register(
    String email,
    String password,
    String name,
    String address,
  ) async {
    isLoading.value = true;
    String? error = await _supabaseService.signUp(
      email: email,
      password: password,
      fullName: name,
      address: address,
    );
    isLoading.value = false;

    if (error != null) {
      Get.snackbar("Gagal Daftar", error);
    } else {
      Get.snackbar("Sukses", "Akun berhasil dibuat! Silakan login.");
    }
  }

  // LOGIN (MASUK) - DENGAN CEK ROLE
  Future<void> login(String email, String password) async {
    isLoading.value = true;

    // 1. Login ke Supabase Auth
    String? error = await _supabaseService.signIn(
      email: email,
      password: password,
    );

    if (error != null) {
      isLoading.value = false;
      Get.snackbar("Gagal Login", error);
      return;
    }

    // 2. Cek Role Admin/User di Database
    try {
      final uid = _supabaseService.client.auth.currentUser!.id;
      final data = await _supabaseService.client
          .from('users')
          .select('role')
          .eq('id', uid)
          .single();

      String role = data['role'] ?? 'user';
      isLoading.value = false;

      if (role == 'admin') {
        Get.snackbar("Halo Chef!", "Selamat bekerja di Dapur");
        Get.offAll(() => const AdminDashboardPage());
      } else {
        Get.snackbar("Halo!", "Selamat datang kembali");
        Get.offAllNamed('/'); // Ke Halaman User
      }
    } catch (e) {
      isLoading.value = false;
      // Fallback jika gagal cek role, anggap user biasa
      Get.offAllNamed('/');
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _supabaseService.signOut();
    Get.offAllNamed('/login'); // Kembali ke Login
  }

  // ==========================================================
  // 2. PROFILE MANAGEMENT (UPDATE & PASSWORD)
  // ==========================================================

  // UPDATE PROFIL
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final uid = currentUser.value!.id;
      final updates = <String, dynamic>{};

      if (name != null && name.isNotEmpty) updates['full_name'] = name;
      if (address != null && address.isNotEmpty) updates['address'] = address;

      await _supabaseService.client.from('users').update(updates).eq('id', uid);
      await loadProfile(); // Refresh tampilan

      Get.back(); // Tutup Dialog
      Get.snackbar("Sukses", "Profil berhasil diperbarui");
    } catch (e) {
      Get.snackbar("Error", "Gagal update profil");
    }
  }

  // GANTI PASSWORD
  Future<void> changePassword(String newPassword) async {
    try {
      await _supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      Get.back(); // Tutup Dialog
      Get.snackbar("Sukses", "Password berhasil diganti");
    } catch (e) {
      Get.snackbar("Error", "Gagal ganti password: $e");
    }
  }
}
