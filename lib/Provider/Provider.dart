import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:locator/Auth/Create_account.dart';
import 'package:locator/Auth/login.dart';
import 'package:locator/Data/user_details.dart';
import 'package:locator/presentation/Home.dart';
import 'package:locator/presentation/bottom_bar.dart';
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
        MaterialPageRoute(builder: (context) => MyHomePage()),
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
}

class CurrentLocations extends ChangeNotifier {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    return position;
  }

  Future<void> newUser({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created')),
      );
      final DatabaseReference ref = FirebaseDatabase.instance.ref().child('users');
      ref.push().set({
        "name": name,
        "email": email,
        'password':password,
      }).then((_) {
        print('added to database');
      }).catchError((error) {
        print('Error adding to database: $error');
      });
      // Navigate to the appropriate screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Home(),
        ),
      );
    } catch (e) {
      print('Error creating account: $e');
      // Check if the error is due to the user already existing
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        // Show SnackBar with error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User already exists'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  notifyListeners();
}

class GetReceiversName extends ChangeNotifier {
  String? receiver;

  Future<String> getReceiver(int index) async {
    if (Users.users.isNotEmpty && index >= 0 && index < Users.users.length) {
      // Set the receiver property based on the specified index
      receiver = Users.users[index].name;

      // Notify listeners that the state has changed
      notifyListeners();
      return 'Please choose a sender';
    }
    return 'Invalid index';
  }
}
