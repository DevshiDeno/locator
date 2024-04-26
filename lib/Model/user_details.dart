import 'package:google_maps_flutter/google_maps_flutter.dart';

class Users {
  String id;
  String name;
  String imageUrl;
  String email;
  Locations currentLocation;
  List <Locations> previousLocation;

  Users({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.email,
    required this.currentLocation,
    required this.previousLocation,
  });

  factory Users.fromMap(Map<String, dynamic> data) {
    List<dynamic> previousLocationsData = data['previousLocation'] ?? [];
    List<Locations> previousLocations =
    previousLocationsData.map((locData) => Locations.fromMap(locData)).toList();

    return Users(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      email: data['email'] ?? '',
      currentLocation: Locations.fromMap(data['currentLocation'] ?? {}),
      previousLocation: previousLocations,
    );
  }

  static List<Users> users = [];
}

class Friends {
  String name;
  String senderName;
  String senderId;
  Locations currentLocation;
  List <Locations> previousLocation;
  String receiverId;
  String imageUrl;
  String senderImage;
  DateTime dateTime = DateTime.now();
  bool request;

  Friends(
      {required this.name,
      required this.senderName,
      required this.senderId,
      required this.imageUrl,
      required this.senderImage,
      required this.currentLocation,
      required this.previousLocation,
      required this.receiverId,
      required this.request});

  factory Friends.fromMap(Map<String, dynamic> data) {
    List<dynamic> previousLocationsData = data['previousLocation'] ?? [];
    List<Locations> previousLocation = previousLocationsData.map((locData) => Locations.fromMap(locData)).toList();

    return Friends(
      name: data['name'],
      senderName: data['senderName'],
      senderId: data['senderId'],
      imageUrl: data['imageUrl'],
      senderImage: data['senderImage'] ?? '',
      receiverId: data['receiverId'],
      currentLocation: Locations.fromMap(data['currentLocation'] ?? {}),
      previousLocation: previousLocation,
      request: data['request'],
    );
  }

  static List<Friends> friends = [];
}

class Locations {
  final double latitude;
  final double longitude;

  Locations({
    required this.latitude,
    required this.longitude,
  });

  factory Locations.fromMap(Map<String, dynamic> data) {
    return Locations(
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}
