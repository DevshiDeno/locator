import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:locator/Auth/Create_account.dart';
import 'package:locator/Auth/resetPassword.dart';
import 'package:locator/Components/Buttons.dart';
import 'package:locator/Components/SnackBar.dart';
import 'package:locator/Components/textField.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../presentation/splashScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  User? user;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;

    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
    return Scaffold(
      //appBar: AppBar(),

      body: Stack(
        children: [
          Positioned(
              left: 50,
              right: 50,
              top: 90,
              child: Container(
                width: 150,
                height: 150,
                child: Lottie.asset('assets/Icon_location.json'),
              )),
          Positioned(
            left: 60,
            right: 40,
            top: 270,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome!',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 30,
                  ),
                ),
              ],
            ),
          ),
          //const SizedBox(height: 40),
          Positioned(
            // left: 50,
            // right: 50,
            top: 300,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Center(
                child: Container(
                  width: we * 0.95,
                  //height: he * 0.5,
                  decoration: BoxDecoration(
                      boxShadow: const [BoxShadow(color: Colors.black)],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MyTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            obscureText: false,
                            onChanged: (value) {},
                          ),
                          const SizedBox(height: 16.0),
                          MyPasswordTextField(
                            controller: _passwordController,
                            // obscureText: true,
                            labelText: 'password',
                            onChanged: (String value) {
                              _passwordController.value;
                            },
                          ),
                          // forgot password?
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: GestureDetector(
                              onTap: () async {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            PasswordResetPage()));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Forgot Password?',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          ElevatedButton(
                            onPressed: () async {
                              final provider = Provider.of<GetLocationProvider>(
                                  context,
                                  listen: false);
                              String email = _emailController.text.trim();
                              String password = _passwordController.text.trim();

                              try {
                                UserCredential userCredential =
                                    await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(
                                            email: email, password: password);

                                // print('User signed in: ${userCredential.user!.displayName}');
                                await provider.updateLocation(
                                    currentId: userCredential.user!.uid,
                                    context: context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                                );
                              } catch (e) {
                                print(e);
                                if (e is FirebaseAuthException &&
                                    e.code == 'invalid-credential') {
                                  // Show SnackBar with error message
                                  showSnackBarError(
                                      context, 'Wrong Password');
                                } else if (e is FirebaseAuthException &&
                                    e.code == 'user-not-found') {
                                  // Show SnackBar with error message
                                  showSnackBarError(context, "User with this email doesn't exist.");
                                } else {
                                  showSnackBarError(context,
                                      'An error occurred. Please try again.');
                                }
                              }
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
              right: 50,
              left: 50,
              top: 570,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                      onTap: () async {
                        await provider.signInWithGoogle(context);
                      },
                      child: const SquareTile(imagePath: 'assets/google.png')),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an Account?"),
                      //const SizedBox(height: 30),
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUp()));
                          },
                          child: const Text(
                            "SignUp.",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ))
                    ],
                  ),
                ],
              ))
        ],
      ),
    );
  }
}
