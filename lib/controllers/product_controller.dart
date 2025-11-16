import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';

class ProductController extends GetxController {
  final HiveService hiveService = Get.find<HiveService>();
  final SupabaseService supabaseService = Get.find<SupabaseService>();

  var products = <Product>[].obs;
  var isLoading = false.obs;

  // simple cart
  var cart = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  // ===================================================================
  // LOAD PRODUCTS (OFFLINE FIRST)
  // ===================================================================
  Future<void> loadProducts() async {
    isLoading.value = true;

    try {
      // (1) Ambil dari Hive dulu (offline cache)
      final local = hiveService.getProducts();
      products.value = local;

      // (2) Coba sync dari Supabase
      final online = await supabaseService.fetchProducts();
      if (online.isNotEmpty) {
        products.value = online;
        await hiveService.replaceAll(online);
      }
    } catch (e) {
      print("loadProducts error: $e");
    }

    isLoading.value = false;
  }

  // ===================================================================
  // ADD PRODUCT
  // ===================================================================
  Future<void> addProduct(Product p) async {
    isLoading.value = true;

    try {
      // Tambah ke Supabase
      final created = await supabaseService.addProduct(p);

      // Simpan juga ke Hive
      if (created != null) {
        await hiveService.addProduct(created);
        products.add(created);
      } else {
        await hiveService.addProduct(p);
        products.add(p);
      }
    } catch (e) {
      // offline fallback
      await hiveService.addProduct(p);
      products.add(p);
    }

    isLoading.value = false;
  }

  // ===================================================================
  // UPDATE PRODUCT
  // ===================================================================
  Future<void> updateProduct(int index, Product updated) async {
    isLoading.value = true;

    try {
      // update ke supabase jika ada ID
      final updatedOnline = (updated.id != null)
          ? await supabaseService.updateProduct(updated)
          : null;

      if (updatedOnline != null) {
        await hiveService.updateProductAt(index, updatedOnline);
        products[index] = updatedOnline;
      } else {
        await hiveService.updateProductAt(index, updated);
        products[index] = updated;
      }
    } catch (e) {
      // offline fallback
      await hiveService.updateProductAt(index, updated);
      products[index] = updated;
    }

    isLoading.value = false;
  }

  // ===================================================================
  // DELETE PRODUCT
  // ===================================================================
  Future<void> deleteProduct(int index) async {
    final p = products[index];
    isLoading.value = true;

    try {
      // hapus di cloud
      if (p.id != null) {
        await supabaseService.deleteProduct(p.id!);
      }

      // hapus di hive
      await hiveService.deleteProductAt(index);
      products.removeAt(index);
    } catch (e) {
      await hiveService.deleteProductAt(index);
      products.removeAt(index);
    }

    isLoading.value = false;
  }

  // ===================================================================
  // CART SYSTEM
  // ===================================================================
  void addToCart(Product p) {
    cart.add(p);
    Get.snackbar('Sukses', '${p.title} ditambahkan ke keranjang');
  }

  void removeFromCart(int index) {
    cart.removeAt(index);
  }

  void checkout() {
    final total = cart.fold<double>(0, (sum, it) => sum + it.price);
    final count = cart.length;
    cart.clear();

    Get.snackbar(
      'Checkout',
      '$count item — Total: Rp ${total.toStringAsFixed(0)}',
    );
  }
}
