// path: lib/models/location_model.dart
import 'package:hive/hive.dart';
part 'location_model.g.dart';

@HiveType(typeId: 1)
class LocationModel {
  @HiveField(0)
  final double lat;

  @HiveField(1)
  final double lng;

  @HiveField(2)
  final double accuracy;

  @HiveField(3)
  final DateTime timestamp;

  LocationModel({
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };
}
