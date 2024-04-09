import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locator/Components/textField.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../Components/SnackBar.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool accepted = false;
  final _formKey = GlobalKey<FormState>();
  final String termsConditions = """
Welcome to Find Me!

These terms and conditions outline the rules and regulations for the use of the Find Me mobile application, provided by D&D.

By accessing this app, we assume you accept these terms and conditions. Do not continue to use Find Me if you do not agree to take all of the terms and conditions stated on this page.

**License**

Unless otherwise stated, D&D and/or its licensors own the intellectual property rights for all material on Find Me. All intellectual property rights are reserved. You may access this from Find Me for your own personal use subjected to restrictions set in these terms and conditions.

**You must not:**

- Republish material from Find Me
- Sell, rent, or sub-license material from Find Me
- Reproduce, duplicate, or copy material from Find Me
- Redistribute content from Find Me

This Agreement shall begin on the date hereof.

Find Me offers users the opportunity to share the app with others and connect with friends by sharing their location and sending or accepting friend requests.

**User Responsibilities:**

- Users may share the Find Me app with others via social media, messaging apps, or other means.
- Users may only share their location and request to connect with friends within the app.
- Users are responsible for their interactions with friends and other users, including sharing accurate location information and respectful communication.
- Users must comply with all applicable laws and regulations while using Find Me.

D&D reserves the right to monitor user activity and take appropriate action, including the removal of content or termination of accounts, for violations of these terms and conditions.
""";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CurrentLocations>(context, listen: false);
    final userProvider = Provider.of<CurrentUser>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios)),
        centerTitle: true,
        //title: const Text('Create Account'),
      ),
      body: Stack(
        children: [
          Positioned(
              left: 50,
              right: 50,
              top: 30,
              child: SizedBox(
                width: 150,
                height: 150,
                child: Lottie.asset('assets/Icon_location.json'),
              )),
          const Positioned(
            left: 50,
            right: 50,
            top: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CREATE ACCOUNT.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 230,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      obscureText: false,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'UserName required';
                        }
                        if (value.length > 8) {
                          return 'UserName must be at most 8 characters long';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey.shade400),
                          ),
                          fillColor: Colors.grey.shade200,
                          filled: true,
                          labelText: 'Username',
                          hintStyle: TextStyle(color: Colors.grey[500])),
                      onChanged: (value) {
                        // Update the _usernameController with the new value
                        _usernameController.text = value;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    MyTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      obscureText: false,
                      onChanged: (value) {
                        _emailController.text = value.trim();
                      },
                    ),
                    const SizedBox(height: 16.0),
                    MyPasswordTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      //obscureText: false,
                      onChanged: (value) {
                        _passwordController.text = value.trim();
                      },
                    ),
                    const SizedBox(height: 32.0),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return FutureBuilder(
                                future: provider.determinePosition(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.orangeAccent,
                                      ),
                                    );
                                  } else if (accepted == true) {
                                    return AlertDialog(
                                      title: const Text('Create Account'),
                                      content: Text(
                                          'Username: ${_usernameController.text}\nEmail: ${_emailController.text}\nPassword: ${_passwordController.text}'),
                                      actions: [
                                        TextButton(
                                          onPressed: () async {
                                            String imageUrl = '';
                                            Position userPosition =
                                                await provider
                                                    .determinePosition();
                                            await provider.newUser(
                                              context: context,
                                              name: _usernameController.text,
                                              email: _emailController.text,
                                              password:
                                                  _passwordController.text,
                                              latitude: userPosition.latitude,
                                              longitude:
                                                  userPosition.longitude,
                                              imageUrl: imageUrl,
                                            );
                                            setState(() {
                                              _emailController.text = '';
                                            });
                                          },
                                          child: const Text('Create Account'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    );
                                  } else {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      showSnackBarError(context, 'Please Read and Accept the terms and Conditions');
                                    });
                                  return Container();
                                  }
                                },
                              );
                            },
                          );
                        }
                      },
                      child: const Text('Create Account'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(accepted
                            ? Icons.check_box_sharp
                            : Icons.check_box_outline_blank),
                        TextButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      content: SingleChildScrollView(
                                          child: Text(termsConditions)),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              setState(() {
                                                accepted = true;
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Accept')),
                                        TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Cancel'))
                                      ],
                                    );
                                  });
                            },
                            child: const Text('Terms & Conditions')),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
