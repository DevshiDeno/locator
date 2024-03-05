import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message){
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
      backgroundColor: Colors.black38,
      content: Text(message))
);
}
void showSnackBarError(BuildContext context, String message){
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Colors.black38,
          content: Text(message))
  );
}