// Lokasi: lib/services/notification_service.dart

import 'dart:convert'; // Untuk decode json
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

// Service utama untuk menangani notifikasi
class NotificationService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Setup Channel Notifikasi Android (Agar bunyi custom)
  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
        'high_importance_channel', // ID Channel
        'High Importance Notifications', // Nama Channel
        description: 'Channel ini untuk notifikasi penting',
        importance: Importance.max,
        playSound: true,
        // Pastikan file 'notif_padang.mp3' ada di android/app/src/main/res/raw/
        sound: RawResourceAndroidNotificationSound('notif_padang'),
      );

  Future<void> init() async {
    // 1. Minta Izin Notifikasi
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Local Notification
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      // LOGIKA SAAT NOTIFIKASI DIKLIK (Posisi Foreground)
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            Map<String, dynamic> data = jsonDecode(details.payload!);
            _handleMessageData(data);
          } catch (e) {
            print("Error parsing payload: $e");
          }
        }
      },
    );

    // Buat Channel di Android System
    final platform = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(_androidChannel);

    // 3. HANDLER SAAT TERMINATED (Aplikasi Mati Total)
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 4. HANDLER SAAT BACKGROUND (Aplikasi Di-minimize)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 5. HANDLER SAAT FOREGROUND (Aplikasi Sedang Dibuka)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      // Tampilkan banner notifikasi manual
      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              sound: const RawResourceAndroidNotificationSound('notif_padang'),
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // --- CETAK TOKEN AGAR BISA DITEST ---
    final fcmToken = await _firebaseMessaging.getToken();
    print('=======================================');
    print('FCM TOKEN SAYA: $fcmToken');
    print('=======================================');
  }

  void _handleMessage(RemoteMessage message) {
    _handleMessageData(message.data);
  }

  // --- LOGIKA NAVIGASI PINTAR (DENGAN RETRY) ---
  void _handleMessageData(Map<String, dynamic> data) {
    print("🔔 MENGECEK DATA NAVIGASI: $data");

    if (data['tipe'] == 'promo') {
      // Cek apakah Navigator (GetX) sudah siap?
      if (Get.key.currentState == null) {
        print("⏳ Navigator belum siap... Menunggu 1 detik.");
        // Jika belum siap, tunggu 1 detik lalu coba lagi
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleMessageData(data);
        });
        return;
      }

      print("✅ Navigator SIAP! Pindah ke Promo Page...");
      // Jeda sedikit agar transisi mulus
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.to(() => PromoPage(data: data));
      });
    } else {
      print("❌ Tipe bukan 'promo' atau data kosong. Stay di Home.");
    }
  }
}

// --- HALAMAN PROMO (Langsung di sini) ---
class PromoPage extends StatelessWidget {
  final Map<String, dynamic>? data;

  const PromoPage({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PROMO SPESIAL"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_offer_rounded,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                "Selamat! Kamu Dapat Promo!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Tunjukkan layar ini ke kasir"),
              const SizedBox(height: 30),
              // Menampilkan data
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    // MENGGUNAKAN 'id_produk'
                    Text(
                      "Kode Produk: ${data?['id_produk'] ?? '-'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Text("Tipe Pesan: ${data?['tipe'] ?? '-'}"),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text("Kembali Belanja"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
