import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class LocationController extends GetxController {
  final LocationService _service = LocationService();
  final MapController mapController = MapController();

  // STATE VARIABLES
  final Rxn<Position> currentPosition = Rxn<Position>();
  final isLoading = false.obs;

  final isTracking = false.obs; // Status Live Tracking
  final isGpsEnabled = true.obs; // Status Mode GPS
  final distanceFilter = 10.obs; // Filter Jarak (Meter)

  // --- LOGIC ONGKIR & JARAK (ALAMAT BARU: BULULAWANG) ---
  // Koordinat diperbarui ke area Jl. Raya Bululawang No.45
  final LatLng warungLocation = const LatLng(-8.077832, 112.641220);

  final distanceToWarung = 0.0.obs;
  final deliveryFee = 0.0.obs;

  StreamSubscription<Position>? _sub;

  @override
  void onInit() {
    super.onInit();
    _initLastKnown();
  }

  Future<void> _initLastKnown() async {
    try {
      final pos = await _service.getLastKnownPosition();
      if (pos != null) _updatePosition(pos);
    } catch (_) {}
  }

  Future<void> refreshOnce() async {
    isLoading.value = true;

    // Cek Service GPS
    bool serviceEnabled = await _service.isLocationServiceEnabled();
    if (!serviceEnabled) {
      isLoading.value = false;
      Get.snackbar("GPS Mati", "Mohon nyalakan GPS");
      return;
    }

    // Cek Permission
    LocationPermission permission = await _service.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _service.requestPermission();
      if (permission == LocationPermission.denied) {
        isLoading.value = false;
        return;
      }
    }

    // Ambil Lokasi
    final pos = await _service.getCurrentPosition(useGps: isGpsEnabled.value);
    if (pos != null) {
      _updatePosition(pos);
    }
    isLoading.value = false;
  }

  // --- FUNGSI UPDATE POSISI & ONGKIR ---
  void _updatePosition(Position pos) {
    currentPosition.value = pos;

    // Hitung Jarak ke Warung (dalam KM)
    double distMeters = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      warungLocation.latitude,
      warungLocation.longitude,
    );
    distanceToWarung.value = distMeters / 1000;

    // Hitung Ongkir (Rp 2000/km, Min Rp 5000)
    double fee = distanceToWarung.value * 2000;
    if (fee < 5000) fee = 5000;
    deliveryFee.value = fee;

    // Pindahkan Kamera Peta
    try {
      mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
    } catch (_) {}
  }

  // --- FUNGSI TRACKING ---
  void startTracking() async {
    if (isTracking.value) return;
    isTracking.value = true;

    _sub = _service
        .getPositionStream(
          useGps: isGpsEnabled.value,
          distanceFilter: distanceFilter.value,
        )
        .listen((pos) {
          _updatePosition(pos);
        });
  }

  void stopTracking() {
    isTracking.value = false;
    _sub?.cancel();
    _sub = null;
  }

  void toggleGpsMode(bool val) {
    isGpsEnabled.value = val;
    // Restart tracking kalau sedang jalan biar mode baru aktif
    if (isTracking.value) {
      stopTracking();
      Future.delayed(const Duration(milliseconds: 200), () => startTracking());
    }
  }

  void setDistanceFilter(int val) {
    distanceFilter.value = val;
    if (isTracking.value) {
      stopTracking();
      Future.delayed(const Duration(milliseconds: 200), () => startTracking());
    }
  }

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }
}
