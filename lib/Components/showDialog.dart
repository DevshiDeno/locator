import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locator/Components/Buttons.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:provider/provider.dart';

void addButton(context) {
  TextEditingController nameController = TextEditingController();
  TextEditingController cityController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      const String category = 'people';
      return SizedBox(
        height: 200,
        child: AlertDialog(
          title: Text("Add Person"),
          content: Container(
            height: 150,
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    labelText: "Person",
                  ),
                ),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                    labelText: "City",
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cancel button
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // OK button
                Navigator.pop(context);

                // Convert city to coordinates
                List<Location> locations =
                    await locationFromAddress(cityController.text);

                if (locations.isNotEmpty) {
                  // Take the first location (you may want to handle multiple results differently)
                  Location location = locations.first;
                  double latitude = location.latitude;
                  double longitude = location.longitude;

                  // Post data with coordinates
                  _postPersonData(
                      nameController.text, category, latitude, longitude);
                } else {
                  // Handle case where no coordinates were found for the city
                  print("No coordinates found for ${cityController.text}");
                }
              },
              child: Text("OK"),
            )
          ],
        ),
      );
    },
  );
}

void addItem(context) {
  TextEditingController typeController = TextEditingController();
  TextEditingController cityController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      const String category = 'item';
      //double id=random.nextDouble();
      return AlertDialog(
        title: Text("Add Item"),
        content: Container(
          height: 150,
          child: Column(
            children: [
              TextField(
                controller: typeController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  labelText: "Type",
                ),
              ),
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                  labelText: "City",
                ),
              )
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cancel button
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // OK button
              Navigator.pop(context);

              // Convert city to coordinates
              List<Location> locations =
                  await locationFromAddress(cityController.text);
              if (locations.isNotEmpty) {
                // Take the first location (you may want to handle multiple results differently)
                Location location = locations.first;
                double latitude = location.latitude;
                double longitude = location.longitude;

                // Post data with coordinates
                _postItemData(
                    typeController.text, category, latitude, longitude);
              } else {
                // Handle case where no coordinates were found for the city
                print("No coordinates found for ${cityController.text}");
              }
            },
            child: const Text("OK"),
          )
        ],
      );
    },
  );
}

Future<void> _postItemData(
    String name, String item, double latitude, double longitude) async {
  // Create a Map with the entered data
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('users');
  ref.push().set({
    "name": name,
    "category": item,
    "currentLocation": {"latitude": latitude, "longitude": longitude},
  }).then((_) {
    print('Item added successfully');
  }).catchError((error) {
    print('Error adding item: $error');
  });
}

Future<void> _postPersonData(
    String name, String item, double latitude, double longitude) async {
  // Create a Map with the entered data
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('users');
  ref.push().set({
    "name": name,
    "category": item,
    "currentLocation": {"latitude": latitude, "longitude": longitude},
  }).then((_) {
    print('Item added successfully');
  }).catchError((error) {
    print('Error adding item: $error');
  });
}

void shareLocation(context) {
  DateTime dateTime = DateTime.now();
  String message = 'My current Location';
  final user = Provider.of<CurrentUser>(context, listen: false);
  final provider = Provider.of<CurrentLocations>(context, listen: false);
  final received = Provider.of<GetReceiversName>(context, listen: false);
  String? receiver = received.receiver;
  Position currentPosition;
  if(receiver!=null)
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Row(
            // crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButtons(
                text: 'Share',
                onPressed: () async {
                  currentPosition = await provider.determinePosition();
                  String currentUser = await user.getCurrentUserId();
                  print(currentUser);
                  print(receiver);
                  await _share(
                      currentUser,
                      receiver!,
                      message,
                      currentPosition.latitude,
                      currentPosition.longitude,
                      dateTime
                  );

                  print('shared location:$currentPosition');
                  //shares location
                  Navigator.pop(context);
                },
              ),
              SizedBox(width: 10),
              ElevatedButtons(
                text: 'Request',
                onPressed: () {
                  //requests location
                },
              ),
            ],
          ),
        );
      });
  else{
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select a Person to share location to')),
    );
  }
}

Future<void> _share(String receiver, String sender, String message,
    double latitude, double longitude, DateTime dateTime) async {
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('shared');
  ref.push().set({
    'name': sender,
    'receiver': receiver,
    'message': message,
    'currentLocation': {'latitude': latitude, 'longitude': longitude},
    'dateTime': dateTime.toUtc().toString()
  }).then((_) {
    print('Location shared');
  }).catchError((error) {
    print('Error sharing Location: $error');
  });
}
