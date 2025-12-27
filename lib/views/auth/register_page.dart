import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class RegisterPage extends GetView<AuthController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();
    final addressC = TextEditingController(); // PENTING BUAT ONGKIR

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Buat Akun Baru"), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Lengkapi Data Diri",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Biar nggak salah panggil.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                _buildLabel("Nama Lengkap"),
                _buildInput(nameC, "Contoh: Budi Santoso", false),

                _buildLabel("Email"),
                _buildInput(emailC, "user@example.com", false),

                _buildLabel("Password"),
                _buildInput(passC, "******", true),

                _buildLabel("Alamat Pengiriman (Wajib)"),
                _buildInput(
                  addressC,
                  "Jl. Mawar No. 12, Malang",
                  false,
                  maxLines: 3,
                ),

                const SizedBox(height: 30),

                // TOMBOL DAFTAR
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              if (nameC.text.isEmpty ||
                                  emailC.text.isEmpty ||
                                  passC.text.isEmpty ||
                                  addressC.text.isEmpty) {
                                Get.snackbar(
                                  "Error",
                                  "Semua kolom wajib diisi!",
                                );
                              } else {
                                controller.register(
                                  emailC.text,
                                  passC.text,
                                  nameC.text,
                                  addressC.text,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "DAFTAR AKUN",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInput(
    TextEditingController c,
    String hint,
    bool isPass, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      obscureText: isPass,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
