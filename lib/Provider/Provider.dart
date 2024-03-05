import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:locator/Components/SnackBar.dart';
import 'package:locator/Model/request_location.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/presentation/Home.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:locator/presentation/splashScreen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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
        MaterialPageRoute(builder: (context) => Home()),
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
      showSnackBar(context, 'Check your Email to reset passwords');
      Navigator.pop(context);
    } catch (e) {
      showSnackBarError(context, "Error sending password reset email :$e");
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
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('users');
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('friends');
    reference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
        data?.forEach((key, value) {
          if (value['senderId'] == id) {
            reference.child(key).update({'senderImage': imageUrl});
          } else if (value['receiverId'] == id) {
            reference.child(key).update({'imageUrl': imageUrl});
          }
        });
      } else {
        print('No data found in friends');
      }
    });

    ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
        data?.forEach((key, value) {
          if (value['id'] == id) {
            ref.child(key).update({'imageUrl': imageUrl});
          }
        });
      } else {
        print('No data found in users');
      }
    });

    // Notify listeners if this method is part of a ChangeNotifier
    notifyListeners();
  }
}

class CurrentLocations extends ChangeNotifier {
  StreamSubscription<Position>? positionStream;

  Future<LatLng> startListening() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    Completer<LatLng> completer = Completer<LatLng>();
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (position != null) {
        LatLng location = LatLng(position.latitude, position.longitude);
        completer.complete(location);
        // Complete the completer with the location
      }
    });
    return completer.future;
  }

  Future<void> stopListening() async {
    positionStream?.cancel();
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
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCredential.user?.updateDisplayName(name);
    await userCredential.user?.reload();
    String id = userCredential.user!.uid;
    showSnackBar(context, "Account created");
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('users');
    ref.push().set({
      'id': id,
      "name": name,
      "email": email,
      'imageUrl': imageUrl,
      'password': password,
      'currentLocation': {'latitude': latitude, 'longitude': longitude}
    }).then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        ),
      );
    }).catchError((e) {
      print('Error creating account: $e');
      // Check if the error is due to the user already existing
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        // Show SnackBar with error message
        showSnackBar(context, "User already exists");
      }
    });
    // Navigate to the appropriate screen
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
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
      'AIzaSyBCGc5yRPH4UQUISzl6wH_IkSpRm2rGQ3k',
      PointLatLng(startingPoint.latitude, startingPoint.longitude),
      PointLatLng(endingPoint.latitude, endingPoint.longitude),
      travelMode: TravelMode.driving,
    );
    print(result.points);
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
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
    reference.onValue.listen((event) {
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
      }
    });
    return completer.future;
  }

  Future<int> getNotifications(BuildContext context) async {
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
          completer.completeError(e); // Complete the Future with an error
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
