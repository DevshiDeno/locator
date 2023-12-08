import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class User {
   int id;
  String name;
   Image? profileImage;
  String category;
  Location currentLocation;
  Location previousLocation;
 // Marker? marker;
  User({
    required this.id,
     //this.marker,
    required this.name,
     this.profileImage,
    required this.category,
    required this.currentLocation,
    required this.previousLocation,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      currentLocation: Location.fromJson(json['currentLocation']),
      previousLocation: Location.fromJson(json['previousLocation']),
    );
  }


   static List<User> users = [];

  static double randomDouble() {
    // Generates a random double between -90.0 and 90.0
    return Random().nextDouble() * 180.0 - 90.0;
  }
}
class Location {
  final double latitude;
  final double longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}
