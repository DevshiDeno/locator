import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
void addButton(context) {
  TextEditingController nameController = TextEditingController();
  TextEditingController cityController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
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
                List<Location> locations = await locationFromAddress(cityController.text);

                if (locations.isNotEmpty) {
                  // Take the first location (you may want to handle multiple results differently)
                  Location location = locations.first;
                  double latitude = location.latitude;
                  double longitude = location.longitude;

                  // Post data with coordinates
                  _postPersonData(nameController.text, cityController.text, latitude, longitude);
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
              List<Location> locations = await locationFromAddress(cityController.text);

              if (locations.isNotEmpty) {
                // Take the first location (you may want to handle multiple results differently)
                Location location = locations.first;
                double latitude = location.latitude;
                double longitude = location.longitude;

                // Post data with coordinates
                _postItemData(typeController.text, cityController.text, latitude, longitude);
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

Future<void> _postItemData(String type, String city, double latitude, double longitude) async {
  // Create a Map with the entered data
  Map<String, dynamic> itemData = {
    "type": type,
    "city": city,
    "currentLocation": {"latitude": latitude, "longitude": longitude},
  };

  // Convert the Map to a JSON string
  String jsonData = json.encode(itemData);
  print("Posted JSON data: $jsonData");
  String apiUrl="https://locatormap.free.beeceptor.com/locate";

  try {
    // Make a POST request to the API
    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonData,
    );

    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      print("Successfully posted JSON data: $jsonData");
    } else {
      print("Failed to post JSON data. Status code: ${response.statusCode}");
    }
  } catch (error) {
    print("Error posting JSON data: $error");
  }
}
Future<void> _postPersonData(String name, String city, double latitude, double longitude) async {
  // Create a Map with the entered data
  Map<String, dynamic> personData = {
    "name": name,
    "currentLocation": {"latitude": latitude, "longitude": longitude},
  };

  // Convert the Map to a JSON string
  String jsonData = json.encode(personData);
  // TODO: Send the jsonData to your server or perform other actions
  // For example, you can print it for testing:
  print("Posted JSON data: $jsonData");
  // Define the API endpoint URL
  String apiUrl = "https://your-api-endpoint.com"; // Replace with your actual API endpoint

  try {
    // Make a POST request to the API
    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonData,
    );

    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      print("Successfully posted JSON data: $jsonData");
    } else {
      print("Failed to post JSON data. Status code: ${response.statusCode}");
    }
  } catch (error) {
    print("Error posting JSON data: $error");
  }

}