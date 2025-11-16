import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class SupabaseService extends GetxService {
  late final SupabaseClient client;

  Future<SupabaseService> init() async {
    client = Supabase.instance.client;
    return this;
  }

  Future<List<Product>> fetchProducts() async {
    try {
      final res = await client
          .from('products')
          .select()
          .order('created_at', ascending: false);

      if (res.isEmpty) return [];

      return (res as List)
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print("fetchProducts error: $e");
      return [];
    }
  }

  Future<Product?> addProduct(Product product) async {
    try {
      final response = await client
          .from('products')
          .insert(product.toJson())
          .select()
          .single();

      return Product.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      print("addProduct error: $e");
      return null;
    }
  }

  Future<Product?> updateProduct(Product product) async {
    if (product.id == null || product.id!.isEmpty) {
      throw ArgumentError("Product.id is required");
    }

    try {
      final response = await client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id!)
          .select()
          .single();

      return Product.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      print("updateProduct error: $e");
      return null;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await client.from('products').delete().eq('id', id);
      return true;
    } catch (e) {
      print("deleteProduct error: $e");
      return false;
    }
  }
}
