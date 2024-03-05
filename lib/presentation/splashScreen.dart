import 'package:flutter/material.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Add any initialization code here if needed
    // For example, navigation to the next screen after a delay
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
      ),
    );
  }
}
