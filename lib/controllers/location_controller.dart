// path: lib/controllers/location_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
// import '../services/hive_service.dart'; // Uncomment jika sudah ada
// import '../models/location_model.dart'; // Uncomment jika sudah ada
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationController extends GetxController {
  final LocationService _service = LocationService();

  final Rxn<Position> currentPosition = Rxn<Position>();
  final isLoading = false.obs;
  final isTracking = false.obs;
  final isGpsEnabled = true.obs;
  final distanceFilter = 5.obs; // in meters

  final MapController mapController = MapController();

  StreamSubscription<Position>? _sub;

  @override
  void onInit() {
    super.onInit();
    _initLastKnown();
  }

  Future<void> _initLastKnown() async {
    try {
      final pos = await _service.getLastKnownPosition();
      if (pos != null) currentPosition.value = pos;
    } catch (_) {}
  }

  Future<Position?> refreshOnce() async {
    isLoading.value = true;
    final pos = await _service.getCurrentPosition(useGps: isGpsEnabled.value);
    if (pos == null) {
      isLoading.value = false;
      _showPermissionMessageIfNeeded();
      return null;
    }
    currentPosition.value = pos;
    _moveMapTo(pos);
    isLoading.value = false;
    return pos;
  }

  void startTracking({int? distance}) async {
    if (isTracking.value) return;

    final ok = await _service.checkAndRequestPermission();
    if (!ok) {
      _showPermissionMessageIfNeeded();
      return;
    }

    isTracking.value = true;
    if (distance != null) distanceFilter.value = distance;

    _sub = _service
        .getPositionStream(
          useGps: isGpsEnabled.value,
          distanceFilter: distanceFilter.value,
        )
        .listen(
          (pos) async {
            currentPosition.value = pos;
            _moveMapTo(pos);

            // Simpan ke Hive (Uncomment jika HiveService sudah siap)
            try {
              // final hive = Get.find<HiveService>();
              // await hive.saveLocation(
              //   LocationModel(
              //     lat: pos.latitude,
              //     lng: pos.longitude,
              //     accuracy: pos.accuracy,
              //     timestamp: DateTime.now(),
              //   ),
              // );
            } catch (_) {}
          },
          onError: (err) {
            Get.snackbar(
              'Error',
              'Tracking error: $err',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        );
  }

  void stopTracking() {
    if (!isTracking.value) return;
    isTracking.value = false;
    _sub?.cancel();
    _sub = null;
  }

  void toggleGpsMode(bool v) {
    isGpsEnabled.value = v;
    if (isTracking.value) {
      stopTracking();
      Future.delayed(const Duration(milliseconds: 150), () => startTracking());
    }
  }

  void setDistanceFilter(int v) {
    distanceFilter.value = v;
    if (isTracking.value) {
      stopTracking();
      Future.delayed(
        const Duration(milliseconds: 150),
        () => startTracking(distance: v),
      );
    }
  }

  void _moveMapTo(Position pos) {
    try {
      // PERBAIKAN V7: Akses zoom melalui .camera.zoom
      mapController.move(
        LatLng(pos.latitude, pos.longitude),
        mapController.camera.zoom,
      );
    } catch (_) {
      // Handle jika map belum siap
    }
  }

  void _showPermissionMessageIfNeeded() async {
    final p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      Get.snackbar(
        'Permission lokasi diperlukan',
        'Aktifkan akses lokasi di pengaturan jika sudah ditolak.',
        snackPosition: SnackPosition.BOTTOM,
        mainButton: TextButton(
          onPressed: () => openAppSettings(),
          child: const Text(
            'Buka Pengaturan',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      Get.snackbar(
        'Lokasi tidak tersedia',
        'Tidak dapat mengambil lokasi saat ini.',
      );
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
