import 'dart:ui';
import 'dart:math';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

NetworkImage image = NetworkImage(
  "https://images.unsplash.com/photo-1583511655826-05700d52f4d9?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=388&q=80",
);

class User {
   int? id;
  String name;
  final Image? profileImage;
  String category;
  Location currentLocation;
  Location previousLocation;
 // Marker? marker;
  User({
    this.id,
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


   static List<User> users = [
    // Users(
    //   name: 'Wife',
    //   category: 'people',
    //   currentLocation: LatLng(-1.286389, 36.817223),
    //   previousLocation: LatLng(randomDouble(), randomDouble()),
    //   marker: Marker(
    //     markerId: MarkerId('wife'),
    //     position: LatLng(-1.286389, 36.817223),
    //     infoWindow: InfoWindow(title: 'Wife'),
    //   ),
    // ),
    // Users(
    //   name: 'Son',
    //   profileImage: Image.asset("images/kid.png"),
    //   category: '',
    //   currentLocation: LatLng(-0.091702, 34.767956),
    //   previousLocation: LatLng(randomDouble(), randomDouble()),
    //   marker: Marker(
    //     markerId: MarkerId('Son'),
    //     position: LatLng(-1.286389, 36.817223),
    //     infoWindow: InfoWindow(title: 'Wife'),
    //   ),
    // ),
    // Users(
    //   name: 'Phone',
    //   profileImage: Image.asset("images/phone.png"),
    //   category: '',
    //   currentLocation: LatLng(-1.102554, 37.013193),
    //   previousLocation: LatLng(randomDouble(), randomDouble()),
    //   marker: Marker(
    //     markerId: MarkerId('Phone'),
    //     position: LatLng(-1.286389, 36.817223),
    //     infoWindow: InfoWindow(title: 'Wife'),
    //   ),
    // ),
    // Users(
    //   name: 'Girlfriend',
    //   profileImage: Image.asset("images/gal.jpg"),
    //   category: '',
    //   currentLocation: LatLng(-1.038757, 37.083375),
    //   previousLocation: LatLng(randomDouble(), randomDouble()),
    //   marker: Marker(
    //     markerId: MarkerId('Girlfriend'),
    //     position: LatLng(-1.286389, 36.817223),
    //     infoWindow: InfoWindow(title: 'Wife'),
    //   ),
    // ),
  ];

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
