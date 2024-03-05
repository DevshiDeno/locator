import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locator/Auth/login.dart';
import 'package:locator/Components/ListsTiles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locator/Provider/Provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:provider/provider.dart';

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

  // Future<void> locationHistory() async {
  //   final lastPosition = await Geolocator.getLastKnownPosition();
  //   if (lastPosition != null) {
  //     final DatabaseReference ref =
  //         FirebaseDatabase.instance.ref().child('users');
  //     ref.onValue.listen((event) {
  //       final data = event.snapshot.value as Map<dynamic, dynamic>?;
  //
  //       data?.forEach((key, value) {
  //         if (value['id'] == currentUser) {
  //           ref.child(key).update({
  //             'previousLocation': {
  //               'latitude': lastPosition.latitude,
  //               'longitude': lastPosition.longitude,
  //             },
  //           });
  //         }
  //       });
  //     });
  //   }
  // }

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

      if (mounted) {
        setState(() {
          _imageUrl = url;
        });
      }
    } catch (e) {
      print('Error uploading image: $e');
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

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.imageUrl;
    currentUserId();
    // locationHistory();
  }

  @override
  void dispose() {
    super.dispose();
    //  locationHistory();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
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
              child: Row(

                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
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
                      decoration: BoxDecoration(
                          color: Colors.lightGreenAccent,
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(16),
                              left: Radius.circular(16))),
                      child: Center(
                          child: Text(
                        widget.user,
                        style: TextStyle(
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
                  decoration: BoxDecoration(color: Colors.white),
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
                    shape: CircleBorder(),
                    shadowColor: Colors.black54,
                    child: CircleAvatar(
                        backgroundColor: Colors.lightGreenAccent,
                        radius: 30,
                        child: IconButton(
                            onPressed: () {}, icon: Icon(Icons.phone_sharp))),
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
                      try {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      } catch (e) {
                        print('Error logging out: $e');
                      }
                    },
                    child: Text(
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
                    shape: CircleBorder(),
                    shadowColor: Colors.black54,
                    child: CircleAvatar(
                        backgroundColor: Colors.lightGreenAccent,
                        radius: 30,
                        child: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.battery_4_bar_rounded))),
                  ),
                ),
              ],
            ),
          ),
      ]),
    );
  }
}
