import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:locator/Components/Buttons.dart';
import 'package:locator/Components/showDialog.dart';
import 'package:locator/Data/user_details.dart';
import 'package:locator/presentation/UserProfile.dart';
import 'bottom_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng? currentPosition;
  GoogleMapController? mapController;
  late BitmapDescriptor customMarker;
  String? address;
  String? prev;
  late LatLng newPosition;
  late TextEditingController controller;
  Set<Marker> markers = {};
  List<User> filteredUsers = [];
  List<User> fetchedUser = []; // Define the list here
  final DatabaseReference _reference =
      FirebaseDatabase.instance.ref().child('users');

  Future<String> getAddressFromLatLng(position) async {

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
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

  Future<void> _loadUsers() async {
    _reference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        print(event.snapshot.value);

        try {
          // Assuming User.fromMap accepts List<dynamic>
          Map<String, dynamic> dataList = jsonDecode(jsonEncode(event.snapshot.value));
          List<User> users =
              dataList.values.map((item) => User.fromMap(item)).toList();
          setState(() {
            User.users = users;
            markers = Set.from(User.users.map((user) => Marker(
                  markerId: MarkerId(user.name),
                  position: user.currentLocation.toLatLng(),
                  infoWindow: InfoWindow(title: user.name),
                )));
            fetchedUser = List.from(User.users);
            // Initially, display all users
          });
        } catch (e) {
          print('Error updating state: $e');
        }
      }
    });
  }

  void filterUsers(String category) {
    setState(() {
      if (category == "All") {
        // Display all users
        filteredUsers = List.from(fetchedUser);
      } else {
        // Filter users based on the selected category
        filteredUsers =
            User.users.where((user) => user.category == category).toList();
      }
    });
  }

  Future<void> selectedItem(int index) async {
    if (User.users.isNotEmpty && index >= 0 && index < User.users.length) {
      LatLng location = User.users[index].currentLocation.toLatLng();

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        address = placemarks.isNotEmpty
            ? placemarks[0].thoroughfare ?? "Unknown Place"
            : "Unknown Place";

        print("Address: $address");

        CameraPosition position = CameraPosition(
          target: location,
          zoom: 12,
        );

        setState(() {
          currentPosition = location;
          mapController
              ?.animateCamera(CameraUpdate.newCameraPosition(position));
          markers = markers;
        });
      } catch (e) {
        print("Error getting address: $e");
      }
    }
  }

  @override
  void initState() {
    controller = TextEditingController();
    super.initState();
  //  getAddressFromLatLng(currentPosition);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
              mapType: MapType.terrain,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                  target: currentPosition ?? const LatLng(-1.292066, 36.821946),
                  zoom: 12.0),
              markers: markers),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          //crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButtons(
                              text: "All",
                              onPressed: () {
                                filterUsers('All');
                              },
                            ),
                            SizedBox(width: we * 0.01),
                            ElevatedButtons(
                              text: "People",
                              onPressed: () {
                                filterUsers('people');
                              },
                            ),
                            SizedBox(width: we * 0.01),
                            ElevatedButtons(
                              text: "Items",
                              onPressed: () {
                                filterUsers("item");
                              },
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
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return
                              Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () async {
                                  //zooms to the specific location
                                  await selectedItem(index);
                                },
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: CircleAvatar(
                                        radius: 20,
                                        child: Image.network(
                                          "https://images.unsplash.com/photo-1583511655826-05700d52f4d9?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=388&q=80",
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: we * 0.45,
                                      height: 60,
                                      child: Center(
                                        child: ListTile(
                                          title: Text(
                                            user.name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: FutureBuilder(
                                            future: getAddressFromLatLng(user.currentLocation),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return Text("Loading...");
                                              } else if (snapshot.hasError) {
                                                return Text("Error: ${snapshot.error}");
                                              } else {
                                                return Text(snapshot.data ?? "Unknown Place");
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
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
                                            onPressed: () async {
                                              String current=await getAddressFromLatLng(user.currentLocation.toLatLng());
                                              String prev=await getAddressFromLatLng(user.previousLocation.toLatLng());
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) => Profile(
                                                        user: user.name,
                                                        currentLocation: current,
                                                        id: user.id, prevLocation: prev,
                                                      )));
                                              print('User ${user.id}');
                                            },
                                            icon: Icon(Icons.send_and_archive_sharp),
                                          )),
                                    ),                                  ],
                                ),
                              ),
                            );
                          },
                        )
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
