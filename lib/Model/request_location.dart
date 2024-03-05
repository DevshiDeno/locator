import 'package:google_maps_flutter/google_maps_flutter.dart';

class RequestLocation{
  String sender;
  Location currentLocation;
  String receivingRequest;
  String message;
  String dateTime;
  bool isAccepted;
  RequestLocation({
    required this.sender,
    required this.currentLocation,
    required this.receivingRequest,
    required this.message,
    required this.dateTime,
    required this.isAccepted
  });
  factory RequestLocation.fromMap(Map<String,dynamic> data){
    return RequestLocation(
      sender: data['sendersName'],
      receivingRequest: data['receivingRequest'],
      message: data['message'],
      currentLocation: Location.fromMap(data['currentLocation'] ?? {}),
      dateTime: data['dateTime'],
      isAccepted: data['isAccepted'],
    );
  }
  static List<RequestLocation>requested=[];
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
