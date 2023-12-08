import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ElevatedButtons extends StatelessWidget {
  final String text;
  final Icon? icon;
  final VoidCallback onPressed;

  const ElevatedButtons(
      {super.key, required this.text, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon  ?? SizedBox.shrink(),
      label: Text(text),

    );
  }
}
