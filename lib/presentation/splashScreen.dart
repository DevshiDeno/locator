import 'package:flutter/material.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isDisposed = false;
  Future? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
        final currentUser = Provider.of<CurrentUser>(context, listen: false);
        String user=await currentUser.getCurrentUserId();
      Provider.of<GetLocationProvider>(context, listen: false).updateLocation(
        currentId: user, // Provide the current user's ID here
        context: context,
      );
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!_isDisposed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    });
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
