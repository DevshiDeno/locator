import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:locator/Auth/Create_account.dart';
import 'package:locator/Auth/login.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/firebase_options.dart';
import 'package:locator/presentation/Home.dart';
import 'package:locator/presentation/Notifications.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that Flutter is initialized before calling Firebase.initializeApp()

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SearchUserProvider()),
        ChangeNotifierProvider(create: (context) => GetReceiversName()),
        ChangeNotifierProvider(create: (context) => CurrentUser()),
        ChangeNotifierProvider(create: (context) => GoogleSignInProvider()),
        ChangeNotifierProvider(create: (context) => CurrentLocations()),
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while checking the authentication state
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            // User is signed in, navigate to HomeScreen
            return const Home();
          } else {
            // User is not signed in, navigate to LoginScreen
            return const LoginScreen();
          }
        },
      ),
    );
  }
}