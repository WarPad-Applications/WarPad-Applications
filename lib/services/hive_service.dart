import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';
import '../models/location_model.dart';
import '../models/user_model.dart'; // Jangan lupa import ini

class HiveService extends GetxService {
  static const String productBoxName = "productsBox";
  static const String locationsBoxName = "locationsBox";
  static const String userBoxName = "userBox"; // Box Baru

  late Box<Product> productsBox;
  late Box<LocationModel> locationsBox;
  late Box<UserModel> userBox; // Box Baru

  Future<HiveService> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(LocationModelAdapter());
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(UserModelAdapter()); // Adapter User

    // Open Boxes
    productsBox = await Hive.openBox<Product>(productBoxName);
    locationsBox = await Hive.openBox<LocationModel>(locationsBoxName);
    userBox = await Hive.openBox<UserModel>(userBoxName); // Buka Box User

    return this;
  }

  // --- PRODUCT HELPERS ---
  List<Product> getProducts() => productsBox.values.toList();

  Future<void> replaceAll(List<Product> items) async {
    await productsBox.clear();
    for (var p in items) await productsBox.add(p);
  }

  Future<void> addProduct(Product p) async => await productsBox.add(p);
  Future<void> updateProductAt(int index, Product p) async =>
      productsBox.putAt(index, p);
  Future<void> deleteProductAt(int index) async => productsBox.deleteAt(index);

  // --- LOCATION HELPERS ---
  Future<void> saveLocation(LocationModel loc) async => locationsBox.add(loc);
  List<LocationModel> getLocations() => locationsBox.values.toList();

  // --- USER HELPERS (LOGIN CACHE) ---
  UserModel? getUser() {
    if (userBox.isEmpty) return null;
    return userBox.getAt(0);
  }

  Future<void> saveUser(UserModel user) async {
    await userBox.clear();
    await userBox.add(user);
  }

  Future<void> clearUser() async {
    await userBox.clear();
  }
}
