import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert'; // Tambahkan import ini jika Anda ingin toMap/toJson

part 'product_model.g.dart';

@HiveType(typeId: 0) 
class Product {
  
  @HiveField(0) 
  final int id; 

  @HiveField(1) 
  final String name;
  
  @HiveField(2) 
  final String description;
  
  @HiveField(3) 
  final double price;

  // [PERBAIKAN 1]: Tambahkan field imageUrl yang hilang.
  // Dibuat nullable (String?) agar data dari DB/JSON yang kosong tidak menyebabkan crash.
  @HiveField(4)
  final String? imageUrl; 

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price, 
    // [PERBAIKAN 2]: Ubah parameter 'required String imageUrl' menjadi opsional 
    // (this.imageUrl) karena tipenya String?
    this.imageUrl, 
  });

  // Factory constructor untuk mapping data dari Supabase (JSON)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      // [PERBAIKAN 3]: Menyertakan imageUrl dari JSON map.
      // Menggunakan 'image_url' (snake_case) yang umum dari Supabase.
      imageUrl: json['image_url'] as String?, 
    );
  }

  // Tambahkan toMap() untuk kemudahan pengiriman data ke Supabase (misalnya, saat CRUD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      // Gunakan 'image_url' agar sesuai dengan kolom database Supabase
      'image_url': imageUrl, 
    };
  }
  
  String toJson() => json.encode(toMap());
  
  // Memastikan dua objek dianggap sama berdasarkan ID (penting untuk keranjang)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // [PERBAIKAN 4]: Hapus getter 'String? get imageUrl => null;' 
  // Getter ini tidak diperlukan karena Anda sudah memiliki field final imageUrl.
}