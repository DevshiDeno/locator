import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../Model/user_details.dart';
import '../Provider/Provider.dart';

class RoutesMap extends StatefulWidget {
  const RoutesMap(
      {super.key,
      required this.polyline,
      required this.markers,
      required this.user,
      required this.currentLocation,
      required this.currentPosition});

  final Position currentPosition;
  final String currentLocation;
  final String user;
  final Set<Polyline>? polyline;
  final Set<Marker>? markers;

  @override
  State<RoutesMap> createState() => _RoutesMapState();
}

class _RoutesMapState extends State<RoutesMap> {
  GoogleMapController? mapController;
  late BitmapDescriptor markerIcon;
  Set<Marker> _markers = {};
  Set<Polyline> _polyLines = {};
  String? currentUser;

  Future<void> mergeMarkers() async {
    final currentId = await Provider.of<CurrentUser>(context, listen: false)
        .getCurrentUserId();
    setState(() {
      currentUser = currentId;
    });
    Set<Marker> mergedMarkers = Set.from(_markers);
    mergedMarkers.addAll(widget.markers ?? {}); // Copy existing markers
    await Future.forEach(Users.users, (user) {
      if (currentUser == user.id) {
        mergedMarkers.add(
          Marker(
            markerId: MarkerId(user.id),
            position: user.currentLocation.toLatLng(),
            infoWindow: const InfoWindow(title: 'You'),
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      }
    });
    setState(() {
      _markers = mergedMarkers;
    });
  }

  @override
  void initState() {
    super.initState();
    _polyLines = widget.polyline!;
    mergeMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final streamProvider =
        Provider.of<CurrentLocations>(context, listen: false);
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return PopScope(
      onPopInvoked: (didPop) async {
        _markers.clear();
        _polyLines.clear();
        await streamProvider.stopListening();
        return Future.value();
      },
      child: Scaffold(
        body: Stack(children: [
          GoogleMap(
              cloudMapId: 'cf2bb55d8b44b0bd',
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    widget.currentPosition.latitude,
                    widget.currentPosition.longitude
                ),
                zoom: 12.0,
              ),
              polylines: _polyLines,
              markers: _markers),
          Positioned(
            top: 30,
            left: 16.0,
            child: IconButton(
                onPressed: () async {
                  try {
                    await streamProvider.stopListening();
                    _markers.clear();
                    _polyLines.clear();
                    Navigator.pop(context);
                  } catch (e) {
                    print(e);
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 25,
                )),
          ),
          Positioned(
              top: he * 0.2,
              left: 16.0,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.lightGreenAccent,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    IconButton(
                        onPressed: () {
                          mapController?.animateCamera(CameraUpdate.zoomOut());
                        },
                        icon: const Icon(Icons.zoom_out)),
                    IconButton(
                        onPressed: () {
                          mapController?.animateCamera(CameraUpdate.zoomIn());
                        },
                        icon: const Icon(Icons.zoom_in)),
                  ],
                ),
              )),
          Positioned(
              left: 0,
              right: 0,
              // top: 0,
              bottom: 0,
              child: Container(
                height: we * 0.5,
                color: Colors.white70,
                child: ListTile(
                  title: Text(widget.user),
                  subtitle: Text(widget.currentLocation),
                ),
              ))
        ]),
      ),
    );
  }
}
