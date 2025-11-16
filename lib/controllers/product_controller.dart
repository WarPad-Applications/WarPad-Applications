import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';

class ProductController extends GetxController {
  final HiveService hiveService = Get.find<HiveService>();
  final SupabaseService supabaseService = Get.find<SupabaseService>();

  var products = <Product>[].obs;
  var isLoading = false.obs;

  // simple cart (list of Products)
  var cart = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      // 1) load from Hive (fast)
      final local = hiveService.getProducts();
      products.value = local;

      // 2) try fetch from Supabase and override local cache (if success)
      final online = await supabaseService.fetchProducts();
      if (online.isNotEmpty) {
        products.value = online;
        await hiveService.replaceAll(online);
      }
    } catch (e) {
      print('loadProducts error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(Product p) async {
    isLoading.value = true;
    try {
      // try add to supabase
      final created = await supabaseService.addProduct(p);
      if (created != null) {
        // save to hive
        await hiveService.addProduct(created);
        products.add(created);
      } else {
        // fallback: save locally only
        await hiveService.addProduct(p);
        products.add(p);
      }
    } catch (e) {
      // offline fallback
      await hiveService.addProduct(p);
      products.add(p);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProduct(int index, Product updated) async {
    isLoading.value = true;
    try {
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
      // fallback local update
      await hiveService.updateProductAt(index, updated);
      products[index] = updated;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(int index) async {
    final p = products[index];
    isLoading.value = true;
    try {
      if (p.id != null) {
        await supabaseService.deleteProduct(p.id!);
      }
      await hiveService.deleteProductAt(index);
      products.removeAt(index);
    } catch (e) {
      // in case of error, still remove locally
      await hiveService.deleteProductAt(index);
      products.removeAt(index);
    } finally {
      isLoading.value = false;
    }
  }

  // CART
  void addToCart(Product p) {
    cart.add(p);
    Get.snackbar('Sukses', '${p.title} ditambahkan ke keranjang');
  }

  void removeFromCart(int idx) {
    cart.removeAt(idx);
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
