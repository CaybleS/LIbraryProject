import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/friends_library/friends_library_page.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
import '../../database/database.dart';
import '../../models/user.dart';
import 'add_friend_page.dart';
import '../../core/appbar.dart';

class FriendsPage extends StatefulWidget {
  final User user;

  const FriendsPage(this.user, {super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Request> showRequests = [];
  List<UserModel> showFriends = [];
  String _selected = "list";
  late final VoidCallback _friendpageListener;

  @override
  void initState() {
    super.initState();
    _friendpageListener = () {
      if (refreshNotifier.value == friendsPageIndex) {
        updateLists();
      }
    };
    refreshNotifier.addListener(_friendpageListener);
  }

  @override
  void dispose() {
    refreshNotifier.removeListener(_friendpageListener);
    super.dispose();
  }

  void updateLists() async {
    showFriends = friends;
    showRequests = requests;
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
    await addFriend(requests[index]);
    SharedWidgets.displayPositiveFeedbackDialog(
        context, "Friend Request Accepted");
    updateLists();
  }

  void _denyClicked(int index, BuildContext context) async {
    await requests[index].delete();
    SharedWidgets.displayPositiveFeedbackDialog(
        context, "Friend Request Deleted");
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
            style: TextStyle(color: Colors.black, fontSize: 20),
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
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
      ],
    );
  }

  Widget displayList() {
    if (_selected == "list") {
      return displayFriends();
    } else {
      return displayRequests();
    }
  }

  Widget displayRequests() {
    return ListView.builder(
        itemCount: showRequests.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
              onTap: () {}, // TODO link to user profile
              child: SizedBox(
                  height: 150,
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
                                        width: 75,
                                        child: showFriends[index].photoUrl !=
                                                null
                                            ? Image.network(
                                                showFriends[index].photoUrl!)
                                            : Image.asset(
                                                'assets/profile_pic.jpg')))),
                            Expanded(
                                child: Align(
                              alignment: Alignment.topLeft,
                              child: Column(children: [
                                const SizedBox(
                                  height: 40,
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    showRequests[index].name,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 20),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    showRequests[index].email,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 20),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ]),
                            )),
                            ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 200),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(children: [
                                    ElevatedButton(
                                        onPressed: () {
                                          _acceptClicked(index, context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromRGBO(
                                                    76, 175, 80, 1)),
                                        child: const Text('Accept',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black))),
                                    ElevatedButton(
                                        onPressed: () {
                                          _denyClicked(index, context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromRGBO(
                                                    244, 67, 54, 1)),
                                        child: const Text('Deny',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black)))
                                  ]),
                                ))
                          ]))));
        });
  }

  Widget displayFriends() {
    return ListView.builder(
        itemCount: showFriends.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
              onTap: () {}, // TODO link to user profile
              child: SizedBox(
                  height: 150,
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
                                  width: 75,
                                  child: showFriends[index].photoUrl != null
                                      ? Image.network(
                                          showFriends[index].photoUrl!)
                                      : Image.asset('assets/profile_pic.jpg'),
                                ))),
                            Expanded(
                                child: Align(
                              alignment: Alignment.topLeft,
                              child: Column(children: [
                                const SizedBox(
                                  height: 40,
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    showFriends[index].name,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 20),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    showFriends[index].email,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 20),
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
                                                      friends[index])));
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
      appBar: const CustomAppBar(curPage:  "friends"),
      backgroundColor: Colors.grey[400],
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () {
            addFriendClicked();
          },
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
              child: displayList(),
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
