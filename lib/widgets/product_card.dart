import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String priceLabel;
  const ProductCard({
    super.key,
    required this.product,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    // LOGIKA CERDAS: Cek apakah gambar dari Internet atau Lokal
    bool isOnline = product.imageUrl.startsWith('http');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: null, // Di-handle parent
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: isOnline
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        // REVISI: Tampilkan Path Error jika gagal muat
                        errorBuilder: (ctx, err, stack) =>
                            _buildErrorDebug(product.imageUrl),
                      )
                    : Image.asset(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        // REVISI: Tampilkan Path Error jika gagal muat
                        errorBuilder: (ctx, err, stack) =>
                            _buildErrorDebug(product.imageUrl),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.brown,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DEBUG BARU ---
  // Ini akan menampilkan kotak hitam dengan teks path file yang error
  Widget _buildErrorDebug(String path) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(4),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
            const SizedBox(height: 4),
            const Text(
              "GAGAL MUAT:",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              path, // INI AKAN MENUNJUKKAN PATH YANG SALAH DI LAYAR HP
              style: const TextStyle(color: Colors.white, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
