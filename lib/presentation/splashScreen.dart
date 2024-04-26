import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key, this.currentPosition});

  LatLng? currentPosition;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = Provider.of<CurrentUser>(context, listen: false);
      String user = await currentUser.getCurrentUserId();
      Provider.of<GetLocationProvider>(context, listen: false).updateLocation(
        currentId: user, // Provide the current user's ID here
        context: context,
      );
      determinePosition();
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!_isDisposed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>
              Home(currentPosition: widget.currentPosition,)),
        );
      }
    });
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    setState(() {
      if (!_isDisposed) {
        widget.currentPosition = LatLng(position.latitude, position.longitude);
      }
    });
    return position;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
            'assets/splash.json'
        ),
      ),);
  }
}
