import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';
import 'add_friend_page.dart';
import '../core/appbar.dart';

class FriendsPage extends StatefulWidget {
  final User user;

  const FriendsPage(this.user, {super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Request> requests = [];
  List<Friend> friends = [];
  String _selected = "list";

  @override
  void initState() {
    super.initState();
    updateLists();
  }

  void updateLists() async {
    await updateRequestList();
    await updateFriendsList();
    setState(() {});
  }

  void addFriendClicked() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => AddFriendPage(widget.user)));
    updateLists();
  }

  Future<void> changeDisplay(String state) async {
    setState(() {
      _selected = state;
    });
  }

  Widget displayNavigationButtons() {
    List<Color> buttonColor = [
      const Color.fromRGBO(129, 199, 132, 1),
      const Color.fromRGBO(129, 199, 132, 1),
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: buttonColor[0]),
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
          style: ElevatedButton.styleFrom(backgroundColor: buttonColor[1]),
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
    friends = await getFriends(widget.user);
  }

  Widget displayList() {
    if (_selected == "list") {
      return FriendList(friends);
    } else {
      return FriendRequestList(requests, updateLists);
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
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            displayNavigationButtons(),
            const SizedBox(height: 10),
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 50,
                      child: Image.asset(
                        "assets/profile_pic.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'milad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'online',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            displayList(),
          ],
        ),
      ),
    );
  }
}

class FriendRequestList extends StatelessWidget {
  const FriendRequestList(this.requests, this.callback, {super.key});

  final List<Request> requests;
  final Function() callback;

  void acceptClicked(int index) async {
    await addFriend(requests[index]);
    callback();
  }

  void denyClicked(int index) async {
    await requests[index].delete();
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 560,
        child: ListView.builder(
            itemCount: requests.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                  margin: const EdgeInsets.all(5),
                  child: Row(children: [
                    const SizedBox(
                      width: 10,
                    ),
                    // SizedBox(
                    //   height: 100,
                    //   width: 70,
                    //   child: image,
                    // ),
                    // const SizedBox(
                    //   width: 10,
                    // ),
                    SizedBox(
                      width: 170,
                      height: 100,
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            requests[index].senderId,
                            style: const TextStyle(color: Colors.black, fontSize: 20),
                            softWrap: true,
                          )),
                    ),
                    SizedBox(
                        height: 100,
                        width: 170,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ElevatedButton(
                                onPressed: () {
                                  acceptClicked(index);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(76, 175, 80, 1)),
                                child: const Text('Accept', style: TextStyle(fontSize: 16, color: Colors.black))),
                            ElevatedButton(
                                onPressed: () {
                                  denyClicked(index);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(244, 67, 54, 1)),
                                child: const Text('Deny', style: TextStyle(fontSize: 16, color: Colors.black)))
                          ],
                        )),
                  ]));
            }));
  }
}

class Request {
  String senderId;
  String uid;
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
  const FriendList(this.friends, {super.key});

  final List<Friend> friends;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 560,
        child: ListView.builder(
            itemCount: friends.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                  margin: const EdgeInsets.all(5),
                  child: Row(children: [
                    const SizedBox(
                      width: 10,
                    ),
                    // SizedBox(
                    //   height: 100,
                    //   width: 70,
                    //   child: image,
                    // ),
                    // const SizedBox(
                    //   width: 10,
                    // ),
                    SizedBox(
                      width: 270,
                      height: 100,
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            friends[index].friendId,
                            style: const TextStyle(color: Colors.black, fontSize: 20),
                            softWrap: true,
                          )),
                    ),
                  ]));
            }));
  }
}

class Friend {
  String friendId;
  String? name;
  String? email;
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
