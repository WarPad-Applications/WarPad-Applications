import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import 'auth_controller.dart';

class CartItem {
  final Product product;
  RxInt qty;
  CartItem({required this.product, required int initialQty})
    : qty = initialQty.obs;
}

class ProductController extends GetxController {
  final HiveService hiveService = Get.find<HiveService>();
  final SupabaseService supabaseService = Get.find<SupabaseService>();
  AuthController get authController => Get.find<AuthController>();

  var products = <Product>[].obs;
  var isLoading = false.obs;

  // --- LOGIC MENU SCROLL ---
  final ScrollController menuScrollController = ScrollController();
  var activeTab = 'Makanan'.obs;

  // --- LOGIC CART ---
  var cartItems = <CartItem>[].obs;

  // --- LOGIC CHECKOUT ---
  var serviceType = 'Dine In'.obs;
  var promoCode = ''.obs;
  var discountAmount = 0.0.obs;
  var appliedPromoName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();

    // --- LISTENER SCROLL ---
    menuScrollController.addListener(() {
      double offset = menuScrollController.offset;

      // Estimasi tinggi per section (Header 60 + Item Grid ~260)
      double itemHeight = 260.0;
      double headerHeight = 60.0;

      int makananCount = products.where((p) => p.category == 'Makanan').length;
      int minumanCount = products.where((p) => p.category == 'Minuman').length;
      int paketCount = products.where((p) => p.category == 'Paket').length;

      // Hitung batas tinggi untuk setiap kategori
      double hMakanan = (makananCount / 2).ceil() * itemHeight + headerHeight;
      double hMinuman = (minumanCount / 2).ceil() * itemHeight + headerHeight;
      double hPaket = (paketCount / 2).ceil() * itemHeight + headerHeight;

      if (offset < hMakanan) {
        activeTab.value = 'Makanan';
      } else if (offset < hMakanan + hMinuman) {
        activeTab.value = 'Minuman';
      } else if (offset < hMakanan + hMinuman + hPaket) {
        activeTab.value = 'Paket';
      } else {
        activeTab.value = 'Promo';
      }
    });
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      final online = await supabaseService.fetchProducts();
      if (online.isNotEmpty) {
        products.value = online;
        await hiveService.replaceAll(online);
      } else {
        products.value = hiveService.getProducts();
      }
    } catch (_) {
      products.value = hiveService.getProducts();
    }
    isLoading.value = false;
  }

  // --- SCROLL TO SECTION ---
  void scrollToSection(String category) {
    activeTab.value = category;

    double itemHeight = 260.0;
    double headerHeight = 60.0;

    int makananCount = products.where((p) => p.category == 'Makanan').length;
    int minumanCount = products.where((p) => p.category == 'Minuman').length;
    int paketCount = products.where((p) => p.category == 'Paket').length;

    double hMakanan = (makananCount / 2).ceil() * itemHeight + headerHeight;
    double hMinuman = (minumanCount / 2).ceil() * itemHeight + headerHeight;
    double hPaket = (paketCount / 2).ceil() * itemHeight + headerHeight;

    double target = 0;
    if (category == 'Makanan') target = 0;
    if (category == 'Minuman') target = hMakanan;
    if (category == 'Paket') target = hMakanan + hMinuman;
    if (category == 'Promo') target = hMakanan + hMinuman + hPaket;

    if (menuScrollController.hasClients) {
      menuScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- CART FUNCTIONS (REVISI DISINI) ---
  // Return true jika berhasil masuk keranjang
  // Return false jika user belum login
  bool addToCart(Product p) {
    if (!authController.isLoggedIn) {
      Get.snackbar("Akses Ditolak", "Silakan Login terlebih dahulu");
      Get.toNamed('/login'); // Arahkan ke Login
      return false; // Gagal
    }

    var existing = cartItems.firstWhereOrNull(
      (element) => element.product.id == p.id,
    );
    if (existing != null) {
      existing.qty.value++;
    } else {
      cartItems.add(CartItem(product: p, initialQty: 1));
    }
    Get.snackbar('Sukses', '${p.title} ditambahkan ke keranjang');
    return true; // Berhasil
  }

  void decreaseQty(CartItem item) {
    if (item.qty.value > 1) {
      item.qty.value--;
    } else {
      cartItems.remove(item);
    }
  }

  void increaseQty(CartItem item) => item.qty.value++;

  double get subTotal => cartItems.fold(
    0,
    (sum, item) => sum + (item.product.price * item.qty.value),
  );

  double get deliveryCost => 0.0;

  double get grandTotal => subTotal - discountAmount.value;

  // --- LOGIC PROMO ---
  void applyPromo() {
    discountAmount.value = 0;
    appliedPromoName.value = '';

    String code = promoCode.value.toUpperCase().trim();
    double total = subTotal;
    int day = DateTime.now().day;

    if (code == 'TANGGALTUA') {
      if (day >= 20) {
        discountAmount.value = total * 0.15;
        appliedPromoName.value = "Promo Tanggal Tua (-15%)";
      } else {
        Get.snackbar("Gagal", "Promo ini hanya aktif tanggal 20 ke atas!");
      }
    } else if (code == 'MAHASISWA') {
      discountAmount.value = total * 0.10;
      appliedPromoName.value = "Promo Mahasiswa (-10%)";
    } else if (code == 'MEMBER') {
      discountAmount.value = 5000;
      appliedPromoName.value = "Potongan Member (-Rp 5.000)";
    } else {
      Get.snackbar("Gagal", "Kode promo tidak ditemukan");
    }
  }

  Future<void> processCheckout(String note) async {
    isLoading.value = true;
    final itemsJson = cartItems
        .map(
          (e) => {
            'title': e.product.title,
            'price': e.product.price,
            'qty': e.qty.value,
          },
        )
        .toList();

    String finalAddressInfo = "${serviceType.value} - $note";

    bool success = await supabaseService.createOrder(
      totalPrice: grandTotal,
      items: itemsJson,
      deliveryAddress: finalAddressInfo,
    );

    isLoading.value = false;
    if (success) {
      cartItems.clear();
      Get.offAllNamed('/');
      Get.snackbar("Order Berhasil", "Silakan tunggu dipanggil");
    } else {
      Get.snackbar("Gagal", "Terjadi kesalahan server");
    }
  }
}
