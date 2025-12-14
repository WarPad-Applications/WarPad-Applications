import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart'; // Opsional jika pakai Geolocator sepenuhnya

class LocationService {
  // Cek apakah Layanan GPS (Hardware) Nyala?
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Cek Permission dengan Geolocator langsung (Lebih akurat untuk plugin ini)
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<Position?> getCurrentPosition({
    bool useGps = true,
    Duration? timeout,
  }) async {
    try {
      // 1. Cek GPS Nyala/Mati
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Return null atau throw error biar Controller tahu GPS mati
        print("Log: GPS is disabled.");
        return null;
      }

      // 2. Cek Izin
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Log: Permission denied.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("Log: Permission denied forever.");
        return null;
      }

      // 3. Ambil Lokasi
      final accuracy = useGps ? LocationAccuracy.high : LocationAccuracy.medium;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout ?? const Duration(seconds: 10),
      );
    } catch (e) {
      print("Log: Error getting location: $e");
      return null;
    }
  }

  Stream<Position> getPositionStream({
    bool useGps = true,
    int distanceFilter = 5,
  }) {
    final accuracy = useGps ? LocationAccuracy.high : LocationAccuracy.medium;

    // Settingan khusus Android/iOS
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }
}
