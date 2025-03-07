import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:shelfswap/Social/friends_library/friends_library_page.dart';
import 'package:shelfswap/Social/profile/profile.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/core/appbar.dart';

class FriendsOfFriendsPage extends StatefulWidget {
  final User user;
  final String friendID;
  
  const FriendsOfFriendsPage(this.user, this.friendID, {super.key});

  @override
  State<FriendsOfFriendsPage> createState() => _FriendsOfFriendsPageState();
}

class _FriendsOfFriendsPageState extends State<FriendsOfFriendsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(widget.user, title: "${userIdToUserModel[widget.friendID]!.name}'s friends",),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: ListView.builder(
        itemCount: idsToFriendList[widget.friendID]?.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Profile(widget.user, idsToFriendList[widget.friendID]![index])));
              },
              child: SizedBox(
                  height: 100,
                  child: Card(
                      margin: const EdgeInsets.all(5),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                                padding: const EdgeInsets.all(20),
                                child: ClipOval(
                                    child: SizedBox(
                                  width: 50,
                                  child: userIdToUserModel[idsToFriendList[widget.friendID]![index]]?.photoUrl != null
                                      ? Image.network(
                                          userIdToUserModel[idsToFriendList[widget.friendID]![index]]!.photoUrl!)
                                      : Image.asset('assets/profile_pic.jpg'),
                                ))),
                            Expanded(
                                child: Align(
                              alignment: Alignment.topLeft,
                              child: Column(children: [
                                const SizedBox(
                                  height: 22.5,
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    userIdToUserModel[idsToFriendList[widget.friendID]![index]]!.name,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    userIdToUserModel[idsToFriendList[widget.friendID]![index]]!.username,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 14),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ]),
                            )),
                          ]))));
        })
        )
    );
  }
}