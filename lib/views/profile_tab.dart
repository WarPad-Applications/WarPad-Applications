import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/auth_controller.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authC = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya"), centerTitle: true),
      body: Obx(() {
        if (!authC.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Kamu belum login",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  child: const Text(
                    "Masuk / Daftar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  'https://ui-avatars.com/api/?name=User+WarPad&background=random',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                authC.userProfile.value?['full_name'] ?? 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                authC.userProfile.value?['email'] ?? '-',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                  border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "MEMBER CARD",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    QrImageView(
                      data: authC.userProfile.value?['id'] ?? 'GUEST',
                      version: QrVersions.auto,
                      size: 150.0,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // MENU SETTINGS
              _buildSettingItem(
                Icons.edit,
                "Ubah Nama",
                "Ganti nama profil",
                () => _showEditNameDialog(authC),
              ),
              _buildSettingItem(
                Icons.map,
                "Lokasi Warung",
                "Cek lokasi WarPad",
                () => Get.toNamed('/location'),
              ),
              _buildSettingItem(
                Icons.lock,
                "Ganti Password",
                null,
                () => _showChangePasswordDialog(authC),
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Keluar",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => authC.logout(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  void _showEditNameDialog(AuthController c) {
    final nameC = TextEditingController(
      text: c.userProfile.value?['full_name'],
    );
    Get.defaultDialog(
      title: "Ubah Nama",
      content: TextField(
        controller: nameC,
        decoration: const InputDecoration(labelText: "Nama Lengkap"),
      ),
      textConfirm: "Simpan",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.deepOrange,
      onConfirm: () => c.updateProfile(name: nameC.text),
    );
  }

  void _showChangePasswordDialog(AuthController c) {
    final passC = TextEditingController();
    Get.defaultDialog(
      title: "Ganti Password",
      content: TextField(
        controller: passC,
        obscureText: true,
        decoration: const InputDecoration(labelText: "Password Baru"),
      ),
      textConfirm: "Simpan",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.deepOrange,
      onConfirm: () => c.changePassword(passC.text),
    );
  }
}
