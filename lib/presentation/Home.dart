import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:locator/Auth/login.dart';
import 'package:locator/Components/Buttons.dart';
import 'package:locator/Components/showDialog.dart';
import 'package:locator/Data/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/Notifications.dart';
import 'package:locator/presentation/UserProfile.dart';
import 'package:provider/provider.dart';
import 'bottom_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  late String receiver;
  LatLng? currentPosition;
  GoogleMapController? mapController;
  final TextEditingController _controller = TextEditingController();
  late BitmapDescriptor customMarker;
  String? address;
  String? prev;
  late LatLng newPosition;
  final TextEditingController controller = TextEditingController();
  Set<Marker> markers = {};
  List<Users> filteredUsers = [];
  List<Users> matchingUsers = [];
  final DatabaseReference _reference =
  FirebaseDatabase.instance.ref().child('users');

  Future<String> getAddressFromLatLng(position) async {
    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placeMarks.isNotEmpty) {
        return placeMarks[0].name ?? "Unknown Place";
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
        try {
          // Assuming User.fromMap accepts List<dynamic>
          Map<String, dynamic> dataList =
          jsonDecode(jsonEncode(event.snapshot.value));
          List<Users> users =
          dataList.values.map((item) => Users.fromMap(item)).toList();
          setState(() {
            Users.users = users;
            markers = Set.from(Users.users.map((user) =>
                Marker(
                  markerId: MarkerId(user.name),
                  position: user.currentLocation.toLatLng(),
                  infoWindow: InfoWindow(title: user.name),
                )));
            filteredUsers = List.from(Users.users);
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
        filteredUsers = List.from(Users.users);
      } else {
        // Filter users based on the selected category
        filteredUsers =
            Users.users.where((user) => user.category == category).toList();
      }
    });
  }

  Future<void> selectedItem(index, GoogleMapController? mapController) async {
    LatLng location = Users.users[index].currentLocation.toLatLng();
    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      address = placeMarks.isNotEmpty
          ? placeMarks[0].thoroughfare ?? "Unknown Place"
          : "Unknown Place";

      print("Address: $address");

      CameraPosition position = CameraPosition(
        target: location,
        zoom: 16,
      );

      setState(() {
        currentPosition = location;
        mapController?.animateCamera(CameraUpdate.newCameraPosition(position));
        markers = markers;
      });
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider =
    Provider.of<SearchUserProvider>(context, listen: false);
    final locationProvider =
    Provider.of<GetReceiversName>(context, listen: false);
    var we = MediaQuery
        .of(context)
        .size
        .width;
    var he = MediaQuery
        .of(context)
        .size
        .height;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
              mapType: MapType.normal,
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
                width: we,
                // height: he * 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: IconButton(
                              onPressed: () async {
                                try {
                                  await FirebaseAuth.instance.signOut();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginScreen()),
                                  );
                                } catch (e) {
                                  print(e);
                                }
                              },
                              icon: const Icon(Icons.logout_rounded))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          //  color: Colors.red,
                            borderRadius: BorderRadius.circular(16)),
                        width: 200,
                        // height: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 45,
                              //color: Colors.blue,

                              child: TextField(
                                maxLines: 1,
                                onChanged: (query) async {
                                  try {
                                    await searchProvider.searchUsers(query);
                                  } catch (e) {
                                    print(e);
                                  }
                                  setState(() {
                                    matchingUsers = searchProvider.searchResults
                                        .where((user) =>
                                        user.name
                                            .toLowerCase()
                                            .contains(query.toLowerCase()))
                                        .toList();
                                  });
                                },
                                controller: _controller,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 10),
                                  // Adjust padding
                                  hintText: 'Search',
                                  // suffixIcon: IconButton(
                                  //     onPressed: () async {
                                  //       String searched = _controller.text;
                                  //       await searchProvider
                                  //           .searchUsers(searched);
                                  //     },
                                  //     icon: Icon(Icons.search))
                                ),
                              ),
                            ),
                            if (matchingUsers.isNotEmpty)
                              Container(
                                  width: 200,
                                  height: 100,
                                  color: Colors.white60,
                                  child: ListView.builder(
                                      itemCount: matchingUsers.length,
                                      itemBuilder: (context, index) {
                                        final searchedUser =
                                        matchingUsers[index];
                                        return GestureDetector(
                                          onTap: () {
                                            selectedItem(index, mapController);
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              matchingUsers.clear();
                                              _controller.text = '';
                                            });
                                          },
                                          child: ListTile(
                                            title: Text(searchedUser.name),
                                            subtitle: FutureBuilder(
                                                future: getAddressFromLatLng(
                                                    searchedUser.currentLocation
                                                        .toLatLng()),
                                                builder:
                                                    (context, addressSnapshot) {
                                                  if (addressSnapshot
                                                      .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const Center(
                                                        child:
                                                        CircularProgressIndicator());
                                                  } else if (addressSnapshot
                                                      .hasError) {
                                                    return Text(
                                                        'Error: ${addressSnapshot
                                                            .error}');
                                                  } else {
                                                    return Text(
                                                        addressSnapshot.data!);
                                                  }
                                                }),
                                          ),
                                        );
                                      }))
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: IconButton(
                              onPressed: () {
                                shareLocation(context);
                              },
                              icon: const Icon(Icons.share_location_rounded))),
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
                    color: Colors.lightGreenAccent,
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
                    //  Center(child: Text("Sharing History")),
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
                      child: filteredUsers.isEmpty
                          ? Center(
                        child: Text(
                          'Add people to share location with',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                          : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                selectedIndex = index;
                              });
                              //zooms to the specific location
                              await selectedItem(index, mapController);
                              await locationProvider.getReceiver(index);
                            },
                            child: buildRow(
                                we, user, context, selectedIndex, index),
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
    );
  }

  Widget buildRow(double we, Users user, context, int index,
      int selectedIndex) {
    Color normalColor = Colors.white60;
    Color selectedColor = Colors.lightGreenAccent;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
       // padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: index == selectedIndex ? selectedColor : normalColor,
            borderRadius: BorderRadius.circular(16)
        ),
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
                  borderRadius: BorderRadius.circular(30), color: Colors.white70),
              child: const Center(
                child: Icon(Icons.battery_2_bar),
              ),
            ),
            SizedBox(width: we * 0.03),
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30), color: Colors.white70),
              child: Center(
                  child: IconButton(
                    onPressed: () async {
                      String current =
                      await getAddressFromLatLng(user.currentLocation.toLatLng());
                      String prev =
                      await getAddressFromLatLng(
                          user.previousLocation.toLatLng());
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  Profile(
                                    user: user.name,
                                    currentLocation: current,
                                    id: user.id,
                                    prevLocation: prev,
                                  )));
                    },
                    icon: Icon(Icons.send_and_archive_sharp),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
