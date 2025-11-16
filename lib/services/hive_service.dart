import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';

class HiveService extends GetxService {
  static const String productBoxName = "productsBox";
  late Box<Product> productsBox;

  Future<HiveService> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(ProductAdapter().typeId)) {
      Hive.registerAdapter(ProductAdapter());
    }
    productsBox = await Hive.openBox<Product>(productBoxName);

    // Jika kosong, jangan otomatis masukkan—kecuali mau. (Opsional)
    return this;
  }

  List<Product> getProducts() {
    return productsBox.values.toList();
  }

  Future<void> replaceAll(List<Product> items) async {
    await productsBox.clear();
    // ensure we store items with their id (some may be null)
    for (var p in items) {
      await productsBox.add(p);
    }
  }

  Future<Product> addProduct(Product product) async {
    // Jika id == null (belum dari Supabase), fine — disimpan di Hive dulu.
    final key = await productsBox.add(product);
    final stored = productsBox.getAt(key)!;
    return stored;
  }

  Future<void> updateProductAt(int index, Product product) async {
    await productsBox.putAt(index, product);
  }

  Future<void> deleteProductAt(int index) async {
    await productsBox.deleteAt(index);
  }
}
