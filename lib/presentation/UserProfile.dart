import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locator/Components/ListsTiles.dart';

class Profile extends StatelessWidget {
  final String user;
  final String currentLocation;
  final String prevLocation;
  final String id;
  const Profile({super.key, required this.user, required this.currentLocation, required this.id, required this.prevLocation});

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
          children: [
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                //color: Colors.green,
              ),
              width: we,
              height: he * 0.08,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back_ios)),
                  ),
                  Text(
                    user,
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                    decoration: TextDecoration.none
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.send_and_archive_sharp,
                         size: 30,
                         // color: Colors.white,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: he * 0.15,
          child: CircleAvatar(
            radius: 50,
            // child:image,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: he * 0.3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: we,
                height: 100,
                //color: Colors.lightGreenAccent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        elevation: 5.0,
                        shape: CircleBorder(),
                        shadowColor: Colors.black54,
                        child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                            child: IconButton(
                                onPressed: () {}, icon: Icon(Icons.info_outline))),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 30,
                      decoration: BoxDecoration(
                          color: Colors.lightGreenAccent,
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(16),
                              left: Radius.circular(16))),
                      child: Center(child: Text(id,
                        style: TextStyle(fontSize: 15,
                            color: Colors.black,
                            decoration: TextDecoration.none
                        ),)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        elevation: 5.0,
                        shape: CircleBorder(),
                        shadowColor: Colors.black54,
                        child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                            child: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.chat_outlined))),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: we,
                  //height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white
                  ),
                  child: Column(
                    children: [
                     ListTiles(text: "Now is",icon: Icon(Icons.location_on_outlined)),
                      ListTiles(text: currentLocation,dateTime: DateTime.now(),),
                      // ListTiles(text: "School"),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: we,
                  height: 200,
                  decoration: BoxDecoration(
                      color: Colors.white
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ListTiles(text: "Last Updates",icon: Icon(Icons.arrow_circle_up_rounded,size: 20,)),
                        ListTiles(text: prevLocation,dateTime: DateTime.now(),),
                        ListTiles(text: "Moi avenue",dateTime: DateTime.now(),),
                        ListTiles(text: "Moi avenue",dateTime: DateTime.now(),),
                        ListTiles(text: "Ronald Ngara",dateTime: DateTime.now(),),
                        ListTiles(text: "River-Road",dateTime: DateTime.now(),),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      elevation: 5.0,
                      shape: CircleBorder(),
                      shadowColor: Colors.black54,
                      child: CircleAvatar(
                          backgroundColor: Colors.lightGreenAccent,
                          radius: 30,
                          child: IconButton(
                              onPressed: () {}, icon: Icon(Icons.phone_sharp))),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 30,
                    decoration: BoxDecoration(
                        color: Colors.lightGreenAccent,
                        borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(16),
                            left: Radius.circular(16))),
                    child: Center(child: Text("Follow",
                      style: TextStyle(fontSize: 15,
                          color: Colors.black,
                          decoration: TextDecoration.none
                      ),)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      elevation: 5.0,
                      shape: CircleBorder(),
                      shadowColor: Colors.black54,
                      child: CircleAvatar(
                          backgroundColor: Colors.lightGreenAccent,
                          radius: 30,
                          child: IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.battery_4_bar_rounded))),
                    ),
                  ),
                ],
              ),
            ),
      ]),
    );
  }
}
