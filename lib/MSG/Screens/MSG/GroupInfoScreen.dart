import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'AddMembersInGroupScreen.dart';
import 'HomeScreen.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId, groupName;

  const GroupInfoScreen(
      {required this.groupId, required this.groupName, super.key});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfoScreen> {
  List membersList = [];
  bool isLoading = true;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    getGroupDetails();
  }

  Future getGroupDetails() async {
    final ref = _database.ref().child('groups').child(widget.groupId);
    final snapshot = await ref.once();
    if (snapshot.snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

      if (data.containsKey('members')) {
        membersList = List.from(data['members']);
        debugPrint("Member List Is : ${membersList.toString()}");
      }
    }
    isLoading = false;
    setState(() {});
  }

  bool checkAdmin() {
    bool isAdmin = false;

    for (var element in membersList) {
      if (element['uid'] == _auth.currentUser!.uid) {
        isAdmin = element['isAdmin'];
      }
    }
    return isAdmin;
  }

  Future removeMembers(int index) async {
    String uid = membersList[index]['uid'];

    setState(() {
      isLoading = true;
      membersList.removeAt(index);
    });

    final groupRef = _database.ref().child('groups').child(widget.groupId);
    await groupRef.update({
      "members": membersList,
    });
    final userGroupRef = _database
        .ref()
        .child('users')
        .child(uid)
        .child('groups')
        .child(widget.groupId);
    await userGroupRef.remove();

    setState(() {
      isLoading = false;
    });
  }

  void showDialogBox(int index) {
    if (checkAdmin()) {
      if (_auth.currentUser!.uid != membersList[index]['uid']) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: ListTile(
                  onTap: () => removeMembers(index),
                  title: const Text("Remove This Member"),
                ),
              );
            });
      }
    }
  }




  Future onLeaveGroup() async {
    if (!checkAdmin()) {
      setState(() {
        isLoading = true;
      });

      membersList.removeWhere(
              (member) => member['uid'] == _auth.currentUser!.uid);

      final groupRef = _database.ref().child('groups').child(widget.groupId);
      await groupRef.update({
        "members": membersList,
      });

      final userGroupRef = _database
          .ref()
          .child('users')
          .child(_auth.currentUser!.uid)
          .child('groups')
          .child(widget.groupId);
      await userGroupRef.remove();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        body: isLoading
            ? Container(
          height: size.height,
          width: size.width,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        )
            : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BackButton(),
              ),
              SizedBox(
                height: size.height / 8,
                width: size.width / 1.1,
                child: Row(
                  children: [
                    Container(
                      height: size.height / 11,
                      width: size.height / 11,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                      child: Icon(
                        Icons.group,
                        color: Colors.white,
                        size: size.width / 10,
                      ),
                    ),
                    SizedBox(
                      width: size.width / 20,
                    ),
                    Expanded(
                      child: Text(
                        widget.groupName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: size.width / 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              //

              SizedBox(
                height: size.height / 20,
              ),

              SizedBox(
                width: size.width / 1.1,
                child: Text(
                  "${membersList.length} Members",
                  style: TextStyle(
                    fontSize: size.width / 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(
                height: size.height / 20,
              ),

              // Members Name

              checkAdmin()
                  ? ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddMembersInTheGroupScreen(
                      groupChatId: widget.groupId,
                      name: widget.groupName,
                      membersList: membersList,
                    ),
                  ),
                ),
                leading: const Icon(
                  Icons.add,
                ),
                title: Text(
                  "Add Members",
                  style: TextStyle(
                    fontSize: size.width / 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
                  : const SizedBox(),

              Flexible(
                child: ListView.builder(
                  itemCount: membersList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () => showDialogBox(index),
                      leading:
                      const Center(child: Icon(Icons.account_circle)),
                      title: Text(
                        membersList[index]['name'],
                        style: TextStyle(
                          fontSize: size.width / 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(membersList[index]['email']),
                      trailing: Text(
                          membersList[index]['isAdmin'] ? "Admin" : ""),
                    );
                  },
                ),
              ),

              ListTile(
                onTap: onLeaveGroup,
                leading: const Icon(
                  Icons.logout,
                  color: Colors.redAccent,
                ),
                title: Text(
                  "Leave Group",
                  style: TextStyle(
                    fontSize: size.width / 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
