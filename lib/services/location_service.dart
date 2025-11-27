// path: lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> checkAndRequestPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) return true;
    final result = await Permission.location.request();
    return result.isGranted;
  }

  Future<Position?> getCurrentPosition({
    bool useGps = false,
    Duration? timeout,
  }) async {
    final ok = await checkAndRequestPermission();
    if (!ok) return null;
    final accuracy = useGps ? LocationAccuracy.high : LocationAccuracy.low;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout ?? const Duration(seconds: 10),
      );
      return pos;
    } catch (_) {
      return null;
    }
  }

  Stream<Position> getPositionStream({
    bool useGps = false,
    int distanceFilter = 5,
  }) {
    final accuracy = useGps ? LocationAccuracy.high : LocationAccuracy.low;
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  Future<Position?> getLastKnownPosition() => Geolocator.getLastKnownPosition();
}
