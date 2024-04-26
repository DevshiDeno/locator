import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:locator/Auth/login.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/firebase_options.dart';
import 'package:locator/presentation/splashScreen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized();

   AwesomeNotifications().initialize(
      //null,
       'resource://mipmap/find',
      [
        NotificationChannel(
            channelKey: 'alerts',
            channelName: 'Alerts',
            channelDescription: 'Notification alerts',
            playSound: true,
          onlyAlertOnce: true,
         //   groupAlertBehavior: GroupAlertBehavior.Children,
            importance: NotificationImportance.High,
            defaultPrivacy: NotificationPrivacy.Private,
            defaultColor: Colors.deepPurple,
            ledColor: Colors.deepPurple)
      ],
     // debug: true
   );
  MobileAds.instance.updateRequestConfiguration
    (
      RequestConfiguration(
      testDeviceIds: [
       '58BFAEB40298D57FC29E534656FD2755'
      ])
  );
  MobileAds.instance.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await FirebaseAppCheck.instance.activate(
  //   webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  //   androidProvider: AndroidProvider.debug,
  //   appleProvider: AppleProvider.appAttest,
  // );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ShowNotification()),
        ChangeNotifierProvider(create: (context) => AdMobProvider()),
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
      home: StreamBuilder<User?>(
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
            return  SplashScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
