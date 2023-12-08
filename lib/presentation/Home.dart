import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locator/Components/Buttons.dart';
import 'package:locator/Data/showDialog.dart';
import 'package:locator/Data/user_details.dart';
import 'package:locator/Model/home.model.dart';
import 'package:locator/presentation/UserProfile.dart';
import 'bottom_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng currentPosition = LatLng(-1.286389, 36.817223);
  GoogleMapController? mapController;
  late BitmapDescriptor customMarker;
  String? address;
  late LatLng newPosition;
  late TextEditingController controller;

  Future _getCurrentLocation() async {
    bool isGeolocationAvailable = await Geolocator.isLocationServiceEnabled();
    Position _position = Position(
      latitude: 0.0,
      longitude: 0.0,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    if (isGeolocationAvailable) {
      try {
        _position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);
      } catch (error) {
        return _position;
      }
    }
    return _position;
  }

  Future<String> getAddressFromLatLng(LatLng coordinates) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks[0].name ?? "Unknown Place";
      } else {
        return "No address information found";
      }
    } catch (e) {
      // print("Error getting address: $e");
      return "Error getting address";
    }
  }
  Future<void>_loadUsers()async {
    try {
      List<User>fetchedUsers = await ApiService.fetchUsers();
      setState(() {
       User.users=fetchedUsers;
       print(User.users);
      });
    }catch(e){
      print('Error loading users: $e');
    }
  }
  @override
  void initState() {
    controller=TextEditingController();
    super.initState();
    _getCurrentLocation();
    _loadUsers();
     marker = User.users.map((user) {
      return Marker(
        markerId: MarkerId(user.name),
        position: user.currentLocation.toLatLng(),
        infoWindow: InfoWindow(title: user.name),
      );
    }).toSet();
  }

  void selectedItem(int index) async {
    if (User.users.isNotEmpty && index >= 0 && index < User.users.length) {
      LatLng Location = User.users[index].currentLocation.toLatLng();

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          Location.latitude,
          Location.longitude,
        );

        address = placemarks.isNotEmpty
            ? placemarks[0].thoroughfare ?? "Unknown Place"
            : "Unknown Place";

        print("Address: $address");

        CameraPosition position = CameraPosition(
          target: Location,
          zoom: 12,
        );

        setState(() {
          currentPosition = Location;
          mapController
              ?.animateCamera(CameraUpdate.newCameraPosition(position));
          //marker = customMarker;
        });
      } catch (e) {
        print("Error getting address: $e");
      }
    }
  }
  Set<Marker> marker = {};

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                mapController = controller;
              },
              initialCameraPosition:
                  CameraPosition(target: currentPosition, zoom: 12.0),
              markers: marker
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                // color: Colors.lightGreenAccent,
                width: we,
                height: he * 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 30,
                          child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.search_outlined))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 30,
                          child: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.settings))),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
              top: he * 0.2,
              left: 16.0,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    IconButton(
                        onPressed: () {
                          mapController?.animateCamera(CameraUpdate.zoomOut());
                        },
                        icon: Icon(Icons.zoom_out)),
                    IconButton(
                        onPressed: () {
                          mapController?.animateCamera(CameraUpdate.zoomIn());
                        },
                        icon: Icon(Icons.zoom_in)),
                  ],
                ),
              )),
          Positioned(
              left: 0,
              right: 0,
              top: he * 0.47,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButtons(
                    text: "Add new person",
                    onPressed: () {
                      addButton(context);
                    },
                    icon: const Icon(Icons.add),
                  ),
                  ElevatedButtons(
                    text: "Add new item",
                    onPressed: () {
                      addItem(context);
                    },
                    icon: const Icon(Icons.add),
                  )
                ],
              )),
          Positioned(
            left: 0,
            right: 0,
            bottom: he * 0,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                width: we,
                height: he * 0.33,
                decoration: BoxDecoration(
                    color: Colors.white70,
                  borderRadius: BorderRadius.circular(12)
                  //color: const Color.fromRGBO(255, 255, 255, 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                 // mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Container(
                        width: we,
                        height: 50,
                         //color: Colors.white,
                        child: Row(
                         // mainAxisAlignment: MainAxisAlignment.spaceAround,
                          //crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButtons(
                              text: "All",
                              onPressed: () {
                              },
                            ),
                            SizedBox(width: we * 0.01),
                            ElevatedButtons(
                              text: "People",
                              onPressed: () {},
                            ),
                            SizedBox(width: we * 0.01),
                            ElevatedButtons(
                              text: "Items",
                              onPressed: () {},
                            ),
                            //const SizedBox(width: 30),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: he * 0.24,
                      width: we,
                      child: ListView.builder(
                        itemCount: User.users.length,
                        itemBuilder: (BuildContext context, int index) {
                          final user = User.users[index];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                //zooms to the specific location
                                selectedItem(index);
                                print(index);
                                print("tapped");
                              },
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: CircleAvatar(
                                      radius: 20,
                                      // child: user.profileImage,
                                    ),
                                  ),
                                  Container(
                                    //color: Colors.red,
                                    width: we * 0.45,
                                    height: 60,
                                    child: Center(
                                      child: ListTile(
                                        //contentPadding:EdgeInsets.symmetric(horizontal: .0) ,
                                        title: Text(
                                          user.name,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: FutureBuilder<String>(
                                            future: getAddressFromLatLng(
                                                user.currentLocation.toLatLng()),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return CircularProgressIndicator(); // or a loading indicator
                                              } else if (snapshot.hasError) {
                                                return Text(
                                                    'Error: ${snapshot.error}');
                                              } else {
                                                address = snapshot.data ??
                                                    "Unknown Place";
                                                return Text(address!);
                                                // Other ListTile properties or widgets you want to display
                                              }
                                            }),
                                      ),
                                    ),
                                  ),
                                  // SizedBox(width: we * 0.1),
                                  Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Colors.white70),
                                    child: const Center(
                                      child: Icon(Icons.battery_2_bar),
                                    ),
                                  ),
                                  SizedBox(width: we * 0.03),
                                  Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Colors.white70),
                                    child: Center(
                                        child: IconButton(
                                      onPressed: () {
                                        //String prev=  getAddressFromLatLng(previousCoordinates).toString();
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => Profile(
                                                      user: user.name,
                                                      currentLocation: address!,
                                                      id:user.id!
                                                    )));
                                        print(user.currentLocation);
                                        print(address);
                                      },
                                      icon: Icon(Icons.send_and_archive_sharp),
                                    )),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomBar(),
    );
  }
}
