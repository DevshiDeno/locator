import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:locator/Auth/login.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/firebase_options.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:locator/presentation/splashScreen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that Flutter is initialized before calling Firebase.initializeApp()

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.appAttest,
  );


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SearchUserProvider()),
        ChangeNotifierProvider(create: (context) => GetReceiversName()),
        ChangeNotifierProvider(create: (context) => CurrentUser()),
        ChangeNotifierProvider(create: (context) => GoogleSignInProvider()),
        ChangeNotifierProvider(create: (context) => CurrentLocations()),
        ChangeNotifierProvider(create: (context) => GetLocationProvider()),
        ChangeNotifierProvider(create: (context) => AddFriend()),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Error occurred. Please try again later.'),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            // Do whatever you want with the user object here
            return const SplashScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
