
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShareLocation {
  String sender;
  Location currentLocation;
  String receiver;
  String message;
  String dateTime;
  bool isAccepted;

  ShareLocation(
      {required this.sender,
      required this.currentLocation,
      required this.receiver,
      required this.message,
      required this.dateTime,
      this.isAccepted = false});

  factory ShareLocation.fromMap(Map<String, dynamic> data) {
    return ShareLocation(
      sender: data['sendersName'],
      receiver: data['receiver'],
      message: data['message'],
      currentLocation: Location.fromMap(data['currentLocation'] ?? {}),
      dateTime: data['dateTime'],
    );
  }

  static List<ShareLocation> shared = [];
}


class Sos {
   final String dateTime;
  final String sendersName;
   final List<Map<String, dynamic>> receiver;
  final String message;
  Location currentLocation;

  Sos({
    required this.message,
    required this.sendersName,
     required this.dateTime,
    required this.currentLocation,
    required this.receiver
  });

  factory Sos.fromMap(Map<String, dynamic> data) {
    try{
      return Sos(
        message: data['message'],
        sendersName: data['sendersName'],
        dateTime: data['dateTime'],
        currentLocation: Location.fromMap(data['currentLocation'] ?? {}),
         receiver: List<Map<String, dynamic>>.from(data['receiver']),
      );
    }catch(e){
      print("Error mapping SOS: $e");
      rethrow;
    }
  }

  static List<Sos> sharedSos = [];
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
