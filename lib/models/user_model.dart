// path: lib/models/user_model.dart
import 'package:hive/hive.dart';

part 'user_model.g.dart'; // Baris ini akan merah sampai build_runner dijalankan

@HiveType(typeId: 2) // ID 0=Product, 1=Location, 2=User
class UserModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String fullName;

  @HiveField(3)
  final String address;

  @HiveField(4)
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.address,
    this.fcmToken,
  });

  // Konversi dari JSON Supabase ke Model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      address: json['address'] ?? '',
      fcmToken: json['fcm_token'],
    );
  }

  // Konversi dari Model ke JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'address': address,
    'fcm_token': fcmToken,
  };
}
