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

import '../Auth/ad_helper.dart';
import '../Auth/config.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final GoogleSignInAccount? _user = GoogleSignIn().currentUser;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  GoogleSignInAccount? get user => _user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref().child('users');
  List<Locations> previousLocationsData = [];

  // Future<void> signUpWithGoogle(BuildContext context) async {
  //   try {
  //     final updateProvider = Provider.of<GetLocationProvider>(context, listen: false);
  //     final provider = Provider.of<CurrentLocations>(context, listen: false);
  //
  //     Position userPosition = await provider.determinePosition();
  //     await googleSignIn.signOut();
  //
  //     final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  //
  //     if (googleSignInAccount != null) {
  //       final GoogleSignInAuthentication googleSignInAuthentication =
  //       await googleSignInAccount.authentication;
  //
  //       final AuthCredential credential = GoogleAuthProvider.credential(
  //         accessToken: googleSignInAuthentication.accessToken,
  //         idToken: googleSignInAuthentication.idToken,
  //       );
  //
  //       final UserCredential userCredential = await _auth.signInWithCredential(credential);
  //
  //       User? user = userCredential.user;
  //
  //       // Check if the user is already linked with email/password authentication
  //       final currentUser = FirebaseAuth.instance.currentUser;
  //       if (currentUser != null &&
  //           currentUser.providerData.any((info) => info.providerId == 'password')) {
  //         // User is already signed in with email/password, inform them to sign in using that method
  //         showSnackBar(context, 'Please sign in using email/password instead.');
  //       } else {
  //         // Proceed with Google sign-up flow for new users
  //         if (user != null && userCredential.additionalUserInfo!.isNewUser) {
  //           Locations newLocation = Locations(
  //             latitude: userPosition.latitude,
  //             longitude: userPosition.longitude,
  //           );
  //           previousLocationsData.add(newLocation);
  //           Users users = Users(
  //               id: user.uid,
  //               name: user.displayName ?? "",
  //               imageUrl: user.photoURL ?? "",
  //               email: user.email ?? "",
  //               currentLocation: Locations(
  //                   latitude: userPosition.latitude,
  //                   longitude: userPosition.longitude),
  //               previousLocation: previousLocationsData);
  //           await _writeUserData(users, context);
  //           showSnackBar(context, 'Account Created');
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print(e.toString());
  //     // Handle error
  //   }
  // }

  Future<void> _writeUserData(Users user, context) async {
    try {
      List<Map<String, dynamic>> previousLocationsJson = previousLocationsData
          .map((location) => {
                'latitude': location.latitude,
                'longitude': location.longitude,
              })
          .toList();
      await _database
          .push()
          .set({
            'id': user.id,
            'name': user.name,
            'imageUrl': user.imageUrl,
            'email': user.email,
            'password': user.name,
            'currentLocation': {
              'latitude': user.currentLocation.latitude,
              'longitude': user.currentLocation.longitude
            },
            'previousLocation': previousLocationsJson
          })
          .then((_) => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => SplashScreen())))
          .catchError((error) {
            showSnackBarError(context, "Account not created");
          });
    } catch (e) {
      print("Error writing user data: $e");
    }
  }

  Future<void> resetPassword(String email, context) async {
    try {
      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showSnackBar(context, 'Check your Email to reset password');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // If user-not-found error, the email doesn't exist
        showSnackBarError(context, "Email does not exist");
      } else {
        showSnackBarError(context, "Error: ${e.message}");
      }
    } catch (e) {
      // Handle other exceptions
      showSnackBarError(context, "Error: $e");
    }
  }

  Future<void> signOut(context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    } catch (e) {
      print('error signing out $e');
    }
  }
}

class CurrentUser extends ChangeNotifier {
  List<Locations> previousLocation = [];

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
      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
      showSnackBar(context, "Account created. Email sent for verification");

      Locations newLocation = Locations(
        latitude: latitude,
        longitude: longitude,
      );
      previousLocation.add(newLocation);
      List<Map<String, dynamic>> previousLocationsJson = previousLocation
          .map((location) => {
                'latitude': location.latitude,
                'longitude': location.longitude,
              })
          .toList();
      // Store additional user data in the database
      final DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('users');
      await ref.push().set({
        'id': id,
        "name": name,
        "email": email,
        'imageUrl': imageUrl,
        'password': password,
        'currentLocation': {'latitude': latitude, 'longitude': longitude},
        'previousLocation': previousLocationsJson
      }).then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }).catchError((error) {
        showSnackBarError(context, 'Error creating account"');
        Navigator.pop(context);
      });
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

    notifyListeners();
  }

  Future<bool> checkIfNameExists(String name) async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('users');

    // Retrieve all users
    DataSnapshot snapshot = (await ref.once().then((event) => event.snapshot));
    Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;

    // Check if any user exists with the given name (case-insensitive)
    if (values != null) {
      for (var user in values.values) {
        if (user['name'].toString().toLowerCase() == name.toLowerCase()) {
          return true; // Username found
        }
      }
    }
    return false; // Username not found
  }

  Future<bool> checkIfEmailExists(String email) async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('users');

    // Retrieve all users
    DataSnapshot snapshot = (await ref.once().then((event) => event.snapshot));
    Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;

    // Check if any user exists with the given name (case-insensitive)
    if (values != null) {
      for (var user in values.values) {
        if (user['email'].toString().toLowerCase() == email.toLowerCase()) {
          return true; // Username found
        }
      }
    }
    return false; // Username not found
  }

  Future<void> linkAccounts(UserCredential emailPasswordCredential,
      UserCredential googleCredential) async {
    try {
      // Get the currently signed-in user
      User? currentUser = FirebaseAuth.instance.currentUser;

      // Link the Google credential to the email/password account
      await currentUser?.linkWithCredential(googleCredential.credential!);

      // Linking successful
      print("Accounts successfully linked");
    } catch (e) {
      // Handle account linking errors
      print("Error linking accounts: $e");
      // You can show an error message to the user or take appropriate action
    }
  }

  Future<void> addProfilePic(String id, String imageUrl) async {
    StreamSubscription? usersSubscription;
    StreamSubscription? friendsSubscription;

    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('users');
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('friends');

    friendsSubscription = reference.onValue.listen((event) {
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
      friendsSubscription!.cancel(); // Cancel the subscription after updating
    });

    usersSubscription = ref.onValue.listen((event) {
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
      usersSubscription!.cancel(); // Cancel the subscription after updating
    });

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
        // Complete the completer with the location
      }
    });
    return completer.future;
  }

  Future<void> stopListening() async {
    positionStream?.cancel();
  }

  Future<Position> determinePosition(context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Handle case where location services are disabled
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Location Services Disabled"),
            content: const Text("Please enable location services to use this app."),
            actions: <Widget>[
              ElevatedButton(
                child: const Text("OK"),
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
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
  String googleAPIKey = Config.apiKey;
  StreamSubscription? update;

  Future<void> updateLocation({required String currentId, required BuildContext context}) async {
    final provider = Provider.of<CurrentLocations>(context, listen: false);
    Position position = await provider.determinePosition(context);
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('users');
    update = ref.onValue.listen((event) {
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
      update?.cancel();
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
        zoom: 18,
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
        zoom: 18,
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
        zoom: 18,
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
      travelMode: TravelMode.walking,
    );
    polylineCoordinates.clear();

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
      {required BuildContext context,
      required String senderName,
      required String senderId,
      required String receiverId,
      required String name,
      required String imageUrl,
      required double latitude,
      required double longitude,
      required bool requested,
      required String? senderImage}) async {
    List<Locations> previousLocation = [];
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('friends');
    Locations newLocation = Locations(
      latitude: latitude,
      longitude: longitude,
    );
    previousLocation.add(newLocation);

    List<Map<String, dynamic>> previousLocationsJson = previousLocation
        .map((location) => {
              'latitude': location.latitude,
              'longitude': location.longitude,
            })
        .toList();
    ref.push().set({
      'senderName': senderName,
      'senderId': senderId,
      'senderImage': senderImage,
      'receiverId': receiverId,
      "name": name,
      'imageUrl': imageUrl,
      "request": requested,
      'currentLocation': {'latitude': latitude, 'longitude': longitude},
      'previousLocation': previousLocationsJson
    }).then((_) {
      showSnackBar(context, 'Friend request sent');
    }).catchError((error) {
      print(error);
    });
  }

  Future<int> loadFriendRequestsCount(BuildContext context) async {
    final provider = Provider.of<CurrentUser>(context, listen: false);
    currentUser = await provider.getCurrentUserId();
    receiversName = await provider.getCurrentUserDisplayName();
    String? name;
    String body='sent you a friend request!';
    String? imageUrl;
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
        for (var friendRequest in filteredRequest){
          name=friendRequest.senderName;
          imageUrl=friendRequest.imageUrl;
        }
        if(name!=null){
          AwesomeNotifications().createNotification(
              content: NotificationContent(
                  id: friendsRequestCount,
                  channelKey: 'alerts',
                  title: name,
                  wakeUpScreen:true,
                  body: body,
                  badge: friendsRequestCount+locationRequestCount,
                  largeIcon:imageUrl
              ),
              actionButtons: [
                // NotificationActionButton(key: 'REDIRECT', label: 'Redirect'),
                // NotificationActionButton(
                //     key: 'Accept',
                //     label: 'Accept request',
                //     requireInputText: true,
                //     actionType: ActionType.SilentAction,
                // ),
                NotificationActionButton(
                    key: 'DISMISS',
                    label: 'Dismiss',
                    actionType: ActionType.DismissAction,
                    isDangerousOption: true)
              ]
          );
        }

        completer.complete(friendsRequestCount);
      }
      subscription?.cancel();
    });

    return completer.future;
  }

  Future<int> getNotificationCount(context) async {
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('requests');
    StreamSubscription<DatabaseEvent>? requestsSubscription;

    final Completer<int> completer =
        Completer<int>(); // Completer to handle async completion

    requestsSubscription = reference.onValue.listen((event) async {
      final provider = Provider.of<CurrentUser>(context, listen: false);
      currentUser = await provider.getCurrentUserId();
      sendersName = await provider.getCurrentUserDisplayName();
      String? name;
      String? body;
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
                  sendersName != sender.sender &&
                  sender.isAccepted == false)
              .toList();
          locationRequestCount = messagesRequests.length;
          for(var message in messagesRequests){
             name=message.sender;
             body=message.message;
          }
          AwesomeNotifications().createNotification(
              content: NotificationContent(
                  id: locationRequestCount,
                  channelKey: 'alerts',
                  title: name,
                  wakeUpScreen:true,
                  body: body,
                  badge: locationRequestCount+friendsRequestCount,
                  largeIcon:'resource://drawable/find'
              ),
            actionButtons: [
              NotificationActionButton(key: 'REDIRECT', label: 'Redirect'),
              NotificationActionButton(
                  key: 'See',
                  label: 'View Location',
                 // requireInputText: true,
                  actionType: ActionType.SilentAction),
              NotificationActionButton(
                  key: 'DISMISS',
                  label: 'Dismiss',
                  actionType: ActionType.DismissAction,
                  isDangerousOption: true)
            ]
          );
          completer.complete(locationRequestCount); // Complete the Future with the count
        } catch (e) {
          completer.completeError(e); // Complete the Future with an error
        }
      }
      requestsSubscription?.cancel();
    });
    return completer.future;
  }

  Future<void> acceptFriend({required String senderId}) async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('friends');
    StreamSubscription<DatabaseEvent>? acceptSubscription;
    acceptSubscription=ref.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot; // Extract DataSnapshot from DatabaseEvent
      if (snapshot.value != null) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map?;

        data?.forEach((key, value) {
          if (value['senderId'] == senderId) {
            ref.child(key).update({'request': true});
          }
        });
      } else {
      }
      acceptSubscription?.cancel();
    });
    notifyListeners();
  }

  Future<void> removeFriend(
      {required BuildContext context, required String senderId}) async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('friends');
    StreamSubscription<DatabaseEvent>? removeFriendSubscription;

    removeFriendSubscription= ref.onValue.listen((event) {
      DataSnapshot snapshot =
          event.snapshot; // Extract DataSnapshot from DatabaseEvent
      if (snapshot.value != null) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map?;

        data?.forEach((key, value) {
          if (value['senderId'] == senderId) {
            ref.child(key).update({'request': false});
          }
        });
        showSnackBarWarning(context, "Friend removed");
      } else {
      }
      removeFriendSubscription?.cancel();
    });
    notifyListeners();
  }

  Future<void> acceptLocationRequest({required String receiverId}) async {
    final DatabaseReference ref =
        FirebaseDatabase.instance.ref().child('requests');
    StreamSubscription<DatabaseEvent>? acceptLocationSubscription;

    acceptLocationSubscription= ref.onValue.listen((event) async {
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
      acceptLocationSubscription?.cancel();
    });
    notifyListeners();
  }
}

class AdMobProvider extends ChangeNotifier {
  InterstitialAd? _interstitialAd;
  final adUnitId = AdHelper.interstitialAdUnitId;

  Future<void> interstitialAd() async {
    try {
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
    } catch (e) {
      print('$e error loading ad');
    }
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
        'name': friend.senderName == sender ? friend.name : friend.senderName,
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
      await provider.interstitialAd();
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
