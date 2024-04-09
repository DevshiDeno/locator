import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:locator/Components/ListsTiles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locator/Components/SnackBar.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

class Profile extends StatefulWidget {
  final String user;
  final String currentLocation;
  final String prevLocation;
  final String id;
  final String imageUrl;

  const Profile({
    super.key,
    required this.user,
    required this.currentLocation,
    required this.id,
    required this.prevLocation,
    required this.imageUrl,
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  File? _imageFile;
  String? currentUser;
  Position? lastPosition;
  List<Position> lastPositionList = [];
  String? _imageUrl;
  List<Friends> emergencyContacts = [];
  List<Friends> filteredFriends = [];
  bool added = false;
  bool respond = false;
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('users');
  StreamSubscription? _location;
  StreamSubscription? _friends;

  Future<void> locationHistory() async {
    lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null) {
      _location = ref.onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        data?.forEach((key, value) {
          if (value['id'] == currentUser) {
            double previousLatitude = value['currentLocation']['latitude'];
            double previousLongitude = value['currentLocation']['longitude'];
            if (previousLatitude != lastPosition?.latitude ||
                previousLongitude != lastPosition?.longitude) {
              ref.child(key).update({
                'previousLocation': {
                  'latitude': lastPosition?.latitude,
                  'longitude': lastPosition?.longitude,
                },
              });
            }
          }
        });
      });
    }
  }

  Future<void> uploadImage(File imageFile) async {
    try {
      final currentId = await Provider.of<CurrentUser>(context, listen: false)
          .getCurrentUserId();
      final String currentName =
          await Provider.of<CurrentUser>(context, listen: false)
              .getCurrentUserDisplayName();
      final FirebaseStorage storage = FirebaseStorage.instance;
      final Reference storageRef =
          storage.ref().child('images').child(currentName).child('profile.png');
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot downloadUrl = await uploadTask;
      final String url = await downloadUrl.ref.getDownloadURL();

      await Provider.of<CurrentUser>(context, listen: false)
          .addProfilePic(currentId, url);
      setState(() {
        _imageUrl = url;
      });
      showSnackBar(context, 'Profile Image changed!');
    } catch (e) {
      showSnackBarError(context, "Error uploading image $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      // Do something with the selected image
      setState(() {
        _imageFile = File(pickedImage.path);
      });
      await uploadImage(_imageFile!);
    }
  }

  Future<void> currentUserId() async {
    final currentId = await Provider.of<CurrentUser>(context, listen: false)
        .getCurrentUserId();

    setState(() {
      currentUser = currentId;
    });
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
            filteredFriends = Friends.friends
                .where((friend) =>
                    friend.request == true &&
                    (userProvider == friend.receiverId ||
                        friend.senderId == userProvider))
                .toList();
          });
        } catch (e) {
          print('Error updating state: $e');
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.imageUrl;
    currentUserId();
    locationHistory();
    _loadFriends();
  }

  @override
  void dispose() {
    super.dispose();
    _location?.cancel();
    _friends?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
    final providerSos = Provider.of<ShowNotification>(context, listen: false);

    return Scaffold(
      body: Stack(children: [
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                //color: Colors.green,
              ),
              width: we,
              height: he * 0.08,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: he * 0.15,
          child: CircleAvatar(
            backgroundColor: Colors.blueGrey,
            radius: 53,
            child: CachedNetworkImage(
              imageUrl: _imageUrl ?? widget.imageUrl,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: 50,
                backgroundImage: imageProvider,
              ),
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.person),
            ),
          ),
        ),
        if (currentUser == widget.id)
          Positioned(
              left: 53,
              right: 0,
              top: he * 0.23,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: IconButton(
                        onPressed: () async {
                          await _pickImage();
                        },
                        icon: const Icon(Icons.add_a_photo_outlined)),
                  ),
                ),
              )),
        Positioned(
          left: 0,
          right: 0,
          top: he * 0.3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: we,
                height: 100,
                //color: Colors.lightGreenAccent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        elevation: 5.0,
                        shape: CircleBorder(),
                        shadowColor: Colors.black54,
                        child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                            child: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.info_outline))),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 30,
                      decoration: const BoxDecoration(
                          color: Colors.lightGreenAccent,
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(16),
                              left: Radius.circular(16))),
                      child: Center(
                          child: Text(
                        widget.user,
                        style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                            decoration: TextDecoration.none),
                      )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        elevation: 5.0,
                        shape: CircleBorder(),
                        shadowColor: Colors.black54,
                        child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                            child: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.chat_outlined))),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: we,

                  //height: 180,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      const ListTiles(
                          text: "Now at",
                          icon: Icon(Icons.location_on_outlined)),
                      ListTiles(
                        text: widget.currentLocation,
                        dateTime: DateTime.now(),
                      ),
                      // ListTiles(text: "School"),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: we,
                  height: 200,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ListTiles(
                            text: "Last Updates",
                            icon: Icon(
                              Icons.arrow_circle_up_rounded,
                              size: 20,
                            )),
                        ListTiles(
                          text: widget.prevLocation,
                          dateTime: DateTime.now(),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        if (currentUser == widget.id)
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Material(
                    elevation: 5.0,
                    shape: const CircleBorder(),
                    shadowColor: Colors.black54,
                    child: CircleAvatar(
                        backgroundColor: Colors.lightGreenAccent,
                        radius: 30,
                        child: IconButton(
                            onPressed: () async {
                              final userProvider =
                                  await Provider.of<CurrentUser>(context,
                                          listen: false)
                                      .getCurrentUserDisplayName();
                              String message =
                                  'Emergency! Help needed at ${widget.currentLocation}';
                              if (filteredFriends.isNotEmpty) {
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                          content: SizedBox(
                                              //height: he * 0.3,
                                              width: we * 0.8,
                                              // color: Colors.lightGreen,
                                              child: ListView.builder(
                                                  shrinkWrap: true,
                                                  // Use shrinkWrap property
                                                  itemCount:
                                                      filteredFriends.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final contact =
                                                        filteredFriends[index];
                                                    return ListTile(
                                                      title: Text(
                                                        widget.user ==
                                                                contact.name
                                                            ? contact.senderName
                                                            : contact.name,
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      trailing: TextButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            if (emergencyContacts
                                                                .contains(
                                                                    contact)) {
                                                              // If 'contact' is already in 'emergencyContacts', remove it and set 'added' to false
                                                              emergencyContacts
                                                                  .remove(
                                                                      contact);
                                                              added = false;
                                                            } else {
                                                              // If 'contact' is not in 'emergencyContacts', add it and set 'added' to true
                                                              emergencyContacts
                                                                  .add(contact);
                                                              added = true;
                                                            }
                                                          });
                                                        },
                                                        child: added
                                                            ? const Icon(
                                                                Icons.check_box)
                                                            : const Icon(Icons
                                                                .check_box_outline_blank),
                                                      ),
                                                    );
                                                  })),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('cancel')),
                                            if (filteredFriends.isNotEmpty)
                                              TextButton(
                                                  onPressed: () {
                                                    if (emergencyContacts
                                                        .isNotEmpty) {
                                                      providerSos.sendSos(
                                                          userProvider,
                                                          emergencyContacts,
                                                          message,
                                                          lastPosition!
                                                              .latitude,
                                                          lastPosition!
                                                              .longitude,
                                                          DateTime.now(),
                                                          context);
                                                      setState(() {
                                                        emergencyContacts
                                                            .clear();
                                                        added = false;
                                                      });
                                                    }
                                                  },
                                                  child: const Text('Send'))
                                          ],
                                        ));
                              } else {
                                showSnackBarWarning(context,
                                    "You current Have no Friends to send an SOS message to!!");
                              }
                            },
                            icon: const Icon(Icons.sos_outlined))),
                  ),
                ),
                Container(
                  width: 100,
                  height: 30,
                  decoration: const BoxDecoration(
                      color: Colors.lightGreenAccent,
                      borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(16),
                          left: Radius.circular(16))),
                  child: Center(
                      child: GestureDetector(
                    onTap: () async {
                      await provider.signOut(context);
                    },
                    child: const Text(
                      "Log Out",
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          decoration: TextDecoration.none),
                    ),
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Material(
                    elevation: 5.0,
                    shape: const CircleBorder(),
                    shadowColor: Colors.black54,
                    child: CircleAvatar(
                        backgroundColor: Colors.lightGreenAccent,
                        radius: 30,
                        child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.battery_4_bar_rounded))),
                  ),
                ),
              ],
            ),
          ),
      ]),
    );
  }
}
