import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'AddMemberInTheGroupChatRoomScreen.dart';
import 'GroupChatRoomScreen.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  _GroupChatHomeScreenState createState() => _GroupChatHomeScreenState();
}

class _GroupChatHomeScreenState extends State<GroupChatScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = true;

  List groupList = [];

  @override
  void initState() {
    super.initState();
    getAvailableGroups();
  }

  void getAvailableGroups() async {
    String uid = _auth.currentUser!.uid;

    final ref = _database.ref().child('users').child(uid).child('groups');
    final snapshot = await ref.once();

    if (snapshot.snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      setState(() {
        groupList = data.values.toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Groups"),
      ),
      body: isLoading
          ? Container(
        height: size.height,
        width: size.width,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: groupList.length,
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupChatRoomScreen(
                  groupName: groupList[index]['name'],
                  groupChatId: groupList[index]['id'],
                ),
              ),
            ),
            leading: const Icon(Icons.group),
            title: Text(groupList[index]['name']),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AddMembersInTheGroupChatRoomScreen(),
          ),
        ),
        tooltip: "Create Group",
        child: const Icon(Icons.create),
      ),
    );
  }
}
