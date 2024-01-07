import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locator/Data/sharing_location.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:provider/provider.dart';

class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('shared');
  String? user;
  Future<void> getNotifactions() async {
    ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> dataList =
              jsonDecode(jsonEncode(event.snapshot.value));
          List<ShareLocation> shared = dataList.values
              .map((item) => ShareLocation.fromMap(item))
              .toList();
          setState(() {
            ShareLocation.shared = shared;
          });
        } catch (e) {
          print('error getting notification$e');
        }
      }
    });
    final provider = Provider.of<CurrentUser>(context, listen: false);
    user = await provider.getCurrentUserId();
    print(user);
  }

  @override
  void initState()  {
    super.initState();
   getNotifactions();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height * 0.9;
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("Notifications"),
        ),
        body: ShareLocation.shared.where((sender) => user == sender.receiver).isNotEmpty
            ? Container(
                color: Colors.white24,
                width: double.infinity,
                height: he * 0.9,
                child: ListView.builder(
                    //scrollDirection: Axis.h7,
                    itemCount: ShareLocation.shared.where((sender) => user==sender.receiver).length,
                    itemBuilder: (context, index) {
                      final filteredList=ShareLocation.shared.where((sender) => user==sender.receiver).toList();
                      print(filteredList);
                      final sender =filteredList[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                            ),
                            child: ListTile(
                              title: Text(sender.sender),
                              subtitle: Text(sender.message),
                              trailing: Text(DateFormat('HH:mm')
                                  .format(DateTime.parse(sender.dateTime))),
                            ),
                          ),
                        );
                    }),
              )
            : Center(child: const Text('No notifactions recieved')));
  }
}
