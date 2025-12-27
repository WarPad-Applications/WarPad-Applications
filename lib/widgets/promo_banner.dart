import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Tambahkan field 'target' untuk navigasi
    final List<Map<String, dynamic>> promos = [
      {
        "color": Colors.redAccent,
        "title": "DISKON 50%",
        "subtitle": "Khusus Rendang Sapi",
        "target": "Makanan",
      },
      {
        "color": Colors.orange,
        "title": "GRATIS ONGKIR",
        "subtitle": "Min. Belanja 50rb",
        "target": "Paket",
      },
      {
        "color": Colors.green,
        "title": "PAKET HEMAT",
        "subtitle": "Nasi + Ayam + Teh",
        "target": "Promo",
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 160.0,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.85,
        aspectRatio: 16 / 9,
      ),
      items: promos.map((promo) {
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              // NAVIGASI SAAT KLIK BANNER
              onTap: () {
                Get.toNamed('/menu', arguments: promo['target']);
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  color: promo['color'],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // BACKGROUND ICON
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.fastfood,
                        size: 120,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),

                    // KONTEN TEKS (DIBUNGKUS FittedBox AGAR AMAN)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: FittedBox(
                        // <--- SOLUSI OVERFLOW
                        fit: BoxFit.scaleDown, // Hanya mengecilkan jika kepepet
                        alignment: Alignment.centerLeft, // Rata kiri
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              promo['title'],
                              style: const TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              promo['subtitle'],
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Lihat Promo",
                                style: TextStyle(
                                  color: promo['color'],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
