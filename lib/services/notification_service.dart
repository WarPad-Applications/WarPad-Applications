import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Instance Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  // Channel dengan Custom Sound (Dikembalikan dari kode lama)
  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Channel ini untuk notifikasi penting',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          'notif_padang',
        ), // Suara Custom
      );

  Future<void> init() async {
    // 1. Minta Izin Firebase
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _firebaseMessaging.subscribeToTopic('promo');

    // 2. Setup Local Notification & Click Handler
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      // Handler saat notifikasi diklik (Navigasi)
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            Map<String, dynamic> data = jsonDecode(details.payload!);
            _handleMessageData(data);
          } catch (e) {
            debugPrint("Error parsing payload: $e");
          }
        }
      },
    );

    // Create Channel
    final platform = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(_androidChannel);

    // 3. SETUP FIREBASE LISTENERS (FCM)
    // Terminated State
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Background State
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Foreground State (Saat aplikasi dibuka)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        // Tampilkan notifikasi FCM menggunakan helper kita
        showLocalNotification(
          id: notification.hashCode,
          title: notification.title ?? 'Info',
          body: notification.body ?? '',
          payload: jsonEncode(message.data), // Simpan data untuk navigasi
        );
      }
    });

    // 4. SETUP SUPABASE LISTENERS (REALTIME)
    _listenToOrderChanges();
    _listenToReservationChanges();
  }

  // --- SUPABASE REALTIME LOGIC ---

  void _listenToOrderChanges() {
    _supabase.from('orders').stream(primaryKey: ['id']).listen((data) {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      for (var order in data) {
        // Pastikan order milik user yang sedang login
        if (order['user_id'] == currentUser.id) {
          if (order['status'] == 'Selesai') {
            showLocalNotification(
              id: order['id'].hashCode,
              title: "Pesanan Siap! 🍽️",
              body: "Pesanan kamu sudah selesai. Silakan diambil/dinikmati.",
              payload: jsonEncode({'tipe': 'order', 'id': order['id']}),
            );
          }
        }
      }
    });
  }

  void _listenToReservationChanges() {
    _supabase.from('reservations').stream(primaryKey: ['id']).listen((data) {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      for (var res in data) {
        if (res['user_id'] == currentUser.id) {
          if (res['status'] == 'Approved') {
            showLocalNotification(
              id: res['id'].hashCode,
              title: "Reservasi Diterima! ✅",
              body: "Booking meja tgl ${res['date']} sudah di-ACC admin.",
              payload: jsonEncode({'tipe': 'reservation', 'id': res['id']}),
            );
          } else if (res['status'] == 'Rejected') {
            showLocalNotification(
              id: res['id'].hashCode,
              title: "Reservasi Ditolak ❌",
              body: "Maaf, booking meja kamu tidak dapat diproses.",
              payload: jsonEncode({'tipe': 'reservation', 'id': res['id']}),
            );
          }
        }
      }
    });
  }

  // --- HELPER METHODS ---

  // Helper menampilkan notifikasi (Digunakan oleh FCM & Supabase)
  void showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    _localNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          // Menggunakan suara custom
          sound: const RawResourceAndroidNotificationSound('notif_padang'),
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  void _handleMessage(RemoteMessage message) {
    _handleMessageData(message.data);
  }

  // Logika Navigasi (Route Handling)
  void _handleMessageData(Map<String, dynamic> data) {
    // 1. Handle Promo (Dari FCM)
    if (data['tipe'] == 'promo') {
      if (Get.key.currentState == null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleMessageData(data);
        });
        return;
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.to(() => PromoPage(data: data));
      });
    }

    // 2. Bisa ditambahkan handle untuk Order/Reservasi jika perlu
    // else if (data['tipe'] == 'order') { Get.to(...) }
  }
}

// --- HALAMAN PROMO (Tetap dipertahankan) ---
class PromoPage extends StatelessWidget {
  final Map<String, dynamic>? data;
  const PromoPage({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PROMO"), backgroundColor: Colors.red),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text("Kode: ${data?['id_produk'] ?? '-'}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text("Tutup"),
            ),
          ],
        ),
      ),
    );
  }
}
