import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:shelfswap/Social/friends_library/friends_library_page.dart';
import 'package:shelfswap/Social/profile/profile.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/core/appbar.dart';
import 'package:shelfswap/core/global_variables.dart';

class FriendsOfFriendsPage extends StatefulWidget {
  final User user;
  final String friendID;

  const FriendsOfFriendsPage(this.user, this.friendID, {super.key});

  @override
  State<FriendsOfFriendsPage> createState() => _FriendsOfFriendsPageState();
}

class _FriendsOfFriendsPageState extends State<FriendsOfFriendsPage> {
  List<String> friends = [];
  late final VoidCallback _somethingUpdatedListener;

  @override
  void initState() {
    super.initState();
    _somethingUpdatedListener = () {
      if (selectedIndex == profileIndex || selectedIndex == friendsPageIndex) {
        _updateList();
      }
    };
    pageDataUpdatedNotifier.addListener(_somethingUpdatedListener);
    _updateList();
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_somethingUpdatedListener);
    super.dispose();
  }

  void _updateList() {
    friends.clear();

    for (String id in idsToFriendList[widget.friendID]!) {
      if (userIdToUserModel[id]!.isPublic || friendIDs.contains(id)) {
        friends.add(id);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          widget.user,
          title: "${userIdToUserModel[widget.friendID]!.name}'s friends",
        ),
        body: Padding(
            padding: const EdgeInsets.all(25),
            child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    Profile(widget.user, friends[index], showBackButtonOnAppbarInsteadOfMenu: true)));
                      },
                      child: SizedBox(
                          height: 100,
                          child: Card(
                              margin: const EdgeInsets.all(5),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: ClipOval(
                                            child: SizedBox(
                                          width: 50,
                                          child:
                                              userIdToUserModel[friends[index]]
                                                          ?.photoUrl !=
                                                      null
                                                  ? Image.network(
                                                      userIdToUserModel[
                                                              friends[index]]!
                                                          .photoUrl!)
                                                  : Image.asset(
                                                      'assets/profile_pic.jpg'),
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
                                            userIdToUserModel[friends[index]]!
                                                .name,
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Text(
                                            userIdToUserModel[friends[index]]!
                                                .username,
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      ]),
                                    )),
                                  ]))));
                })));
  }
}
