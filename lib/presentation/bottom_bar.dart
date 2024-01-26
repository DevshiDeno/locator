import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:locator/presentation/Home.dart';
import 'package:locator/presentation/Notifications.dart';

class Home extends StatefulWidget {
   const Home({super.key,});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var currentIndex = 0;
  var indexs;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (indexs) {
            setState(() {
              currentIndex = indexs;
            });
          },
          items: listOfIcons.map((icon) {
            return BottomNavigationBarItem(
                icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.fastLinearToSlowEaseIn,
                    margin: EdgeInsets.only(
                      bottom: indexs == currentIndex ? 0 : size.width * 0.029,
                      right: size.width * .0422,
                      left: size.width * .0422,
                    ),
                    width: size.width * .128,
                    height: indexs == currentIndex ? size.width * .014 : 0,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(10)),
                    ),
                    child: Icon(icon)),
                label: '');
          }).toList()),
    );
  }

  final List<Widget> screens = [
    MyHomePage(),
    Messages(),
    // Add more screens as needed
  ];
  List<IconData> listOfIcons = [
    Icons.location_on_outlined,
    Icons.chat_bubble,
    // Icons.safety_check_outlined,
    // Icons.chat_outlined,
  ];
  List<String> icontitles = ["Location", "Chat"];
}
