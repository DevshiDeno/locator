import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locator/Auth/Create_account.dart';
import 'package:locator/Components/textField.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/Home.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? user;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
@override
  void dispose(){
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
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
          child: Container(
            width: we * 0.95,
            //height: he * 0.5,
            decoration: BoxDecoration(
                color: Colors.black26, borderRadius: BorderRadius.circular(16)),
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      obscureText: false,
                      onChanged: (value) {},
                    ),
                    SizedBox(height: 16.0),
                    MyPasswordTextField(
                      controller: _passwordController,
                      obscureText: true,
                      hintText: 'password',
                      onChanged: (String value) {
                      _passwordController.value;
                    },
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () async {
                        String email = _emailController.text.trim();
                        String password = _passwordController.text.trim();

                        try {
                          UserCredential userCredential = await FirebaseAuth
                              .instance
                              .signInWithEmailAndPassword(
                                  email: email,
                              password: password);
                          print('User signed in: ${userCredential.user!.displayName}');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Home(
                                    )),
                          );
                        } catch (e) {
                          print('Error: $e');

                          if (e is FirebaseAuthException && e.code == 'wrong-password') {
                            // Show SnackBar with error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('User already exists'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }  else  if (e is FirebaseAuthException && e.code == 'user-not-found') {
                            // Show SnackBar with error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Incorrect email'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('An error occurred. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Login'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("SignIn with,"),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  await provider.signInWithGoogle(context);
                                },
                          child: isLoading
                              ? const Center(
                                  child: Text('...'),
                                )
                              : const Text("Google"),
                        )
                      ],
                    ),
                    const Text("Don't have an Account?"),
                    TextButton(onPressed: () {
                      Navigator.push(context,
                      MaterialPageRoute(builder: (context)=>const SignUp())
                      );
                    }, child: const Text(" SignUp."))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
