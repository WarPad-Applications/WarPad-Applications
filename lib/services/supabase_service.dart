import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/product_model.dart';

class SupabaseService extends GetxService {
  late final SupabaseClient client;

  Future<SupabaseService> init() async {
    client = Supabase.instance.client;
    return this;
  }

  // ========================================================================
  // 1. AUTHENTICATION (LOGIN, REGISTER & FCM TOKEN)
  // ========================================================================

  // Fungsi Internal: Update Token Notifikasi ke Database
  Future<void> _updateFcmToken(String userId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await client
            .from('users')
            .update({'fcm_token': token})
            .eq('id', userId);
        print("✅ FCM Token Updated ke Database");
      }
    } catch (e) {
      print("❌ Gagal update token: $e");
    }
  }

  // SIGN UP (DAFTAR)
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String address,
  }) async {
    try {
      // 1. Buat Akun Auth
      final AuthResponse res = await client.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = res.user;

      if (user != null) {
        // 2. Simpan Data Profil ke Tabel 'users'
        await client.from('users').insert({
          'id': user.id,
          'email': email,
          'full_name': fullName,
          'address': address,
        });

        // 3. Update Token FCM
        await _updateFcmToken(user.id);
        return null; // Null artinya Berhasil (Tidak ada error)
      } else {
        return "Gagal mendaftar. Coba lagi.";
      }
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // SIGN IN (MASUK)
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await _updateFcmToken(res.user!.id);
        return null; // Berhasil
      } else {
        return "Login gagal.";
      }
    } catch (e) {
      return "Email atau Password salah!";
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // CEK USER LOGIN SAAT INI (SESSION)
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  // AMBIL PROFIL USER (NAMA, ALAMAT, DLL)
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      print("Error get profile: $e");
      return null;
    }
  }

  // ========================================================================
  // 2. PRODUCTS (MENU MAKANAN)
  // ========================================================================

  // AMBIL SEMUA PRODUK
  Future<List<Product>> fetchProducts() async {
    try {
      final data = await client
          .from('products')
          .select('*')
          .order('created_at');
      if (data == null || data is! List) return [];
      return data.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      print("Fetch Error: $e");
      return [];
    }
  }

  // TAMBAH PRODUK BARU (OPSIONAL)
  Future<Product?> addProduct(Product product) async {
    try {
      final response = await client
          .from('products')
          .insert(product.toJson())
          .select();

      if (response == null || response is! List || response.isEmpty)
        return null;
      return Product.fromJson(response.first);
    } catch (e) {
      print("Add Product Error: $e");
      return null;
    }
  }

  // HAPUS PRODUK (INI YANG TADI HILANG & BIKIN ERROR)
  Future<bool> deleteProduct(String id) async {
    try {
      await client.from('products').delete().eq('id', id);
      return true;
    } catch (e) {
      print("Delete Product Error: $e");
      return false;
    }
  }

  // UPDATE PRODUK (OPSIONAL)
  Future<Product?> updateProduct(Product product) async {
    if (product.id == null) return null;
    try {
      final response = await client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id!)
          .select();

      if (response == null || response is! List || response.isEmpty)
        return null;
      return Product.fromJson(response.first);
    } catch (e) {
      print("Update Product Error: $e");
      return null;
    }
  }

  // ========================================================================
  // 3. ORDERS (TRANSAKSI)
  // ========================================================================

  // BUAT PESANAN BARU
  Future<bool> createOrder({
    required double totalPrice,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      await client.from('orders').insert({
        'user_id': userId,
        'total_price': totalPrice,
        'items': items,
        'delivery_address': deliveryAddress,
        'status': 'Dimasak',
      });
      return true;
    } catch (e) {
      print("Order Error: $e");
      return false;
    }
  }
}
