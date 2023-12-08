import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ListTiles extends StatelessWidget {
 final  DateTime? dateTime;
 final String text;
 final Icon? icon;
  const ListTiles({super.key,  this.dateTime, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return  ListTile(
      title: Text(text),
      trailing:  icon !=null ? Icon(icon!.icon) :Text("${dateTime?.hour}: ${dateTime?.minute}"),
    );
  }
}
