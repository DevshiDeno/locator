import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
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
StreamSubscription? loadFriendsSubscription;
  Future<void> loadFriends() async {
    final provider = Provider.of<CurrentUser>(context, listen: false);
    currentUser = await provider.getCurrentUserId();
    receiversName = await provider.getCurrentUserDisplayName();
    final DatabaseReference reference =
        FirebaseDatabase.instance.ref().child('friends');
    loadFriendsSubscription=reference.onValue.listen((event) async {
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
        } catch (e) {}
      }
     // loadFriendsSubscription?.cancel();

    });
  }

  @override
  void initState() {
    super.initState();
    loadFriends();
  }
  @override
  void dispose(){
    super.dispose();
  loadFriendsSubscription?.cancel();
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
            automaticallyImplyLeading:false,
            centerTitle: true,
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
                ? FriendsRequest(we: we, he: he, filteredRequest: filteredRequest, friendProvider: friendProvider, receiversName: receiversName,)
                : const Center(child: Text('Friend request will appear here')),
            filteredFriendsList.isNotEmpty
                ? FriendsList(we: we, he: he, filteredFriendsList: filteredFriendsList, receiversName: receiversName)
                : const Center(child: Text('No Friends received')),
          ])),
    );
  }
}

class FriendsRequest extends StatelessWidget {
  const FriendsRequest({
    super.key,
    required this.we,
    required this.he,
    required this.filteredRequest,
    required this.friendProvider,
    required this.receiversName,

  });

  final double we;
  final double he;
  final List<Friends> filteredRequest;
  final AddFriend friendProvider;
  final String? receiversName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                        // leading: CachedNetworkImage(
                        //     imageUrl:receiversName == friend.senderName ? friend.imageUrl
                        //         :friend.senderImage,
                        //   imageBuilder: (context, imageProvider) =>
                        //       CircleAvatar(
                        //     radius: 35,
                        //     backgroundImage: imageProvider,
                        //   ),
                        //   placeholder: (context, url) =>
                        //       const Center(
                        //           child:
                        //               CircularProgressIndicator()),
                        //   errorWidget: (context, url, error) =>
                        //       const CircleAvatar(
                        //           radius:30,
                        //           child: Icon(Icons.person)),
                        // ),
                        title: Text(friend.senderName),
                        subtitle: const Text(
                            'sent you a friend request!'),
                        trailing: friend.request
                            ? const Text('Friends')
                            : ElevatedButton(
                                onPressed: () async {
                                  await friendProvider.acceptFriend(
                                      senderId: friend.senderId);
                                  await friendProvider.friendsRequestCount--;
                                },
                                child: const Text('Accept')))),
              );
            }),
      );
  }
}

class FriendsList extends StatelessWidget {
  const FriendsList({
    super.key,
    required this.we,
    required this.he,
    required this.filteredFriendsList,
    required this.receiversName,
  });

  final double we;
  final double he;
  final List<Friends> filteredFriendsList;
  final String? receiversName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: we,
        height: he * 0.8,
        child: ListView.builder(
            itemCount: filteredFriendsList.length,
            itemBuilder: (context, index) {
              final friend = filteredFriendsList[index];
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
                          imageUrl:receiversName == friend.senderName ? friend.imageUrl
                          :friend.senderImage,
                          imageBuilder: (context, imageProvider) =>
                              CircleAvatar(
                            radius: 30,
                            backgroundImage: imageProvider,
                          ),
                          placeholder: (context, url) =>
                              const Center(
                                  child:
                                      CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const CircleAvatar(
                                  radius: 30,
                                  child: Icon(Icons.person)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                              width: we * 0.40,
                          //alignment: Alignment.topLeft,
                          child:Text(
                              receiversName == friend.senderName
                                  ? friend.name
                                  : friend.senderName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold))
                                          ),
                        ),
                        Container(
                            width: we * 0.15),
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
                                                  Navigator.pop(context);
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
      );
  }
}
