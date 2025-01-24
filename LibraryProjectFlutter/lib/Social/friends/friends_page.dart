import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/Social/friends_library/friends_library_page.dart';
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
  // List<Request> requests = [];
  // List<Friend> friends = [];
  String _selected = "list";

  @override
  void initState() {
    super.initState();
    updateLists();
  }

  void updateLists() async {
    // await updateRequestList();
    // await updateFriendsList();
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

  Future<void> updateRequestList() async {
    requests = await getFriendRequests(widget.user);
  }

  Future<void> updateFriendsList() async {
    // friends = await getFriends(widget.user);
  }

  Widget displayList() {
    if (_selected == "list") {
      return const FriendList();
    } else {
      return FriendRequestList(updateLists);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: displayAppBar(context, widget.user, "friends"),
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
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            displayNavigationButtons(),
            const SizedBox(height: 10),
            // Container(
            //   decoration: const BoxDecoration(
            //     borderRadius: BorderRadius.all(Radius.circular(20)),
            //     color: Colors.white,
            //   ),
            //   padding: const EdgeInsets.all(15),
            //   child: Row(
            //     children: [
            //       ClipOval(
            //         child: SizedBox(
            //           width: 50,
            //           child: Image.asset(
            //             "assets/profile_pic.jpg",
            //             fit: BoxFit.cover,
            //           ),
            //         ),
            //       ),
            //       const SizedBox(width: 10),
            //       const Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             'milad',
            //             style: TextStyle(
            //               fontSize: 18,
            //               fontWeight: FontWeight.w600,
            //             ),
            //           ),
            //           Text(
            //             'online',
            //             style: TextStyle(
            //               fontSize: 14,
            //               color: Colors.green,
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(
              child: displayList(),
            )
          ],
        ),
      ),
    );
  }
}

class FriendRequestList extends StatelessWidget {
  const FriendRequestList(this.callback, {super.key});

  // final List<Request> requests;
  final Function() callback;

  void acceptClicked(int index, BuildContext context) async {
    await addFriend(requests[index]);
    SharedWidgets.displayPositiveFeedbackDialog(
        context, "Friend Request Accepted");
    callback();
  }

  void denyClicked(int index, BuildContext context) async {
    await requests[index].delete();
    SharedWidgets.displayPositiveFeedbackDialog(
        context, "Friend Request Deleted");
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: requests.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
              margin: const EdgeInsets.all(5),
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            flex: 4,
                            child: Row(children: [
                              ClipOval(
                                child: SizedBox(
                                    width: 75,
                                    child:
                                        Image.network(requests[index].photo)),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      requests[index].name,
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 20),
                                      softWrap: true,
                                    ),
                                    Text(
                                      requests[index].email,
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 16),
                                      softWrap: true,
                                    ),
                                  ]),
                            ])),
                        Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                    onPressed: () {
                                      acceptClicked(index, context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromRGBO(
                                            76, 175, 80, 1)),
                                    child: const Text('Accept',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black))),
                                ElevatedButton(
                                    onPressed: () {
                                      denyClicked(index, context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromRGBO(
                                            244, 67, 54, 1)),
                                    child: const Text('Deny',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.black)))
                              ],
                            )),
                      ])));
        });
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

class FriendList extends StatelessWidget {
  const FriendList({super.key});

  // final List<Friend> friends;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: friends.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            margin: const EdgeInsets.all(5),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        ClipOval(
                          child: SizedBox(
                            width: 75,
                            // child: Image.network(friends[index].photo)),
                            child: friends[index].photoUrl != null
                                ? Image.network(friends[index].photoUrl!)
                                : Image.asset('assets/profile_pic.jpg'),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friends[index].name,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 20),
                                softWrap: true,
                              ),
                              Text(
                                friends[index].email,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16),
                                softWrap: true,
                              ),
                            ]),
                      ]),
                    ])),
          );
        });
    // SizedBox(
    //   height: 100,
    //   width: 70,
    //   child: image,
    // ),
    // const SizedBox(
    //   width: 10,
    // ),
    //   SizedBox(
    //     width: 270,
    //     height: 100,
    //     child: Align(
    //         alignment: Alignment.topLeft,
    //         child: Text(
    //           friends[index].friendId,
    //           style:
    //               const TextStyle(color: Colors.black, fontSize: 20),
    //           softWrap: true,
    //         )),
    //   ),
    // ]));
    // });
  }
}

class Friend {
  String friendId;
  late String name = "";
  late String email = "";
  late String photo = "";
  late DatabaseReference _id;

  @override
  String toString() {
    return 'Friend{friendId: $friendId, name: $name, email: $email, _id: $_id}';
  }

  void setId(DatabaseReference id) {
    _id = id;
  }

  Future<void> delete() async {
    await removeRef(_id);
  }

  Friend(this.friendId);
}
