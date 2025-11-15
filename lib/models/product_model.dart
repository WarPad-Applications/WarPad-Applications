// Lokasi: lib/models/product_model.dart

class Product {
  final int? id; // Wajib ada untuk database
  final String title;
  final int price;
  final String imageUrl;

  Product({
    this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  // Fungsi untuk mengubah Objek Product menjadi Map (untuk disimpan ke DB)
  Map<String, dynamic> toMap() {
    return {'title': title, 'price': price, 'imageUrl': imageUrl};
  }

  // Fungsi untuk mengubah Map (dari DB) menjadi Objek Product
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      price: map['price']?.toInt() ?? 0,
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
