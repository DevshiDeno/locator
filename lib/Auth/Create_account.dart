import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:locator/Components/textField.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:provider/provider.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CurrentLocations>(context, listen: false);
    final userProvider=Provider.of<CurrentUser>(context,listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                obscureText: false,
                decoration: InputDecoration(
                  labelText: 'Username',
                ),
                onChanged: (value) {
                  // Update the _usernameController with the new value
                  _usernameController.text = value;
                },
              ),
              const SizedBox(height: 16.0),
              MyTextField(
                controller: _emailController,
                hintText: 'Email',
                obscureText: false,
                onChanged: (value) {
                  // Update the _emailController with the new value
                  _emailController.text = value;
                },
              ),
              const SizedBox(height: 16.0),
              MyPasswordTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: false,
                onChanged: (value) {
                  // Update the _passwordController with the new value
                  _passwordController.text = value;
                },
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () {
                  if(_formKey.currentState?.validate() ?? false) {
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
                            } else {
                              return AlertDialog(
                                title: const Text('Create Account'),
                                content: Text(
                                    'Username: ${_usernameController.text}\nEmail: ${_emailController.text}\nPassword: ${_passwordController.text}'),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      String id =await userProvider.getCurrentUserId();
                                      Position userPosition =await provider.determinePosition();
                                      await provider.newUser(
                                        context: context,
                                        id:id,
                                        name: _usernameController.text,
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                        latitude: userPosition.latitude,
                                        longitude: userPosition.longitude,
                                      );
                                      setState(() {
                                        _usernameController.text = '';
                                        _emailController.text = '';
                                        _passwordController.text = '';
                                      });
                                    },
                                    child: Text('Create Account'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('Cancel'),
                                  ),
                                ],
                              );
                            }
                          },
                        );
                      },
                    );
                  }
                },
                child: Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
