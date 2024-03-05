import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:locator/Components/Buttons.dart';
import 'package:locator/Components/SnackBar.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareLocation(context) async {
  DateTime dateTime = DateTime.now();
  final user = Provider.of<CurrentUser>(context, listen: false);
  final provider = Provider.of<CurrentLocations>(context, listen: false);
  final received = Provider.of<GetReceiversName>(context, listen: false);
  String? receiver = received.receiver;
  String? currentUser = await user.getCurrentUserDisplayName();
  String requestMessage = '$currentUser sent you a Location request!';
  String message = 'shared Location with you!';
  bool isAccepted = false;
  Position currentPosition = await provider.determinePosition();
  if (receiver != null) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButtons(
                  text: 'Share',
                  onPressed: () async {
                    await _share(
                        currentUser,
                        receiver,
                        message,
                        currentPosition.latitude,
                        currentPosition.longitude,
                        dateTime,
                        context);
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButtons(
                  text: 'Request',
                  onPressed: () async {
                    //requests location
                    await _request(
                        currentUser,
                        receiver,
                        requestMessage,
                        dateTime,
                        currentPosition.latitude,
                        currentPosition.longitude,
                        isAccepted,
                        context);
                  },
                ),
              ],
            ),
          );
        });
  } else if (receiver == null && Friends.friends.isEmpty) {
    await invitation(context);
  } else {
    showSnackBar(context, 'Please select a friend to share or request location');
  }
}

Future<void> invitation(context) async {
  final box = context.findRenderObject() as RenderBox?;
  String link = 'https://garlicfarming.my.canva.site/garlic-farming-in-kenya';
  String text =
      "Check this cool app to keep track of your friends and Family Location $link";
  await Share.share(text,
      //subject: link
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
}

Future<void> _share(
    String sender,
    String receiver,
    String message,
    double latitude,
    double longitude,
    DateTime dateTime,
    BuildContext context) async {
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('shared');
  ref.push().set({
    'sendersName': sender,
    'receiver': receiver,
    'message': message,
    'currentLocation': {'latitude': latitude, 'longitude': longitude},
    'dateTime': dateTime.toUtc().toString()
  }).then((_) {
    showSnackBar(context, 'location shared to $receiver');
    //shares location
    Navigator.pop(context);
  }).catchError((error) {
    showSnackBar(context, 'location not shared,Try again!');
    Navigator.pop(context);
  });
}

Future<void> _request(
    String sender,
    String receiver,
    String message,
    DateTime dateTime,
    double latitude,
    double longitude,
    bool isAccepted,
    BuildContext context) async {
  final DatabaseReference ref =
      FirebaseDatabase.instance.ref().child('requests');
  ref.push().set({
    'sendersName': sender,
    'receivingRequest': receiver,
    'message': message,
    'currentLocation': {'latitude': latitude, 'longitude': longitude},
    'dateTime': dateTime.toString(),
    'isAccepted': isAccepted
  }).then((_) {
    showSnackBar(context, 'location requested from $receiver');
    Navigator.pop(context);
  }).catchError((error) {
    showSnackBar(context, 'location not requested, Try again!"');
    Navigator.pop(context);
  });
}

