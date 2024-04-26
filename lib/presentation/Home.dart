import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:locator/Components/Buttons.dart';
import 'package:locator/Components/SnackBar.dart';
import 'package:locator/Components/showDialog.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/UserProfile.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.currentPosition});

  final LatLng? currentPosition;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isFriend = false;
  int selectedIndex = 0;
  String currentUser = 'user';
  String? currentUserId;
  LatLng? currentPosition;
  GoogleMapController? mapController;
  final TextEditingController _controller = TextEditingController();
  BitmapDescriptor? customMarker;
  String? address;
  String? prev;
  List<Friends> filteredFriends = [];
  List<Users> matchingUsers = [];
  List<Users> filteredUsers = [];
  Users? userName;
  Set<Marker> _markers = {};
  Set<Marker> mergedMarker = {};
  List<Users> filterUser = [];
  StreamSubscription? _users;
  StreamSubscription? _friends;
  bool isSatelliteView = false;
  List<String> lastLocation = [];

  void _toggleMapType() {
    setState(() {
      isSatelliteView = !isSatelliteView;
    });
  }

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
    currentUserId = await Provider.of<CurrentUser>(context, listen: false)
        .getCurrentUserId();
    currentUser = await Provider.of<CurrentUser>(context, listen: false)
        .getCurrentUserDisplayName();
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('users');
    _users = reference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        if (kDebugMode) {}
        try {
          Map<String, dynamic> dataList =
              jsonDecode(jsonEncode(event.snapshot.value));

          List<Users> users =
              dataList.values.map((item) => Users.fromMap(item)).toList();
          setState(() {
            Users.users = users;
            filteredUsers = List.from(Users.users);
            userName =
                filteredUsers.firstWhere((user) => currentUserId == user.id);
            mergeMarkers();
          });
        } catch (e) {
          print('Error updating state of all users: $e');
        }
      }
      _users?.cancel();
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
      }
    });
  }

  Future<BitmapDescriptor> getCustomMarkerIcon(String imageUrl) async {
    const ImageConfiguration config = ImageConfiguration();
    final Completer<BitmapDescriptor> completer = Completer<BitmapDescriptor>();

    final ImageStream stream = NetworkImage(imageUrl).resolve(config);
    stream.addListener(ImageStreamListener((ImageInfo image, bool _) async {
      final ByteData? byteData =
          await image.image.toByteData(format: ImageByteFormat.png);
      final Uint8List? pngBytes = byteData?.buffer.asUint8List();
      final List<int> compressedBytes =
          await FlutterImageCompress.compressWithList(
        pngBytes!,
        minHeight: 80,
        minWidth: 50,
        quality: 70,
      );

      final BitmapDescriptor bitmapDescriptor =
          BitmapDescriptor.fromBytes(Uint8List.fromList(compressedBytes));

      completer.complete(bitmapDescriptor);
    }));
    return completer.future;
  }

  Future<void> mergeMarkers() async {
    try {
      mergedMarker.clear();
      await Future.forEach(Friends.friends, (friend) async {
        if (friend.request == true &&
            (currentUserId == friend.receiverId ||
                friend.senderId == currentUserId)) {
          mergedMarker.add(Marker(
              markerId: MarkerId(
                  currentUser == friend.name ? friend.senderName : friend.name),
              position: friend.currentLocation.toLatLng(),
              infoWindow: InfoWindow(
                title: currentUser == friend.name
                    ? friend.senderName
                    : friend.name,
              ),
              // await getCustomMarkerIcon(friend.imageUrl)
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRose)));
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    await Future.forEach(Users.users, (user) async {
      if (currentUser == user.name) {
        mergedMarker.add(
          Marker(
              markerId: MarkerId(user.name),
              infoWindow:
                  InfoWindow(title: currentUser == user.name ? 'You' : ''),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueMagenta),

              // await getCustomMarkerIcon(user.imageUrl),
              position: user.currentLocation.toLatLng()),
        );
      }
    });
    setState(() {
      _markers = mergedMarker;
    });
  }

  @override
  void initState() {
    super.initState();
    currentPosition = widget.currentPosition;
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          //leading: Icon(Icons.abc),
        ),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: GoogleMap(

                  cloudMapId: 'cf2bb55d8b44b0bd',
                  mapType: isSatelliteView ? MapType.satellite : MapType.normal,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) async {
                    mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: currentPosition ?? const LatLng(0.0, 0.0),
                    zoom: isSatelliteView ? 16 : 18,
                  ),
                  markers: _markers),
            ),
            Positioned(
              top: 0,
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
                          onTap: () async {
                            if (userName?.id != null) {
                              for (var previousLocation
                                  in userName!.previousLocation) {
                                prev = await getAddressFromLatLng(
                                    previousLocation);
                                lastLocation.add(prev!);
                              }
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
                                      prevLocation: lastLocation,
                                      imageUrl: userName!.imageUrl,
                                    ),
                                  ),
                                );
                                lastLocation.clear();
                              }).catchError((e) {
                                print(e);
                              });
                            } else {
                              showSnackBarError(context, 'User not logged In');
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.blueGrey,
                            radius: 25,
                            child: CachedNetworkImage(
                              imageUrl: userName?.imageUrl ?? 'assets/error.png',
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                radius: 22,
                                backgroundImage: imageProvider,
                              ),
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
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
                                                  .contains(
                                                      query.toLowerCase()))
                                              .toList();
                                          filterUser = matchingUsers
                                              .where((friend) =>
                                                  !filteredFriends.any((ff) =>
                                                      ff.receiverId ==
                                                          friend.id ||
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
                                          final searchedUser =
                                              filterUser[index];
                                          return GestureDetector(
                                            onTap: () async {
                                              String senderId =
                                                  await getCurrentId
                                                      .getCurrentUserId();
                                              searchProvider
                                                  .getFriendIds(senderId);
                                              await getLocationProvider
                                                  .selectedItem(
                                                      index, mapController);
                                              setState(() {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                filterUser.clear();
                                                _controller.clear();
                                              });
                                            },
                                            child: ListTile(
                                                title: Text(
                                                  currentUser ==
                                                          searchedUser.name
                                                      ? "YOU"
                                                      : searchedUser.name,
                                                ),
                                                subtitle: FutureBuilder(
                                                    future:
                                                        getAddressFromLatLng(
                                                            searchedUser
                                                                .currentLocation
                                                                .toLatLng()),
                                                    builder: (context,
                                                        addressSnapshot) {
                                                      if (addressSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const Center(
                                                            child:
                                                                CircularProgressIndicator());
                                                      } else if (addressSnapshot
                                                          .hasError) {
                                                        return Text(
                                                            'Error: ${addressSnapshot.error}');
                                                      } else {
                                                        return Text(
                                                            addressSnapshot
                                                                .data!);
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
                                                                  listen:
                                                                      false);
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
                                                          addProvider
                                                              .friendsList(
                                                            receiverId:
                                                                searchedUser.id,
                                                            senderId: senderId,
                                                            senderImage:
                                                                userName
                                                                    ?.imageUrl,
                                                            senderName: sender,
                                                            name: searchedUser
                                                                .name,
                                                            latitude: position
                                                                .latitude,
                                                            longitude: position
                                                                .longitude,
                                                            requested: isFriend,
                                                            imageUrl:
                                                                searchedUser
                                                                    .imageUrl,
                                                            context: context,
                                                          );
                                                          setState(() {
                                                            filterUser.clear();
                                                            _controller.clear();
                                                            FocusScope.of(
                                                                    context)
                                                                .unfocus();
                                                          });
                                                        },
                                                        child: const Text(
                                                          // searchedUser.id==
                                                          'Add Friend',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
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
                                icon:
                                    const Icon(Icons.share_location_rounded))),
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
                            mapController
                                ?.animateCamera(CameraUpdate.zoomOut());
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
                child: CircleAvatar(
                  backgroundColor:
                      isSatelliteView ? Colors.white : Colors.lightGreenAccent,
                  radius: 25,
                  child: IconButton(
                      onPressed: () async {
                        _toggleMapType();
                      },
                      icon: const Icon(
                        Icons.layers,
                        size: 30,
                      )),
                )),
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
                              Users users = filteredUsers.firstWhere(
                                  (user) => currentUser == user.name);
                              LatLng location =
                                  users.currentLocation.toLatLng();
                              await getLocationProvider.getCurrentLocations(
                                  location, mapController);
                            } catch (e) {
                              if (e is StateError) {
                                if (kDebugMode) {
                                  print(
                                      'No element found in filteredUsers that satisfies the condition');
                                }
                              } else {
                                if (kDebugMode) {
                                  print(e);
                                }
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.location_on,
                            size: 50,
                          )),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            currentUser,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: isSatelliteView
                                    ? Colors.black87
                                    : Colors.black),
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
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisSize: MainAxisSize.min,
                    children: [
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
                                    child: buildRow(we, friend, context,
                                        selectedIndex, index),
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
                          : '')
                      : (friend.imageUrl.isNotEmpty ? friend.imageUrl : 'assets/error.png'),
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 50,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const CircleAvatar(radius: 50, child: Icon(Icons.person)),
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
                  SizedBox(width: we * 0.1),
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
                        for (var previousLocation in friend.previousLocation) {
                          prev = await getAddressFromLatLng(previousLocation);
                           lastLocation.add(prev!);
                        }
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
                                      prevLocation: lastLocation,
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
