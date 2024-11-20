import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'HomeScreen.dart';

class CreateGroupScreen extends StatefulWidget {
  final List<Map<String, dynamic>> membersList;

  const CreateGroupScreen({required this.membersList, super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroupScreen> {
  final TextEditingController _groupName = TextEditingController();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  void createGroup() async {
    setState(() {
      isLoading = true;
    });

    String groupId = const Uuid().v1();

    await _database.ref("groups/$groupId").set({
      "members": widget.membersList,
      "id": groupId,
    });

    for (int i = 0; i < widget.membersList.length; i++) {
      String uid = widget.membersList[i]['uid'];

      await _database
          .ref("users/$uid/groups/$groupId")
          .set({
        "name": _groupName.text,
        "id": groupId,
      });
    }

    await _database
        .ref("groups/$groupId/chats")
        .push()
        .set({
      "message": "${_auth.currentUser!.displayName} Created This Group.",
      "type": "notify",
      "time": DateTime.now().millisecondsSinceEpoch,
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Name"),
      ),
      body: isLoading
          ? Container(
        height: size.height,
        width: size.width,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      )
          : Column(
        children: [
          SizedBox(
            height: size.height / 10,
          ),
          Container(
            height: size.height / 14,
            width: size.width,
            alignment: Alignment.center,
            child: SizedBox(
              height: size.height / 14,
              width: size.width / 1.15,
              child: TextField(
                controller: _groupName,
                decoration: InputDecoration(
                  hintText: "Enter Group Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: size.height / 50,
          ),
          ElevatedButton(
            onPressed: createGroup,
            child: const Text("Create Group"),
          ),
        ],
      ),
    );
  }
}

//
