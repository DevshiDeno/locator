import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locator/Components/textField.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class PasswordResetPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              child: Lottie.asset('assets/Icon_location.json'),
            ),
            MyTextField(
              controller: emailController,
              labelText: 'Email',
              obscureText: false,
              onChanged: (value) {},
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await provider.resetPassword(
                    emailController.text.trim(), context);
              },
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}
