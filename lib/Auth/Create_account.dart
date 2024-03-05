import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:locator/Components/textField.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

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
              child: Container(
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
              child: Container(
                //color: Colors.black,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        controller: _usernameController,
                        obscureText: false,
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
                                    } else {
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
                                                _usernameController.text = '';
                                                _emailController.text = '';
                                                _passwordController.text = '';
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
            ),
          ),
        ],
      ),
    );
  }
}
