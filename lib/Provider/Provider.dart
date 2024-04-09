import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:locator/Auth/login.dart';
import 'package:locator/Components/SnackBar.dart';
import 'package:locator/Model/request_location.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:locator/presentation/splashScreen.dart';
import 'package:provider/provider.dart';

class GoogleSignInProvider extends ChangeNotifier {
  GoogleSignInAccount? _user = GoogleSignIn().currentUser;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  GoogleSignInAccount? get user => _user;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithGoogle(context) async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> signIn() async {
    try {
      final account = await googleSignIn.signIn();
      if (account != null) {
        _user = account;
      }
    } catch (e) {
      print("Error during Google sign-in: $e");
    }
  }

  Future<void> resetPassword(String email, context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showSnackBar(context, 'Check your Email to reset password');
      Navigator.pop(context);
    } catch (e) {
      showSnackBarError(context, "Invalid Email");
    }
  }

  Future<void> signOut(context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    } catch (e) {
      print('error signing out $e');
    }
  }
}

class CurrentUser extends ChangeNotifier {
  Future<String> getCurrentUserDisplayName() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String displayName = user.displayName ?? 'No Display Name';
      return displayName;
    } else {
      print('User not logged in');
      return 'No Display Name';
    }
  }

  Future<String> getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;
      return userId;
    } else {
      print('User not logged in');
      return 'Unknown user';
    }
  }

  Future<void> addProfilePic(String id, String imageUrl) async {
    StreamSubscription? _usersSubscription;
    StreamSubscription? _friendsSubscription;

    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('users');
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('friends');
    _friendsSubscription = reference.onValue.listen((event) {
      final friendData = event.snapshot.value as Map?;
      if (friendData != null) {
        friendData.forEach((key, value) {
          if (value['senderId'] == id) {
            reference.child(key).update({'senderImage': imageUrl});
          } else if (value['receiverId'] == id) {
            reference.child(key).update({'imageUrl': imageUrl});
          }
        });
      }
    });
    // _usersSubscription =
    ref.onValue.listen((event) {
      final userData = event.snapshot.value as Map?;
      if (userData != null) {
        userData.forEach((key, value) {
          if (value['id'] == id) {
            ref.child(key).update({'imageUrl': imageUrl});
          }
        });
      } else {
        print('No data found in users');
      }
    });
    // _usersSubscription.cancel();
    _friendsSubscription.cancel();
    notifyListeners();
  }
}

class CurrentLocations extends ChangeNotifier {
  StreamSubscription<Position>? positionStream;

  Future<LatLng> startListening() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 100,
    );
    Completer<LatLng> completer = Completer<LatLng>();
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (position != null) {
        LatLng location = LatLng(position.latitude, position.longitude);
        completer.complete(location);
        print(location);
        // Complete the completer with the location
      }
    });
    return completer.future;
  }

  Future<void> stopListening() async {
    positionStream?.cancel();
    print('cancelled');
  }

  Future<Position> determinePosition() async {
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
      desiredAccuracy: LocationAccuracy.medium,
    );
    return position;
  }

  Future<void> newUser({
    required BuildContext context,
    required String name,
    required String email,
    required String imageUrl,
    required String password,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Attempt to create a new user account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user display name
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      // Get user ID
      String id = userCredential.user!.uid;

      // Show success message
      showSnackBar(context, "Account created");

      // Store additional user data in the database
      final DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('users');
      await ref.push().set({
        'id': id,
        "name": name,
        "email": email,
        'imageUrl': imageUrl,
        'password': password,
        'currentLocation': {'latitude': latitude, 'longitude': longitude}
      });

      // Navigate to the appropriate screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        ),
      );
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        Navigator.pop(context);
        showSnackBarError(
            context, "The email address is already in use by another account.");
      } else {
        Navigator.pop(context);
        showSnackBarError(
            context, "An error occurred while creating the account.");
      }
    }
  }

  @override
  notifyListeners();
}

class GetReceiversName extends ChangeNotifier {
  //String? sendersName;
  String? receiver;

  Future<String> getReceiver(index, String userProvider) async {
    if (Friends.friends.isNotEmpty &&
        index >= 0 &&
        index < Friends.friends.length) {
      if (userProvider == Friends.friends[index].name) {
        receiver = Friends.friends[index].senderId.toString();
      } else {
        receiver = Friends.friends[index].receiverId.toString();
      }
      notifyListeners();
      return 'Please choose a sender';
    } else if (Friends.friends.isEmpty) {}
    return 'Invalid index';
  }
}

class SearchUserProvider extends ChangeNotifier {
  final DatabaseReference _reference =
      FirebaseDatabase.instance.ref().child('users');

  // final DatabaseReference ref =
  //     FirebaseDatabase.instance.ref().child('friends');
  List<Users> searchResults = [];
  List<Friends> friendsId = [];
  List<Friends> filterfriendsId = [];
  bool isFriend = false;

  Future getFriendIds(String currentId) async {
    try {
      _reference.onValue.listen((event) {
        if (event.snapshot.value != null) {
          try {
            Map<String, dynamic> friendList =
                jsonDecode(jsonEncode(event.snapshot.value));
            friendsId =
                friendList.values.map((item) => Friends.fromMap(item)).toList();
            filterfriendsId = friendsId
                .where((id) =>
                    id.senderId == currentId ||
                    id.receiverId == currentId && id.request == true)
                .toList();
            if (filterfriendsId.isNotEmpty) {
              isFriend = true;
            } else {
              isFriend = false;
            }
            notifyListeners();
            // print('my friends $filterfriendsId');
          } catch (error) {
            "Error getting users: $error";
          }
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future searchUsers(String query) async {
    if (query.isNotEmpty) {
      _reference.onValue.listen((event) async {
        if (event.snapshot.value != null) {
          try {
            Map<String, dynamic> searchList =
                jsonDecode(jsonEncode(event.snapshot.value));
            searchResults =
                searchList.values.map((item) => Users.fromMap(item)).toList();
            notifyListeners();
          } catch (error) {
            "Error searching users: $error";
          }
        }
      });
    }
  }
}

class GetLocationProvider extends ChangeNotifier {
  String? address;
  Set<Marker> markers = {};
  Set<Polyline> polyline = {};
  LatLng? currentPosition;
  List<LatLng> polylineCoordinates = [];
  String googleAPIKey = "AIzaSyBoITIzaKF1njfhL3AVj_yNGN3XpzpcHHA";

  Future<void> updateLocation(
      {required String currentId, required BuildContext context}) async {
    final provider = Provider.of<CurrentLocations>(context, listen: false);
    Position position = await provider.determinePosition();
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('users');
    ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map?;

        data?.forEach((key, value) {
          if (value['id'] == currentId) {
            ref.child(key).update({
              'currentLocation': {
                'latitude': position.latitude,
                'longitude': position.longitude
              }
            });
          }
        });
      } else {
        print('No data found');
      }
    });
    notifyListeners();
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

      CameraPosition position = CameraPosition(
        target: location,
        zoom: 16,
      );

      mapController?.animateCamera(CameraUpdate.newCameraPosition(position));
      markers = markers;
      notifyListeners();
    } catch (e) {
      "Error getting address: $e";
    }
  }

  Future<void> getCurrentLocation(
      index, GoogleMapController? mapController) async {
    LatLng location = Friends.friends[index].currentLocation.toLatLng();

    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      address = placeMarks.isNotEmpty
          ? placeMarks[0].thoroughfare ?? "Unknown Place"
          : "Unknown Place";

      CameraPosition position = CameraPosition(
        target: location,
        zoom: 16,
      );
      mapController?.animateCamera(CameraUpdate.newCameraPosition(position));
      markers = markers;
      notifyListeners();
    } catch (e) {
      "Error getting address: $e";
    }
  }

  Future<void> getCurrentLocations(
      LatLng location, GoogleMapController? mapController) async {
    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      address = placeMarks.isNotEmpty
          ? placeMarks[0].thoroughfare ?? "Unknown Place"
          : "Unknown Place";
      currentPosition = location;
      CameraPosition position = CameraPosition(
        target: location,
        zoom: 16,
      );

      mapController?.animateCamera(CameraUpdate.newCameraPosition(position));
      markers = markers;
      notifyListeners();
    } catch (e) {
      "Error getting address: $e";
    }
  }

  Future<void> addPolyline(LatLng startingPoint, LatLng endingPoint) async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPIKey,
      PointLatLng(startingPoint.latitude, startingPoint.longitude),
      PointLatLng(endingPoint.latitude, endingPoint.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    polyline.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylineCoordinates,
        width: 5,
        color: Colors.blue,
      ),
    );
  }
}

class AddFriend extends ChangeNotifier {
  List<Friends> filteredFriends = [];
  bool isAccepted = false;
  String? currentUser;
  String? receiversName;
  List<Friends> filteredRequest = [];
  int friendsCount = 0;
  int friendsRequestCount = 0;
  List<RequestLocation> messagesRequests = [];
  String? sendersName;
  int locationRequestCount = 0;

  Future friendsList(
      {required String senderName,
      required String senderId,
      required String receiverId,
      required String name,
      required String imageUrl,
      required double latitude,
      required double longitude,
      required bool requested,
      required String? senderImage}) async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('friends');

    ref
        .push()
        .set({
          'senderName': senderName,
          'senderId': senderId,
          'senderImage': senderImage,
          'receiverId': receiverId,
          "name": name,
          'imageUrl': imageUrl,
          "request": requested,
          'currentLocation': {'latitude': latitude, 'longitude': longitude},
          'previousLocation': {'latitude': latitude, 'longitude': longitude}
        })
        .then((_) {})
        .catchError((error) {
          print(error);
        });
  }

  Future<int> loadFriendRequestsCount(BuildContext context) async {
    final provider = Provider.of<CurrentUser>(context, listen: false);
    currentUser = await provider.getCurrentUserId();
    receiversName = await provider.getCurrentUserDisplayName();
    Completer<int> completer = Completer<int>();
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('friends');
    StreamSubscription<DatabaseEvent>? subscription;

    subscription = reference.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<String, dynamic> dataList = jsonDecode(jsonEncode(snapshot.value));
        List<Friends> friend =
            dataList.values.map((item) => Friends.fromMap(item)).toList();
        Friends.friends = friend;
        filteredFriends = List.from(Friends.friends);
        filteredRequest = filteredFriends
            .where((receiver) =>
                currentUser == receiver.receiverId &&
                isAccepted == receiver.request)
            .toList();

        friendsRequestCount = filteredRequest.length;
        completer.complete(friendsRequestCount);

        // Cancel the subscription after completing the completer
      }
    });
    subscription.cancel();

    return completer.future;
  }

  Future<int> getNotifications(context) async {
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('requests');

    final Completer<int> completer =
        Completer<int>(); // Completer to handle async completion

    reference.onValue.listen((event) async {
      final provider = Provider.of<CurrentUser>(context, listen: false);
      currentUser = await provider.getCurrentUserId();
      sendersName = await provider.getCurrentUserDisplayName();
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> dataList =
              jsonDecode(jsonEncode(event.snapshot.value));
          List<RequestLocation> requests = dataList.values
              .map((item) => RequestLocation.fromMap(item))
              .toList();
          RequestLocation.requested = requests;
          messagesRequests = RequestLocation.requested
              .where((sender) =>
                  currentUser == sender.receivingRequest &&
                  sendersName != sender.sender)
              .toList();
          locationRequestCount = messagesRequests.length;
          completer.complete(
              locationRequestCount); // Complete the Future with the count
        } catch (e) {
          // completer.completeError(e); // Complete the Future with an error
        }
      }
    });
    return completer.future;
  }

  Future<void> acceptFriend({required String senderId}) async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('friends');

    ref.onValue.listen((event) {
      DataSnapshot snapshot =
          event.snapshot; // Extract DataSnapshot from DatabaseEvent

      if (snapshot.value != null) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map?;

        data?.forEach((key, value) {
          if (value['senderId'] == senderId) {
            ref.child(key).update({'request': true});
          }
        });
      } else {
        //print('No data found');
      }
    });
  }

  Future<void> removeFriend(
      {required BuildContext context, required String senderId}) async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('friends');

    ref.onValue.listen((event) {
      DataSnapshot snapshot =
          event.snapshot; // Extract DataSnapshot from DatabaseEvent

      if (snapshot.value != null) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map?;

        data?.forEach((key, value) {
          if (value['senderId'] == senderId) {
            ref.child(key).update({'request': false});
          }
        });
        showSnackBar(context, "Friend removed");
      } else {
        print('No data found');
      }
    });
    notifyListeners();
  }

  Future<void> acceptLocationRequest({required String receiverId}) async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('requests');
    ref.onValue.listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map?;

        data?.forEach((key, value) {
          if (value['receivingRequest'] == receiverId) {
            ref.child(key).update({'isAccepted': true});
          }
        });
        await Future.delayed(const Duration(seconds: 1)); // Simulating a delay
      } else {
        print('No data found');
      }
    });
    notifyListeners();
  }
}

class AdMobProvider extends ChangeNotifier {
  InterstitialAd? _interstitialAd;
  final adUnitId = '/6499/example/interstitial';

  Future<void> interstitialAd() async {
    InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialAd?.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
    notifyListeners();
  }
}

class ShowNotification extends ChangeNotifier {
  String? currentUser;
  String? senderName;

  Future<void> sendSos(
      String sender,
      List<Friends> receiver,
      String message,
      double latitude,
      double longitude,
      DateTime dateTime,
      BuildContext context) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref().child('SOS');
    List<Map<String, dynamic>> receiversData = receiver.map((friend) {
      return {
        'id': friend.senderId,
        'name': friend.senderName,
        'request': friend.request
      };
    }).toList();
    ref.push().set({
      'sendersName': sender,
      'receiver': receiversData,
      'message': message,
      'currentLocation': {'latitude': latitude, 'longitude': longitude},
      'dateTime': dateTime.toUtc().toString()
    }).then((_) async {
      final provider = Provider.of<AdMobProvider>(context, listen: false);
      //await provider.interstitialAd();
      Future.delayed(const Duration(seconds: 2));
      showSnackBarSos(context, 'SOS sent!');
      Navigator.pop(context);
      //shares location
    }).catchError((error) {
      Navigator.pop(context);
      showSnackBarError(context, 'Error sending SOS,Try again! $error');
    });
  }
}
