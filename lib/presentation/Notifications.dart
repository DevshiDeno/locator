import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locator/Data/sharing_location.dart';
import 'package:locator/Data/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/bottom_bar.dart';
import 'package:provider/provider.dart';

class Messages extends StatefulWidget {
  const Messages({
    super.key,
  });

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref().child('shared');
  List<Users> userId = [];
  List<ShareLocation> messages = [];
  String? currentUser;
  String? sendersName;

  Future<void> GetNotifactions() async {
    ref.onValue.listen((event) async {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> dataList =
              jsonDecode(jsonEncode(event.snapshot.value));
          List<ShareLocation> shared = dataList.values
              .map((item) => ShareLocation.fromMap(item))
              .toList();
          setState(() {
            messages = shared;
            //print(messages);
          });
          final provider = Provider.of<CurrentUser>(context, listen: false);
          currentUser = await provider.getCurrentUserId();
          sendersName = await provider.getCurrentUserDisplayName();
        } catch (e) {
          print('error getting notification $e');
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    GetNotifactions();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height * 0.9;
    if (messages.isEmpty) {
      return const Center(
          child:
              CircularProgressIndicator()); // Show loading indicator while waiting for data
    }
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text("Notifications"),
              bottom: TabBar(
                tabs: [
                  Tab(text: "Shared"),
                  Tab(
                    text: 'Requests',
                  )
                ],
              ),
            ),
            body: TabBarView(
              children: [
                messages
                        .where((sender) =>
                            currentUser == sender.receiver &&
                            sendersName != sender.sender)
                        .isNotEmpty
                    ? SharedLocation(he: he, messages: messages, currentUser: currentUser, sendersName: sendersName)
                    : Center(child: const Text('No notifactions recieved')),

                // messages
                //         .where((sender) => currentUser ==sender.receiver )
                //         .isNotEmpty
                //     ? Container(
                //         color: Colors.white24,
                //         width: double.infinity,
                //         height: he * 0.9,
                //         child: ListView.builder(
                //             //scrollDirection: Axis.h7,
                //             itemCount: messages
                //                 .where((sender) => currentUser==sender.receiver &&  sendersName!=sender.sender)
                //                 .length,
                //             itemBuilder: (context, index) {
                //               final filteredList = messages
                //                   .where((sender) => currentUser==sender.receiver && sendersName!=sender.sender)
                //                   .toList();
                //               //print('my notifications $filteredList');
                //               final message = filteredList[index];
                //               print(sendersName);
                //               print(message.sender);
                //               return Padding(
                //                 padding: const EdgeInsets.all(8.0),
                //                 child: Container(
                //                   padding: const EdgeInsets.all(2),
                //                   decoration: BoxDecoration(
                //                     borderRadius: BorderRadius.circular(16),
                //                     color: Colors.white,
                //                   ),
                //                   child: ListTile(
                //                     title: Text(message.sender),
                //                     subtitle: Text(message.message),
                //                     trailing: Text(DateFormat('HH:mm')
                //                         .format(DateTime.parse(message.dateTime))),
                //                   ),
                //                 ),
                //               );
                //             }),
                //       )
                //     :
                Center(child: const Text('No Location requests')),
              ],
            )
            ));
  }
}

class SharedLocation extends StatelessWidget {
  const SharedLocation({
    super.key,
    required this.he,
    required this.messages,
    required this.currentUser,
    required this.sendersName,
  });

  final double he;
  final List<ShareLocation> messages;
  final String? currentUser;
  final String? sendersName;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white24,
        width: double.infinity,
        height: he * 0.9,
        child: ListView.builder(
            //scrollDirection: Axis.h7,
            itemCount: messages
                .where((sender) =>
                    currentUser == sender.receiver &&
                    sendersName != sender.sender)
                .length,
            itemBuilder: (context, index) {
              final filteredList = messages
                  .where((sender) =>
                      currentUser == sender.receiver &&
                      sendersName != sender.sender)
                  .toList();
              //print('my notifications $filteredList');
              final message = filteredList[index];
              print(sendersName);
              print(message.sender);
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    title: Text(message.sender),
                    subtitle: Text(message.message),
                    trailing: Text(DateFormat('HH:mm').format(
                        DateTime.parse(message.dateTime))),
                  ),
                ),
              );
            }),
      );
  }
}
