import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class LocationController extends GetxController {
  final LocationService _service = LocationService();

  final Rxn<Position> currentPosition = Rxn<Position>();
  final isLoading = false.obs;
  final isTracking = false.obs;
  final isGpsEnabled = true.obs; // Mode High Accuracy
  final distanceFilter = 5.obs;

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
      if (pos != null) {
        currentPosition.value = pos;
        _moveMapTo(pos);
      }
    } catch (_) {}
  }

  Future<void> refreshOnce() async {
    isLoading.value = true;

    // 1. Cek apakah GPS (Hardware) Nyala?
    bool isServiceEnabled = await _service.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      isLoading.value = false;
      _showDialogGpsMati(); // Tampilkan Dialog suruh nyalakan GPS
      return;
    }

    // 2. Cek Permission
    LocationPermission permission = await _service.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await _service.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        isLoading.value = false;
        _showDialogPermissionDitolak();
        return;
      }
    }

    // 3. Ambil Posisi
    final pos = await _service.getCurrentPosition(useGps: isGpsEnabled.value);

    if (pos != null) {
      currentPosition.value = pos;
      _moveMapTo(pos);
      Get.snackbar("Sukses", "Lokasi berhasil diperbarui!");
    } else {
      Get.snackbar(
        "Gagal",
        "Tidak dapat mengambil lokasi (Timeout/Error). Coba lagi.",
      );
    }

    isLoading.value = false;
  }

  void startTracking({int? distance}) async {
    if (isTracking.value) return;

    // Cek Permission Dulu
    LocationPermission permission = await _service.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await refreshOnce(); // Pancing request permission lewat refreshOnce
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
          (pos) {
            currentPosition.value = pos;
            _moveMapTo(pos);
          },
          onError: (err) {
            print("Stream Error: $err");
            stopTracking();
          },
        );
  }

  void stopTracking() {
    isTracking.value = false;
    _sub?.cancel();
    _sub = null;
  }

  void toggleGpsMode(bool v) {
    isGpsEnabled.value = v;
    // Restart tracking jika sedang aktif agar mode baru teraplikasi
    if (isTracking.value) {
      stopTracking();
      Future.delayed(const Duration(milliseconds: 200), () => startTracking());
    }
  }

  void setDistanceFilter(int v) {
    distanceFilter.value = v;
    if (isTracking.value) {
      stopTracking();
      Future.delayed(
        const Duration(milliseconds: 200),
        () => startTracking(distance: v),
      );
    }
  }

  void _moveMapTo(Position pos) {
    try {
      mapController.move(
        LatLng(pos.latitude, pos.longitude),
        15.0, // Zoom Level Default
      );
    } catch (e) {
      print("Map belum siap: $e");
    }
  }

  // --- Dialog Helpers ---

  void _showDialogGpsMati() {
    Get.defaultDialog(
      title: "GPS Mati",
      middleText: "Fitur lokasi membutuhkan GPS. Mohon nyalakan GPS Anda.",
      textConfirm: "Buka Settings",
      textCancel: "Batal",
      onConfirm: () {
        Geolocator.openLocationSettings();
        Get.back();
      },
    );
  }

  void _showDialogPermissionDitolak() {
    Get.defaultDialog(
      title: "Izin Ditolak",
      middleText: "Aplikasi butuh izin lokasi untuk fitur ini.",
      textConfirm: "Buka App Settings",
      textCancel: "Batal",
      onConfirm: () {
        Geolocator.openAppSettings();
        Get.back();
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
