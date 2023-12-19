import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

void addButton(context) {
  TextEditingController nameController = TextEditingController();
  TextEditingController cityController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      const String category ='people';
      return Container(
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
                List<Location> locations = await locationFromAddress(
                    cityController.text);

                if (locations.isNotEmpty) {
                  // Take the first location (you may want to handle multiple results differently)
                  Location location = locations.first;
                  double latitude = location.latitude;
                  double longitude = location.longitude;

                  // Post data with coordinates
                  _postPersonData(nameController.text,category,latitude,longitude);
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
      const String category ='item';
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
              List<Location> locations = await locationFromAddress(
                  cityController.text
              );
              print(cityController.text);
              if (locations.isNotEmpty) {
                // Take the first location (you may want to handle multiple results differently)
                Location location = locations.first;
                double latitude = location.latitude;
                double longitude = location.longitude;

                // Post data with coordinates
                _postItemData(typeController.text,category, latitude, longitude);
              } else {
                // Handle case where no coordinates were found for the city
                print("No coordinates found for ${cityController.text}");
              }
            },
            child: Text("OK"),
          )
        ],
      );
    },
  );
}

Future<void> _postItemData(String name, String item,double latitude, double longitude) async {
  // Create a Map with the entered data
final DatabaseReference ref=FirebaseDatabase.instance.ref().child('users');
  ref.push().set({
    "name": "name",
    "category":"item",
    "currentLocation": {"latitude": latitude, "longitude": longitude},
  }).then((_) {
    print('Item added successfully');
  }).catchError((error) {
    print('Error adding item: $error');
  });
}

Future<void> _postPersonData(String name, String item,double latitude, double longitude) async {
  // Create a Map with the entered data
  final DatabaseReference ref=FirebaseDatabase.instance.ref().child('users');
  ref.push().set({
    "name": name,
    "category":item,
    "currentLocation": {"latitude": latitude, "longitude": longitude},
  }).then((_) {
    print('Item added successfully');
  }).catchError((error) {
    print('Error adding item: $error');
  });
}