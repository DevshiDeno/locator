import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locator/Components/Buttons.dart';
import 'package:locator/Components/SnackBar.dart';
import 'package:locator/Components/showDialog.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/UserProfile.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isFriend = false;
  int selectedIndex = 0;
  String currentUser = 'user';
  String? currentUserId;
  LatLng currentPosition = const LatLng(-1.286389, 36.817223);
  GoogleMapController? mapController;
  final TextEditingController _controller = TextEditingController();
  late BitmapDescriptor markerIcon;
  String? address;
  String? prev;
  final TextEditingController controller = TextEditingController();
  List<Friends> filteredFriends = [];
  List<Users> matchingUsers = [];
  List<Users> filteredUsers = [];
  Users? userName;
  Set<Marker> _markers = {};
  List<Users> filterUser = [];
  StreamSubscription? _users;
  StreamSubscription? _friends;
  GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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

  Future<void> _loadFriends() async {
    final userProvider = await Provider.of<CurrentUser>(context, listen: false)
        .getCurrentUserId();
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('friends');
    _friends = reference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> dataList =
              jsonDecode(jsonEncode(event.snapshot.value));
          List<Friends> users =
              dataList.values.map((item) => Friends.fromMap(item)).toList();
          setState(() {
            Friends.friends = users;
            currentUserId = userProvider;
            filteredFriends = Friends.friends
                .where((friend) =>
                    friend.request == true &&
                    (currentUserId == friend.receiverId ||
                        friend.senderId == currentUserId))
                .toList();
            mergeMarkers();
          });
        } catch (e) {
          print('Error updating state: $e');
        }
      }
    });
  }

  Future<void> allUsers() async {
    currentUser = await Provider.of<CurrentUser>(context, listen: false)
        .getCurrentUserDisplayName();
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('users');
    _users = reference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> dataList =
              jsonDecode(jsonEncode(event.snapshot.value));
          List<Users> users =
              dataList.values.map((item) => Users.fromMap(item)).toList();
          setState(() {
            Users.users = users;
            filteredUsers = List.from(Users.users);
            userName =
                filteredUsers.firstWhere((user) => currentUser == user.name);
          });
        } catch (e) {
          print('Error updating state: $e');
        }
      }
    });
  }

  void filterFriends(String category) {
    setState(() {
      if (category == "Pending") {
        filteredFriends = Friends.friends
            .where((friend) =>
                friend.request == false &&
                (currentUserId == friend.receiverId ||
                    friend.senderId == currentUserId))
            .toList();
      } else {
        // Filter users based on the selected category
        filteredFriends = Friends.friends
            .where((friend) =>
                friend.request == true &&
                (currentUserId == friend.receiverId ||
                    friend.senderId == currentUserId))
            .toList();
        // print(filteredFriends);
      }
    });
  }

  Future<Position> determinePosition() async {
    // Check if position is not yet determined
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Handle case where location services are disabled
      return Future.error('Location services are disabled.');
    }

    // Check and request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle case where location permissions are denied
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle case where location permissions are permanently denied
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Fetch the user's current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
    return position;
  }

  Future<void> mergeMarkers() async {
    Set<Marker> mergedMarkers = Set.from(_markers); // Copy existing markers
    await Future.forEach(Friends.friends, (friend) async {
      if (friend.request == true &&
          (currentUserId == friend.receiverId ||
              friend.senderId == currentUserId)) {
        mergedMarkers.add(
          Marker(
            markerId: MarkerId(
                currentUser == friend.name ? friend.senderName : friend.name),
            position: friend.currentLocation.toLatLng(),
            infoWindow: InfoWindow(
                title: currentUser == friend.name
                    ? friend.senderName
                    : friend.name),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
            // icon: await getMarkerIconFromUrl(user.imageUrl), // Replace with your image URL
          ),
        );
      }
    });
    await Future.forEach(Users.users, (user) async {
      if (currentUser == user.name) {
        mergedMarkers.add(
          Marker(
              markerId: MarkerId(user.name),
              infoWindow:
                  InfoWindow(title: currentUser == user.name ? 'You' : ''),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              position: user.currentLocation.toLatLng()),
        );
        print("Marker Added");
      }
    });
    setState(() {
      _markers = mergedMarkers;
    });
  }

  // Future<BitmapDescriptor> getMarkerIconFromUrl(String imageUrl) async {
  //   final cacheManager = DefaultCacheManager();
  //   try {
  //     final file = await cacheManager.getSingleFile(imageUrl);
  //     final bytes = await file.readAsBytes();
  //
  //     // 1. Edit image for marker shape
  //     final imageEditor = ImageEditor(memoryBytes: bytes);
  //     double markerWidth = 100; // Adjust width and height as needed for marker size
  //     double markerHeight = 100;
  //     final points = [
  //       Offset(markerWidth / 2, 0.0),
  //       Offset(0.0, markerHeight),
  //       Offset(markerWidth, markerHeight),
  //     ];
  //     final paint = Paint()..color = Colors.red; // Adjust color as needed
  //     final path = Path()..addPolygon(points);
  //     final editedImage = await imageEditor
  //         .drawImage(CopyImage(imageEditor.fullImage.width, imageEditor.fullImage.height), path: path, blendMode: BlendMode.srcIn);
  //
  //     // 2. Resize the edited image
  //     final resizedImage = await editedImage.resize(width: 50, height: 50);
  //
  //     // 3. Encode the resized image
  //     final resizedBytes = await resizedImage.readAsBytes();
  //
  //     return BitmapDescriptor.fromBytes(resizedBytes);
  //   } catch (e) {
  //     // Handle error gracefully (e.g., display a placeholder icon)
  //     print(e);
  //     return BitmapDescriptor.defaultMarker; // Or a custom placeholder icon
  //   }
  // }  @override
  @override
  void initState() {
    super.initState();
    _loadFriends();
    allUsers();
    filterFriends('friends');
    mergeMarkers();
  }

  @override
  void dispose() {
    super.dispose();
    _friends?.cancel();
    _users?.cancel();
    mapController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider =
        Provider.of<SearchUserProvider>(context, listen: false);
    final getCurrentId = Provider.of<CurrentUser>(context, listen: false);
    final getLocationProvider =
        Provider.of<GetLocationProvider>(context, listen: false);
    final getReceiversName =
        Provider.of<GetReceiversName>(context, listen: false);
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
        body: Stack(
      children: [
        GoogleMap(
            cloudMapId: 'cf2bb55d8b44b0bd',
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            onMapCreated: (controller) async {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: currentPosition,
              zoom: 8.0,
            ),
            markers: _markers),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: we,
              // height: he * 0.1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        print('Current $userName');
                        if (userName?.id != null) {
                          getAddressFromLatLng(
                                  userName?.currentLocation.toLatLng())
                              .then((current) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Profile(
                                  user: userName!.name,
                                  currentLocation: current,
                                  id: userName!.id,
                                  prevLocation: current,
                                  imageUrl: userName!.imageUrl,
                                ),
                              ),
                            );
                          }).catchError((e) {
                            print(e);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("User not logged In")));
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        radius: 25,
                        child: CachedNetworkImage(
                          imageUrl: userName?.imageUrl ??
                              'https://source.unsplash.com/user/wsanter',
                          imageBuilder: (context, imageProvider) =>
                              CircleAvatar(
                            radius: 22,
                            backgroundImage: imageProvider,
                          ),
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 225,
                      // height: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 248,
                            height: 45,
                            child: TextField(
                              maxLines: 1,
                              onChanged: (query) async {
                                try {
                                  await searchProvider.searchUsers(query);
                                  setState(() {
                                    if (query.isEmpty) {
                                      matchingUsers.clear();
                                      filterUser
                                          .clear(); // Clear the matchingUsers list
                                    } else {
                                      matchingUsers = searchProvider
                                          .searchResults
                                          .where((user) => user.name
                                              .toLowerCase()
                                              .contains(query.toLowerCase()))
                                          .toList();
                                      filterUser = matchingUsers
                                          .where((friend) =>
                                              !filteredFriends.any((ff) =>
                                                  ff.receiverId == friend.id ||
                                                  ff.senderId == friend.id))
                                          .toList();
                                    }
                                  });
                                } catch (e) {
                                  Text(e.toString());
                                }
                              },
                              controller: _controller,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                hintText: 'Search',
                              ),
                            ),
                          ),
                          if (filterUser.isNotEmpty)
                            Container(
                                width: 248,
                                height: 100,
                                color: Colors.white,
                                child: ListView.builder(
                                    physics: const ScrollPhysics(),
                                    itemCount: filterUser.length,
                                    itemBuilder: (context, index) {
                                      final searchedUser = filterUser[index];
                                      return GestureDetector(
                                        onTap: () async {
                                          String senderId = await getCurrentId
                                              .getCurrentUserId();
                                          searchProvider.getFriendIds(senderId);
                                          await getLocationProvider
                                              .selectedItem(
                                                  index, mapController);
                                          setState(() {
                                            FocusScope.of(context).unfocus();
                                            filterUser.clear();
                                            _controller.clear();
                                          });
                                        },
                                        child: ListTile(
                                            title: Text(
                                              currentUser == searchedUser.name
                                                  ? "YOU"
                                                  : searchedUser.name,
                                            ),
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
                                                        'Error: ${addressSnapshot.error}');
                                                  } else {
                                                    return Text(
                                                        addressSnapshot.data!);
                                                  }
                                                }),
                                            trailing: currentUser !=
                                                    searchedUser.name
                                                ? TextButton(
                                                    onPressed: () async {
                                                      final addProvider =
                                                          Provider.of<
                                                                  AddFriend>(
                                                              context,
                                                              listen: false);
                                                      LatLng position =
                                                          searchedUser
                                                              .currentLocation
                                                              .toLatLng();
                                                      String sender =
                                                          await getCurrentId
                                                              .getCurrentUserDisplayName();
                                                      String senderId =
                                                          await getCurrentId
                                                              .getCurrentUserId();
                                                      addProvider.friendsList(
                                                        receiverId:
                                                            searchedUser.id,
                                                        senderId: senderId,
                                                        senderImage:
                                                            userName?.imageUrl,
                                                        senderName: sender,
                                                        name: searchedUser.name,
                                                        latitude:
                                                            position.latitude,
                                                        longitude:
                                                            position.longitude,
                                                        requested: isFriend,
                                                        imageUrl: searchedUser
                                                            .imageUrl,
                                                      );
                                                      setState(() {
                                                        filterUser.clear();
                                                        _controller.clear();
                                                        FocusScope.of(context)
                                                            .unfocus();
                                                      });
                                                    },
                                                    child: const Text(
                                                      // searchedUser.id==
                                                      'Add Friend',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  )
                                                : null),
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
                        radius: 25,
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
                      icon: const Icon(Icons.zoom_out)),
                  IconButton(
                      onPressed: () {
                        mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                      icon: const Icon(Icons.zoom_in)),
                ],
              ),
            )),
        Positioned(
            top: he * 0.2,
            right: 16.0,
            child: IconButton(
                onPressed: () async {
                  await invitation(context);
                },
                icon: const Icon(
                  Icons.share,
                  size: 30,
                ))),
        Positioned(
            left: we * 0.73,
            right: 0,
            bottom: he * 0.36,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: () async {
                        try {
                          print(filteredUsers);
                          Users users = filteredUsers
                              .firstWhere((user) => currentUser == user.name);
                          LatLng location = users.currentLocation.toLatLng();
                          await getLocationProvider.getCurrentLocations(
                              location, mapController);
                        } catch (e) {
                          if (e is StateError) {
                            print(
                                'No element found in filteredUsers that satisfies the condition');
                          } else {
                            print(e);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.location_on,
                        size: 50,
                      )),
                  Expanded(
                    child: Container(
                      color: Colors.white54,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          currentUser,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                    ),
                  )
                ],
              ),
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
                  color: Colors.white70, borderRadius: BorderRadius.circular(12)
                  //color: const Color.fromRGBO(255, 255, 255, 0.5),
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisSize: MainAxisSize.min,
                children: [
                  // const Center(child: Text("Friends")),
                  ListTile(
                    title: SizedBox(
                      width: we,
                      height: 50,
                      //color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButtons(
                            text: "Friends",
                            onPressed: () {
                              filterFriends("friends");
                            },
                          ),
                          SizedBox(width: we * 0.01),

                          ElevatedButtons(
                            text: "Pending",
                            onPressed: () {
                              filterFriends('Pending');
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
                    child: filteredFriends.isNotEmpty
                        ? ListView.builder(
                            itemCount: filteredFriends.length,
                            itemBuilder: (context, index) {
                              final friend = filteredFriends[index];
                              return GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                  if (friend.request == true) {
                                    await getLocationProvider
                                        .getCurrentLocation(
                                            index, mapController);
                                    await getReceiversName.getReceiver(
                                        index, currentUser);
                                  } else {
                                    showSnackBarWarning(
                                        context, 'Friend Request pending');
                                  }
                                },
                                child: buildRow(
                                    we, friend, context, selectedIndex, index),
                              );
                            },
                          )
                        : const Center(
                            child: Text(
                              'Invite friends and Family to share Location to',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  Widget buildRow(
      double we, Friends friend, context, int index, int selectedIndex) {
    Color normalColor = Colors.white60;
    Color selectedColor = Colors.lightGreenAccent;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        // padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: index == selectedIndex ? selectedColor : normalColor,
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: CircleAvatar(
                radius: 20,
                child: CachedNetworkImage(
                  imageUrl: (currentUser == friend.name)
                      ? (friend.senderImage.isNotEmpty
                          ? friend.senderImage
                          : 'https://source.unsplash.com/user/wsanter')
                      : (friend.imageUrl.isNotEmpty
                          ? friend.imageUrl
                          : 'https://source.unsplash.com/user/wsanter'),
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 50,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.person),
                ),
              ),
            ),
            SizedBox(
              width: we * 0.45,
              height: 60,
              child: Center(
                child: ListTile(
                  title: Text(
                    currentUser == friend.name
                        ? friend.senderName
                        : friend.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: FutureBuilder(
                    future: getAddressFromLatLng(friend.currentLocation),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("Loading...");
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
            if (friend.request == false)
              const Text(
                'Pending ',
              ),
            if (friend.request == true)
              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white70),
                    child: const Center(
                      child: Icon(Icons.delete),
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
                        String current = await getAddressFromLatLng(
                            friend.currentLocation.toLatLng());
                        String prev = await getAddressFromLatLng(
                            friend.previousLocation.toLatLng());
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Profile(
                                      user: currentUser == friend.name
                                          ? friend.senderName
                                          : friend.name,
                                      currentLocation: current,
                                      id: currentUser == friend.name
                                          ? friend.senderId
                                          : friend.receiverId,
                                      prevLocation: prev,
                                      imageUrl: currentUser == friend.name
                                          ? friend.senderImage
                                          : friend.imageUrl,
                                    )));
                      },
                      icon: const Icon(Icons.send_and_archive_sharp),
                    )),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
