import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/Friends.dart';
import 'package:locator/presentation/Home.dart';
import 'package:locator/presentation/Notifications.dart';
import 'package:locator/presentation/UserProfile.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  final Set<Marker>? markers;
  final String? user;
  final Set<Polyline>? polylines;

  const Home({super.key, this.polylines, this.user, this.markers});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  var currentIndex = 0;
  var index;
  late final List<Widget> screens;
  MotionTabBarController? _motionTabBarController;
  bool showBadge = true;
  int friendsCount = 0;
  List<Users> filteredUsers = [];
  Users? userName;
  String currentUser = 'user';
  String? current;
  String? previous;
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  final adUnitId = 'ca-app-pub-9922819544973761/3118792741';
   Future<int>? user;
  Future<int>? _user;

  void loadAd() {
    _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: adUnitId,
        listener: BannerAdListener(onAdLoaded: (ad) {
          print('$ad loaded');
          setState(() {
            _isLoaded = true;
          });
        }, onAdFailedToLoad: (ad, err) {
          print('failed to load $err');
          ad.dispose();
        }),
        request: const AdManagerAdRequest()
    );
    _bannerAd?.load();
  }

  Future<void> allUsers() async {
    currentUser = await Provider.of<CurrentUser>(context, listen: false)
        .getCurrentUserDisplayName();
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('users');
    reference.onValue.listen((event) async {
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

          current = await getAddressFromLatLng(userName!.currentLocation);
          previous = await getAddressFromLatLng(userName!.previousLocation);
        } catch (e) {
          print('Error updating state: $e');
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    //loadAd();
    allUsers();
    _motionTabBarController = MotionTabBarController(
        initialIndex: currentIndex, length: 4, vsync: this);
    user= AddFriend().loadFriendRequestsCount(context);
    _user= AddFriend().getNotifications(context);
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

  @override
  void dispose() {
    super.dispose();
    _motionTabBarController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Size size = MediaQuery.of(context).size;
    return Scaffold(
        body:
            Stack(
              children: [
                TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _motionTabBarController,
                    children: [
                      const MyHomePage(),
                      const Messages(),
                      const Friend(),
                      Profile(
                        user: userName?.name ?? '',
                        currentLocation: current ?? '',
                        id: userName?.id ?? '',
                        prevLocation: previous ?? '',
                        imageUrl: userName?.imageUrl ?? '',
                      ),
                    ]
                ),
                if(_bannerAd!=null)
                Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child:  Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        child: SizedBox(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      ),
                    )
                ),
              ],
            ),

        bottomNavigationBar: MotionTabBar(
          controller: _motionTabBarController,
          initialSelectedTab: 'Home',
          labels: iconTitles,
          icons: listOfIcons,
          badges: [
            null,
            FutureBuilder<int>(
              future:_user,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('');
                } else if (snapshot.hasError) {
                  return const Icon(Icons.error_outline);
                } else if (snapshot.hasData && snapshot.data != 0) {
                  return Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepOrange,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      snapshot.data.toString(),
                      // Display the friend request count
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
            FutureBuilder<int>(
              future: user,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('');
                } else if (snapshot.hasError) {
                  return const Icon(Icons.error_outline);
                } else if (snapshot.hasData && snapshot.data != 0) {
                  return Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepOrange,
                    ),
                    padding: EdgeInsets.all(2),
                    child: Text(
                      snapshot.data.toString(),
                      // Display the friend request count
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
            null
          ],
          tabSize: 50,
          tabBarHeight: 55,
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
          tabIconColor: Colors.blue[600],
          tabIconSize: 28.0,
          tabIconSelectedSize: 26.0,
          tabSelectedColor: Colors.lightGreenAccent,
          tabIconSelectedColor: Colors.white,
          tabBarColor: Colors.white,
          onTabItemSelected: (index) {
            setState(() {
              _motionTabBarController?.index = index;
              showBadge = false;
            });
          },
        )
    );
  }

  final List<IconData> listOfIcons = [
    Icons.location_on_outlined,
    Icons.chat_bubble_outline,
    Icons.person_add_alt,
    Icons.person_pin,
  ];
  final List<String> iconTitles = ['Home', 'Messages', 'Friends', 'Profile'];
  final List<Widget> badges = [];
}
