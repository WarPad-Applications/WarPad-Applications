// path: lib/services/supabase_service.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class SupabaseService extends GetxService {
  late final SupabaseClient client;

  Future<SupabaseService> init() async {
    client = Supabase.instance.client;
    return this;
  }

  // ============================
  // FETCH PRODUCTS
  // ============================
  Future<List<Product>> fetchProducts() async {
    try {
      final data = await client.from('products').select('*');

      if (data == null || data is! List) {
        return [];
      }

      return data
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print("fetchProducts error: $e");
      return [];
    }
  }

  // ============================
  // INSERT PRODUCT
  // ============================
  Future<Product?> addProduct(Product product) async {
    try {
      final response = await client
          .from('products')
          .insert(product.toJson())
          .select();

      if (response == null || response is! List || response.isEmpty) {
        return null;
      }

      final map = Map<String, dynamic>.from(response.first);
      return Product.fromJson(map);
    } catch (e) {
      print("addProduct error: $e");
      return null;
    }
  }

  // ============================
  // UPDATE PRODUCT
  // ============================
  Future<Product?> updateProduct(Product product) async {
    if (product.id == null) {
      throw ArgumentError("Product id is required for update");
    }

    try {
      final response = await client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id as String)
          .select();

      if (response == null || response is! List || response.isEmpty) {
        return null;
      }

      final map = Map<String, dynamic>.from(response.first);
      return Product.fromJson(map);
    } catch (e) {
      print("updateProduct error: $e");
      return null;
    }
  }

  // ============================
  // DELETE PRODUCT
  // ============================
  Future<bool> deleteProduct(String id) async {
    try {
      await client.from('products').delete().eq('id', id);
      return true;
    } catch (e) {
      print("deleteProduct error: $e");
      return false;
    }
  }

  // ============================
  // INSERT LOCATION (MODUL 5)
  // ============================
  Future<void> insertLocation(
    String userId,
    double lat,
    double lng,
    double accuracy,
  ) async {
    try {
      await client.from('locations').insert({
        'user_id': userId,
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
      });
    } catch (e) {
      print("insertLocation error: $e");
    }
  }
}
