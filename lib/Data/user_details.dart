import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class User {
  double id;
  String name;
  String category;
  String email;
  Location currentLocation;
  Location previousLocation;

  User({
    required this.id,
    required this.name,
    required this.category,
    required this.email,
    required this.currentLocation,
    required this.previousLocation,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id:double.parse((Random().nextDouble() * 1000).toStringAsFixed(3)),
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      email: data['email'] ?? '',
      currentLocation: Location.fromMap(data['currentLocation'] ?? {}),
      previousLocation: Location.fromMap(data['previousLocation'] ?? {}),
    );
  }

  static List<User> users = [];
}

class Location {
  final double latitude;
  final double longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromMap(Map<String, dynamic> data) {
    return Location(
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
    );
  }
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}
// class Location {
//   final double latitude;
//   final double longitude;
//
//   Location({
//     required this.latitude,
//     required this.longitude,
//   });
//
//   factory Location.fromSnapshot(DataSnapshot snapshot) {
//     Map<String, dynamic>? data = snapshot.value as Map<String, dynamic>?;
//
//     if (data != null) {
//       return Location(
//         latitude: data['latitude'] ?? 0.0,
//         longitude: data['longitude'] ?? 0.0,
//       );
//     }
//
//     // Handle the case where data is null
//     return Location(latitude: 0.0, longitude: 0.0);
//   }
//
//   LatLng toLatLng() {
//     return LatLng(latitude, longitude);
//   }
// }
