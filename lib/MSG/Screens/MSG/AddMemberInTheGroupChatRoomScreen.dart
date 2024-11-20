import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'CreateGroupScreen.dart';

class AddMembersInTheGroupChatRoomScreen extends StatefulWidget {
  const AddMembersInTheGroupChatRoomScreen({super.key});

  @override
  State<AddMembersInTheGroupChatRoomScreen> createState() =>
      _AddMembersInGroupState();
}

class _AddMembersInGroupState extends State<AddMembersInTheGroupChatRoomScreen> {
  final TextEditingController _search = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  List<Map<String, dynamic>> membersList = [];
  bool isLoading = false;
  Map<String, dynamic>? userMap;

  @override
  void initState() {
    super.initState();
    getCurrentUserDetails();
  }

  void getCurrentUserDetails() async {
    DatabaseReference ref = _database.ref('users/${_auth.currentUser!.uid}');
    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      Map data = snapshot.value as Map;
      setState(() {
        membersList.add({
          "name": data['name'],
          "email": data['email'],
          "uid": data['uid'],
          "isAdmin": true,
        });
      });
    }
  }

  void onSearch() async {
    setState(() {
      isLoading = true;
    });
    DatabaseReference ref = _database.ref('users');
    DataSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      for (var user in snapshot.children) {
        Map data = user.value as Map;
        if (data['email'] == _search.text) {
          setState(() {
            userMap = data.cast<String, dynamic>();
            isLoading = false;
          });
          return;
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void onResultTap() {
    bool isAlreadyExist = false;

    for (int i = 0; i < membersList.length; i++) {
      if (membersList[i]['uid'] == userMap!['uid']) {
        isAlreadyExist = true;
      }
    }

    if (!isAlreadyExist) {
      setState(() {
        membersList.add({
          "name": userMap!['name'],
          "email": userMap!['email'],
          "uid": userMap!['uid'],
          "isAdmin": false,
        });

        userMap = null;
      });
    }
  }

  void onRemoveMembers(int index) {
    if (membersList[index]['uid'] != _auth.currentUser!.uid) {
      setState(() {
        membersList.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Members"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                itemCount: membersList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () => onRemoveMembers(index),
                    leading: const Icon(Icons.account_circle),
                    title: Text(membersList[index]['name']),
                    subtitle: Text(membersList[index]['email']),
                    trailing: const Icon(Icons.close),
                  );
                },
              ),
            ),
            SizedBox(
              height: size.height / 20,
            ),
            Container(
              height: size.height / 14,
              width: size.width,
              alignment: Alignment.center,
              child: SizedBox(
                height: size.height / 14,
                width: size.width / 1.15,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: "Search",
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
            isLoading
                ? Container(
              height: size.height / 12,
              width: size.height / 12,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            )
                : ElevatedButton(
              onPressed: onSearch,
              child: const Text("Search"),
            ),
            userMap != null
                ? ListTile(
              onTap: onResultTap,
              leading: const Icon(Icons.account_box),
              title: Text(userMap!['name']),
              subtitle: Text(userMap!['email']),
              trailing: const Icon(Icons.add),
            )
                : const SizedBox(),
          ],
        ),
      ),
      floatingActionButton: membersList.length >= 2
          ? FloatingActionButton(
        child: const Icon(Icons.forward),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateGroupScreen(
              membersList: membersList,
            ),
          ),
        ),
      )
          : const SizedBox(),
    );
  }
}
