import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_page.dart';
import 'product_grid_page.dart';
import 'order_history_page.dart'; // Import Halaman Riwayat
import 'profile_tab.dart'; // Import Halaman Profil

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Daftar Halaman Utama
  final List<Widget> _pages = [
    const HomePage(), // 0: Beranda
    const ProductGridPage(), // 1: Menu (Makanan/Minuman)
    const OrderHistoryPage(), // 2: Pesanan (Riwayat) -> SUDAH ADA
    const ProfileTab(), // 3: Profil (QR & Settings) -> SUDAH ADA
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        indicatorColor: Colors.deepOrange.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.deepOrange),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu, color: Colors.deepOrange),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Colors.deepOrange),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.deepOrange),
            label: 'Saya',
          ),
        ],
      ),
    );
  }
}
