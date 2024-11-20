import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AddMembersInTheGroupScreen extends StatefulWidget {
  final String groupChatId, name;
  final List membersList;
  const AddMembersInTheGroupScreen(
      {required this.name,
        required this.membersList,
        required this.groupChatId,
        super.key});

  @override
  _AddMembersInTheGroupScreen createState() => _AddMembersInTheGroupScreen();
}

class _AddMembersInTheGroupScreen extends State<AddMembersInTheGroupScreen> {
  final TextEditingController _search = TextEditingController();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  Map<String, dynamic>? userMap;
  bool isLoading = false;
  List membersList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    membersList = widget.membersList;
  }

  void onSearch() async {
    setState(() {
      isLoading = true;
    });

    final snapshot = await _database
        .ref()
        .child('users')
        .orderByChild("email")
        .equalTo(_search.text)
        .once();
    if (snapshot.snapshot.value != null) {
      final user = (snapshot.snapshot.value as Map).values.first;
      setState(() {
        userMap = Map<String, dynamic>.from(user);
        isLoading = false;
      });
    } else {
      setState(() {
        userMap = null;
        isLoading = false;
      });
    }
  }

  void onAddMembers() async {
    membersList.add(userMap);

    await _database
        .ref()
        .child('groups')
        .child(widget.groupChatId)
        .child("members")
        .set(membersList);

    await _database
        .ref()
        .child('users')
        .child(userMap!['uid'])
        .child("groups")
        .child(widget.groupChatId)
        .set({"name": widget.name, "id": widget.groupChatId});

    setState(() {
      userMap = null;
    });
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
              onTap: onAddMembers,
              leading: const Icon(Icons.account_box),
              title: Text(userMap!['name']),
              subtitle: Text(userMap!['email']),
              trailing: const Icon(Icons.add),
            )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}