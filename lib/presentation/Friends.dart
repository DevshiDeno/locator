import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:locator/Model/user_details.dart';
import 'package:locator/Provider/Provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Friend extends StatefulWidget {
  const Friend({super.key});

  @override
  State<Friend> createState() => _FriendState();
}

class _FriendState extends State<Friend> {
  List<Friends> filteredFriends = [];
  bool isAccepted = false;
  String? currentUser;
  String? receiversName;
  List<Friends> filteredRequest = [];
  List<Friends> filteredFriendsList = [];
  int friendsCount = 0;
  int friendsRequestCount = 0;

  Future<void> loadFriends() async {

    final provider = Provider.of<CurrentUser>(context, listen: false);
    currentUser = await provider.getCurrentUserId();
    receiversName = await provider.getCurrentUserDisplayName();
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('friends');
    reference.onValue.listen((event) async {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> dataList =
              jsonDecode(jsonEncode(event.snapshot.value));
          List<Friends> friend =
              dataList.values.map((item) => Friends.fromMap(item)).toList();
          setState(() {
            Friends.friends = friend;
            filteredFriends = List.from(Friends.friends);
            filteredRequest = filteredFriends
                .where((receiver) =>
                    currentUser == receiver.receiverId &&
                    isAccepted == receiver.request)
                .toList();
            filteredFriendsList = filteredFriends
                .where((receiver) =>
                    (currentUser == receiver.receiverId ||
                    receiversName == receiver.senderName )&& isAccepted!=receiver.request
            ).toList();
            friendsCount = filteredFriendsList
                .where((friend) => isAccepted != friend.request)
                .length;
            friendsRequestCount = filteredRequest
                .where((request) => isAccepted == request.request)
                .length;
          });
          // print(currentUser);
        } catch (e) {
          print('Error updating state: $e');
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height * 0.9;
    final friendProvider = Provider.of<AddFriend>(context, listen: false);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
            title: const Text('My Friends'),
            bottom: TabBar(
              tabs: [
                Tab(text: "Requests ($friendsRequestCount)"),
                Tab(
                  text: 'Friends ($friendsCount)',
                )
              ],
            ),
          ),
          body: TabBarView(children: [
            filteredRequest.isNotEmpty
                ? SizedBox(
                    width: we,
                    height: he * 0.8,
                    child: ListView.builder(
                        itemCount: filteredRequest.length,
                        itemBuilder: (context, index) {
                          final friend = filteredRequest[index];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                                width: we * 0.8,
                                color: Colors.white,
                                child: ListTile(
                                    leading: CachedNetworkImage(
                                      imageUrl: friend.imageUrl,
                                      imageBuilder: (context, imageProvider) =>
                                          CircleAvatar(
                                        radius: 22,
                                        backgroundImage: imageProvider,
                                      ),
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person),
                                    ),
                                    title: Text(friend.senderName),
                                    subtitle: const Text(
                                        'sent you a friend request!'),
                                    trailing: friend.request
                                        ? const Text('Friends')
                                        : ElevatedButton(
                                            onPressed: () async {
                                              await friendProvider.acceptFriend(
                                                  senderId: friend.senderId);
                                            },
                                            child: const Text('Accept')))),
                          );
                        }),
                  )
                : const Center(child: Text('Friend request will appear here')),
            filteredFriendsList.isNotEmpty
                ? SizedBox(
                    width: we,
                    height: he * 0.8,
                    child: ListView.builder(
                        itemCount: filteredFriendsList.length,
                        itemBuilder: (context, index) {
                          final friend = filteredFriendsList[index];
                          print(friend.request);
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                                width: we * 0.85,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26
                                    )
                                  ]
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: friend.imageUrl,
                                      imageBuilder: (context, imageProvider) =>
                                          CircleAvatar(
                                        radius: 25,
                                        backgroundImage: imageProvider,
                                      ),
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person),
                                    ),
                                    SizedBox(width: we * 0.04),
                                    Text(
                                        receiversName == friend.senderName
                                            ? friend.name
                                            : friend.senderName,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: we * 0.30),
                                      const Text('Friends',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400)),
                                      IconButton(
                                          onPressed: () {
                                            final provider =
                                                Provider.of<AddFriend>(context,
                                                    listen: false);
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    content: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,

                                                      children: [
                                                        ElevatedButton(
                                                            onPressed:
                                                                () async {
                                                              await provider
                                                                  .removeFriend(
                                                                      senderId:
                                                                          friend
                                                                              .senderId,
                                                                      context:
                                                                          context);
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'Remove')),
                                                        ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'cancel'))
                                                      ],
                                                    ),
                                                  );
                                                });
                                          },
                                          icon: const Icon(Icons.more_vert,size: 15,))
                                  ],
                                )),
                          );
                        }),
                  )
                : const Center(child: Text('No Friends received')),
          ])),
    );
  }
}
