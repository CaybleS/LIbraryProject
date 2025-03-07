import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/Social/chats/create_group_chat_screen.dart';
import 'package:shelfswap/Social/chats/private_chat_screen.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/models/user.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/widgets/user_avatar_widget.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final controller = TextEditingController();
  List<UserModel> friendsResult = [];

  @override
  void initState() {
    super.initState();
    resetFriendsResult();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void resetFriendsResult() {
    friendsResult = userIdToUserModel.entries.where((MapEntry friend) => friendIDs.contains(friend.value.uid)).map((entry) => entry.value).toList();
    setState(() {});
  }

  void createChat(UserModel user) async {
    String id = await getChatRoomId(userModel.value!.uid, user.uid);
    showBottombar = false;
    refreshBottombar.value = true;
    if (mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrivateChatScreen(chatRoomId: id, contact: user),
        ),
      );
    }
    showBottombar = true;
    refreshBottombar.value = true;

  }

  Future<String> getChatRoomId(String currentUser, String contact) async {
    final snapshot = await _database.child('chats/$currentUser*$contact').get();
    if (snapshot.exists) {
      return '$currentUser*$contact';
    } //
    else {
      final snapshot = await _database.child('chats/$contact*$currentUser').get();
      if (snapshot.exists) {
        return '$contact*$currentUser';
      } //
      else {
        return '$currentUser*$contact';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Create Chat',
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupChatScreen()));
        },
        backgroundColor: Colors.green,
        label: const Text(
          'Create Group',
          style: TextStyle(fontSize: 18),
        ),
        splashColor: Colors.blue,
        heroTag: UniqueKey(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child:
              TextField(
              controller: controller,
              onChanged: (value) {
                if (value.isEmpty) {
                  resetFriendsResult();
                } //
                else {
                  friendsResult =
                      userIdToUserModel.entries.where((element) => friendIDs.contains(element.value.uid) && element.value.name.toLowerCase().contains(value.toLowerCase())).map((entry) => entry.value).toList();
                }
                setState(() {});
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search Friend',
                hintStyle: const TextStyle(color: Colors.grey),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    resetFriendsResult();
                    controller.clear();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
            )),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: friendsResult.length,
                itemBuilder: (BuildContext context, int index) {
                  final user = friendsResult[index];
                  return InkWell(
                    onTap: () {
                      createChat(user);
                    },
                    child: Card(
                      margin: const EdgeInsets.all(5),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(1, 0, 5, 0),
                              child: UserAvatarWidget(photoUrl: user.photoUrl, name: user.name, avatarColor: user.avatarColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                                    softWrap: true,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user.username,
                                    style: const TextStyle(color: Colors.black, fontSize: 14),
                                    softWrap: true,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
