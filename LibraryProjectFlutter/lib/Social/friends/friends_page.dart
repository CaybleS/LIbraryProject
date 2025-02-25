import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/friends_library/friends_library_page.dart';
import 'package:library_project/Social/profile/profile.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
import '../../database/database.dart';
import 'add_friend_page.dart';
import '../../core/appbar.dart';

class FriendsPage extends StatefulWidget {
  final User user;

  const FriendsPage(this.user, {super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<String> showRequests = [];
  List<String> showFriends = [];
  String _selected = "list";
  late final VoidCallback _friendpageListener;

  @override
  void initState() {
    super.initState();
    _friendpageListener = () {
      // since offstage loads this page into memory at all times via the bottombar we just run the refresh logic if its the selectedIndex
      if (selectedIndex == friendsPageIndex) {
        updateLists();
      }
    };
    pageDataUpdatedNotifier.addListener(_friendpageListener);
    updateLists();
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_friendpageListener);
    super.dispose();
  }

  void updateLists() async {
    showFriends = friendIDs;
    showRequests = requestIDs;
    setState(() {});
  }

  void addFriendClicked() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => AddFriendPage(widget.user)));
    updateLists();
  }

  Future<void> changeDisplay(String state) async {
    setState(() {
      _selected = state;
    });
  }

  void _acceptClicked(int index, BuildContext context) async {
    SharedWidgets.displayPositiveFeedbackDialog(
        context, "Friend Request Accepted");
    await addFriend(requestIDs[index], widget.user.uid);
    updateLists();
  }

  void _denyClicked(int index, BuildContext context) async {
    SharedWidgets.displayPositiveFeedbackDialog(
        context, "Friend Request Deleted");
    // await requests[index].delete();
    await removeRef(FirebaseDatabase.instance.ref('requests/${widget.user.uid}/${requestIDs[index]}'));
    updateLists();
  }

  Widget displayNavigationButtons() {
    List<Color> buttonColor = [
      AppColor.skyBlue,
      AppColor.skyBlue,
    ];

    switch (_selected) {
      case "list":
        buttonColor[0] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case "requests":
        buttonColor[1] = const Color.fromARGB(255, 117, 117, 117);
        break;
      default:
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor[0],
              padding: const EdgeInsets.all(8)),
          onPressed: () {
            if (_selected == "list") {
              return;
            } else {
              changeDisplay("list");
            }
          },
          child: const Text(
            "Friends List",
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor[1],
              padding: const EdgeInsets.all(8)),
          onPressed: () {
            if (_selected == "requests") {
              return;
            } else {
              changeDisplay("requests");
            }
          },
          child: const Text(
            "Friend Requests",
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget displayRequests() {
    return ListView.builder(
        itemCount: showRequests.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
              onTap: () {}, // TODO link to user profile
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
                                        child: userIdToUserModel[showRequests[index]]?.photoUrl != null
                                            ? Image.network(
                                                userIdToUserModel[showRequests[index]]!.photoUrl!)
                                            : Image.asset(
                                                'assets/profile_pic.jpg')))),
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
                                    userIdToUserModel[showRequests[index]]!.name,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    userIdToUserModel[showRequests[index]]!.email,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 14),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ]),
                            )),
                            ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 150),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  // child: Column(children: [
                                  //   ElevatedButton(
                                  //       onPressed: () {
                                  //         _acceptClicked(index, context);
                                  //       },
                                  //       style: ElevatedButton.styleFrom(
                                  //           backgroundColor:
                                  //               const Color.fromRGBO(
                                  //                   76, 175, 80, 1)),
                                  //       child: const Text('Accept',
                                  //           style: TextStyle(
                                  //               fontSize: 16,
                                  //               color: Colors.black))),
                                  //   ElevatedButton(
                                  //       onPressed: () {
                                  //         _denyClicked(index, context);
                                  //       },
                                  //       style: ElevatedButton.styleFrom(
                                  //           backgroundColor:
                                  //               const Color.fromRGBO(
                                  //                   244, 67, 54, 1)),
                                  //       child: const Text('Deny',
                                  //           style: TextStyle(
                                  //               fontSize: 16,
                                  //               color: Colors.black)))
                                  // ]),
                                  child: Row(
                                    children: [
                                      IconButton(
                                          onPressed: () {
                                            _acceptClicked(index, context);
                                          },
                                          color: const Color.fromRGBO(
                                              76, 175, 80, 1),
                                          icon: Icon(Icons.check)),
                                      IconButton(
                                          onPressed: () {
                                            _denyClicked(index, context);
                                          },
                                          color: const Color.fromRGBO(
                                              244, 67, 54, 1),
                                          icon: Icon(Icons.close))
                                    ],
                                  ),
                                ))
                          ]))));
        });
  }

  Widget displayFriends() {
    return ListView.builder(
        itemCount: showFriends.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Profile(widget.user, showFriends[index])));
              }, // TODO link to user profile
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
                                  child: userIdToUserModel[showFriends[index]]?.photoUrl != null
                                      ? Image.network(
                                          userIdToUserModel[showFriends[index]]!.photoUrl!)
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
                                    userIdToUserModel[showFriends[index]]!.name,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 16),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    userIdToUserModel[showFriends[index]]!.email,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 14),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ]),
                            )),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: ElevatedButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FriendsLibraryPage(
                                                      widget.user,
                                                      userIdToUserModel[friendIDs[index]]!)));
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColor.pink),
                                    child: const Text('View Library',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black))),
                              ),
                            )
                          ]))));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(widget.user),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () {
            addFriendClicked();
          },
          heroTag: UniqueKey(),
          child: const Icon(
            Icons.add,
            size: 30,
          )),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            displayNavigationButtons(),
            const SizedBox(height: 10),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 1, 15, 25),
              child: _selected == "list"
                  ? (showFriends.isNotEmpty ? displayFriends() : const SizedBox.shrink())
                  : (showRequests.isNotEmpty ? displayRequests() : const SizedBox.shrink()),
            ))
          ],
        ),
      ),
    );
  }
}

class Request {
  String senderId;
  String uid;
  late String photo = "";
  late String name = "";
  late String email = "";
  late DatabaseReference _id;

  void setId(DatabaseReference id) {
    _id = id;
  }

  Future<void> delete() async {
    await removeRef(_id);
  }

  Request(this.senderId, this.uid);
}

Request createRequest(record, String id) {
  return Request(record['sender'], id);
}
