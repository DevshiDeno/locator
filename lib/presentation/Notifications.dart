import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:locator/Components/showDialog.dart';
import 'package:locator/Model/request_location.dart';
import 'package:locator/Model/sharing_location.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/Home.dart';
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
  final DatabaseReference _reference =
  FirebaseDatabase.instance.ref().child('requests');

  List<Users> userId = [];
  List<ShareLocation> messages = [];
  List<RequestLocation> messagesRequests = [];
  String? currentUser;
  String? sendersName;

  Future<void> getNotifications() async {
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
        } catch (e) {}
      }
    });
    _reference.onValue.listen((event) async {
      final provider = Provider.of<CurrentUser>(context, listen: false);
      currentUser = await provider.getCurrentUserId();
      sendersName = await provider.getCurrentUserDisplayName();
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> dataList =
          jsonDecode(jsonEncode(event.snapshot.value));
          List<RequestLocation> requests = dataList.values
              .map((item) => RequestLocation.fromMap(item))
              .toList();
          setState(() {
            RequestLocation.requested = requests;
            messagesRequests = RequestLocation.requested
                .where((sender) =>
            currentUser == sender.receivingRequest &&
                sendersName != sender.sender)
                .toList();
          });
        } catch (e) {
          print('error getting notification $e');
        }
      }
    });
    await Future.delayed(const Duration(seconds: 1)); // Simulating a delay
  }

  @override
  void initState() {
    super.initState();
    getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery
        .of(context)
        .size
        .width;
    var he = MediaQuery
        .of(context)
        .size
        .height * 0.9;

    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text("Notifications"),
              bottom: const TabBar(
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
                    ? SharedLocation(
                    he: he,
                    messages: messages,
                    currentUser: currentUser,
                    sendersName: sendersName)
                    : const Center(child: Text('No notification received')),
                messagesRequests.isNotEmpty
                    ? RequestedLocations(
                    he: he,
                    messagesRequests: messagesRequests,
                    currentUser: currentUser,
                    sendersName: sendersName)
                    : const Center(child: Text('No Location requests')),
              ],
            )));
  }
}

class RequestedLocations extends StatelessWidget {
  const RequestedLocations({
    super.key,
    required this.he,
    required this.messagesRequests,
    required this.currentUser,
    required this.sendersName,
  });

  final double he;
  final List<RequestLocation> messagesRequests;
  final String? currentUser;
  final String? sendersName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white24,
      width: double.infinity,
      height: he * 0.9,
      child: ListView.builder(
          itemCount: messagesRequests.length,
          itemBuilder: (context, index) {
            final locationListening =
            Provider.of<CurrentLocations>(context, listen: false);
            final message = messagesRequests[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onDoubleTap: () async {
                  try {
                    Set<Marker> markers = {};
                    final polylineProvider = Provider.of<GetLocationProvider>(
                        context,
                        listen: false);
                    final polylines = polylineProvider.polyline;
                    final provider =
                    Provider.of<AddFriend>(context, listen: false);
                    provider.acceptLocationRequest(receiverId: currentUser!);

                    LatLng? streamLocation =
                    await locationListening.startListening();
                    markers.add(
                      Marker(
                        markerId: MarkerId(message.sender),
                        position: message.currentLocation.toLatLng(),
                        infoWindow: InfoWindow(title: message.sender),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueOrange),
                      ),
                    );
                    await polylineProvider.addPolyline(
                      message.currentLocation
                          .toLatLng(), streamLocation);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Home(
                                polylines: polylines,
                                markers: markers),
                      ),
                    );
                  } catch (e) {
                    print(e);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    title: Text(message.sender),
                    subtitle: Text(message.isAccepted == true
                        ? 'request Accepted'
                        : message.message),
                    trailing: message.isAccepted == false
                        ? Text(DateFormat('HH:mm')
                        .format(DateTime.parse(message.dateTime)))
                        : ElevatedButton(
                        onPressed: () {
                          locationListening.stopListening();
                        },
                        child: Text('Stop')),
                  ),
                ),
              ),
            );
          }),
    );
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
            final message = filteredList[index];
            final locationListening =
            Provider.of<CurrentLocations>(context, listen: false);
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () async {
                  try {
                    Set<Marker> markers = {};
                    final polylineProvider = Provider.of<GetLocationProvider>(
                        context,
                        listen: false);
                    final polylines = polylineProvider.polyline;
                    LatLng? streamLocation =
                    await locationListening.startListening();
                    markers.add(
                      Marker(
                        markerId: MarkerId(message.sender),
                        position: message.currentLocation.toLatLng(),
                        infoWindow: InfoWindow(title: message.sender),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen),
                      ),
                    );
                    await polylineProvider.addPolyline(
                        message.currentLocation
                            .toLatLng(), streamLocation);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Home(
                                polylines: polylines,
                                markers: markers),
                      ),
                    );
                  } catch (e) {
                    print(e);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    title: Text(message.sender),
                    subtitle: Text(message.message),
                    leading: Text(DateFormat('HH:mm')
                        .format(DateTime.parse(message.dateTime))),
                    trailing:ElevatedButton(onPressed: ()  async {
                      await locationListening.stopListening();
                    }, child: Text("Stop")) ,
                  ),
                ),
              ),
            );
          }),
    );
  }
}
