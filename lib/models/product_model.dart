import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class Product {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double price;

  @HiveField(3)
  String imageUrl;

  @HiveField(4)
  String? description;

  @HiveField(5)
  bool isAvailable;

  Product({
    this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.description,
    this.isAvailable = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0,
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      description: json['description'],
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'price': price,
      'image_url': imageUrl,
      'description': description,
      'is_available': isAvailable,
    };
  }
}
