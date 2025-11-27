// path: lib/services/hive_service.dart
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';
import '../models/location_model.dart';

class HiveService extends GetxService {
  static const String productBoxName = "productsBox";
  static const String locationsBoxName = "locationsBox";

  late Box<Product> productsBox;
  late Box<LocationModel> locationsBox;

  Future<HiveService> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(ProductAdapter().typeId)) {
      Hive.registerAdapter(ProductAdapter());
    }
    if (!Hive.isAdapterRegistered(LocationModelAdapter().typeId)) {
      Hive.registerAdapter(LocationModelAdapter());
    }

    productsBox = await Hive.openBox<Product>(productBoxName);
    locationsBox = await Hive.openBox<LocationModel>(locationsBoxName);

    return this;
  }

  // Product helpers
  List<Product> getProducts() => productsBox.values.toList();

  Future<void> replaceAll(List<Product> items) async {
    await productsBox.clear();
    for (var p in items) await productsBox.add(p);
  }

  Future<Product> addProduct(Product product) async {
    final key = await productsBox.add(product);
    return productsBox.getAt(key)!;
  }

  Future<void> updateProductAt(int index, Product product) async =>
      productsBox.putAt(index, product);

  Future<void> deleteProductAt(int index) async => productsBox.deleteAt(index);

  // Location helpers
  Future<void> saveLocation(LocationModel loc) async => locationsBox.add(loc);

  List<LocationModel> getLocations() => locationsBox.values.toList();

  Future<void> clearLocations() async => locationsBox.clear();
}
