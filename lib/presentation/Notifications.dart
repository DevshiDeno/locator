import 'dart:async';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:locator/Components/SnackBar.dart';
import 'package:locator/Model/request_location.dart';
import 'package:locator/Model/sharing_location.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:locator/presentation/Map_Routes.dart';
import 'package:provider/provider.dart';

class Messages extends StatefulWidget {
  const Messages({
    super.key,
  });

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final DatabaseReference ref =
  FirebaseDatabase.instance.ref().child('shared');
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('SOS');

  final DatabaseReference _reference =
      FirebaseDatabase.instance.ref().child('requests');
  StreamSubscription? _requests;
  StreamSubscription? _sos;
  StreamSubscription? _shared;

  List<Users> userId = [];
  List<ShareLocation> messages = [];
  List<Sos> sosMessages = [];

  List<RequestLocation> messagesRequests = [];
  String? currentUser;
  String? sendersName;
  bool isImportant = false;

  Future<void> getNotifications() async {
    _requests=ref.onValue.listen((event) async {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> dataList =
              jsonDecode(jsonEncode(event.snapshot.value));
          List<ShareLocation> shared = dataList.values
              .map((item) => ShareLocation.fromMap(item))
              .toList();
          setState(() {
            ShareLocation.shared = shared;
            messages = ShareLocation.shared
                .where((sender) =>
                    currentUser == sender.receiver &&
                    sendersName != sender.sender)
                .toList();
          });
          final provider = Provider.of<CurrentUser>(context, listen: false);
          currentUser = await provider.getCurrentUserId();
          sendersName = await provider.getCurrentUserDisplayName();
        } catch (e) {}
      }
    });
    _sos= _databaseReference.onValue.listen((event) async {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> dataList =
              jsonDecode(jsonEncode(event.snapshot.value));
          List<Sos> sosList =
              dataList.values.map((item) => Sos.fromMap(item)).toList();

          setState(() {
            Sos.sharedSos = sosList;
            for (var sos in Sos.sharedSos) {
              for (var receiver in sos.receiver) {
                if (sendersName == receiver['name']) {
                  sosMessages.add(sos);
                  break;
                }
              }
            }
          });
          final provider = Provider.of<CurrentUser>(context, listen: false);
          currentUser = await provider.getCurrentUserId();
          sendersName = await provider.getCurrentUserDisplayName();
        } catch (e) {}
      }
    });

    _shared= _reference.onValue.listen((event) async {
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
  void dispose() {
    super.dispose();
  _requests?.cancel();
    _sos?.cancel();
     _shared?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height * 0.9;
    return DefaultTabController(
        length: 3,
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text("Notifications"),
              bottom: const TabBar(
                tabs: [
                  Tab(text: "Shared"),
                  Tab(
                    text: 'Requests',
                  ),
                  Tab(
                    text: 'Emergency',
                  )
                ],
              ),
            ),
            body: TabBarView(
              children: [
                messages.isNotEmpty
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
                sosMessages.isNotEmpty
                    ? Container(
                        color: Colors.white24,
                        width: double.infinity,
                        height: he * 0.9,
                        child: ListView.builder(
                            itemCount: sosMessages.length,
                            itemBuilder: (context, index) {
                              final sos = sosMessages[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  title: Text(sos.sendersName),
                                  subtitle: Text(sos.message),
                                  leading: Text(DateFormat('HH:mm')
                                      .format(DateTime.parse(sos.dateTime))),
                                  trailing: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:Colors.redAccent
                                    ),
                                    child: const Text('Respond')
                                  ),
                                ),
                              );
                            }),
                      )
                    : const Center(child: Text('No emergency messages'))
              ],
            )));
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
  Future<String> getAddressFromLatLng(position) async {
    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placeMarks.isNotEmpty) {
        return placeMarks[0].name ?? "Unknown Place";
      } else {
        return "No address information found";
      }
    } catch (e) {
      // print("Error getting address: $e");
      return "Error getting address";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white24,
      width: double.infinity,
      height: he * 0.9,
      child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
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
                    LatLng? streamLocation =
                        await locationListening.startListening();

                    await polylineProvider.addPolyline(
                        message.currentLocation.toLatLng(), streamLocation);
                    final polyline = polylineProvider.polyline;

                    markers.add(
                      Marker(
                        markerId: MarkerId(message.sender),
                        position: message.currentLocation.toLatLng(),
                        infoWindow: InfoWindow(title: message.sender),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen),
                      ),
                    );
                    String currentLocation=await getAddressFromLatLng(message.currentLocation.toLatLng());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RoutesMap(
                              polyline: polyline,
                              markers: markers,
                              user: message.sender,
                              currentLocation: currentLocation),
                      ),
                    );
                  } catch (e) {
                    showSnackBarError(
                        context, 'Unable to find route, Try again later!');
                    await locationListening.stopListening();
                    print('Error getting route: $e');
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
                  ),
                ),
              ),
            );
          }),
    );
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
  Future<String> getAddressFromLatLng(position) async {
    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placeMarks.isNotEmpty) {
        return placeMarks[0].name ?? "Unknown Place";
      } else {
        return "No address information found";
      }
    } catch (e) {
      // print("Error getting address: $e");
      return "Error getting address";
    }
  }

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
                  if(message.isAccepted==false){
                    try {
                      Set<Marker> markers = {};
                      final polylineProvider = Provider.of<GetLocationProvider>(
                          context,
                          listen: false);
                      final polyline = polylineProvider.polyline;
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
                          message.currentLocation.toLatLng(), streamLocation);
                      String currentLocation=await getAddressFromLatLng(message.currentLocation.toLatLng());
                       Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoutesMap(
                                    currentLocation: currentLocation,
                                    user: message.sender,
                                    polyline: polyline,
                                    markers: markers)
                            ,
                          ),
                        );

                    } catch (e) {
                      print(e);
                    }
                  }else{
                    showSnackBar(context,'Request Expired');
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
                    trailing:
                        Text(DateFormat('HH:mm')
                            .format(DateTime.parse(message.dateTime)))

                  ),
                ),
              ),
            );
          }),
    );
  }
}
