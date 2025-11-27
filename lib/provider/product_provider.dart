// path: lib/provider/product_provider.dart
import 'package:get/get.dart';
import '../models/product_model.dart';

class ProductProvider extends GetxService {
  Future<List<Product>> fetchMockProducts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      Product(
        title: 'Nasi Padang A',
        price: 15000,
        imageUrl: 'https://via.placeholder.com/400',
        description: 'Lezat.',
      ),
      Product(
        title: 'Nasi Padang B',
        price: 20000,
        imageUrl: 'https://via.placeholder.com/400',
        description: 'Mantap.',
      ),
    ];
  }
}
