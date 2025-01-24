import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/private_chat_screen.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/user.dart';

class CreateChatScreen extends StatefulWidget {
  final User user;

  const CreateChatScreen(this.user, {super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  late TextEditingController controller;
  final TextEditingController groupNameController = TextEditingController();
  List<UserModel> inChat = [];

  @override
  void initState() {
    super.initState();

    getAppFriends();
  }

  getAppFriends() async {
    final friends = await getFriends(widget.user);
    print(friends);
  }

  void addFriend(UserModel friend) {
    if (inChat.contains(friend)) return;
    inChat.add(friend);

    controller.clear;

    setState(() {});
  }

  void removeFriend(int index) {
    inChat.remove(inChat[index]);

    setState(() {});
  }

  void createChat() async {
    if (inChat.length == 1) {
      String id = FirebaseDatabase.instance.ref('chats/').push().key!;
      showBottombar = false;
      refreshBottombar.value = true;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrivateChatScreen(
            chatRoomId: id,
            contact: inChat.first,
            currentUserId: widget.user.uid,
          ),
        ),
      );
      showBottombar = true;
      refreshBottombar.value = true;
    } else if (inChat.length > 1 && groupNameController.text.isNotEmpty) {
      // Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) => ChatScreen(
      //               widget.user,
      //               inChat: inChat,
      //               name: groupNameController.text,
      //             )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          createChat();
        },
        backgroundColor: inChat.isNotEmpty ? Colors.green : Colors.grey,
        label: const Text(
          "Create Chat",
          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
        ),
        splashColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[400],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Autocomplete<UserModel>(
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                controller = textEditingController;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (String value) => onFieldSubmitted,
                  style: const TextStyle(fontFamily: 'Poppins'),
                  decoration: InputDecoration(
                    hintText: 'Add Friend',
                    hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                    suffixIcon: InkWell(onTap: controller.clear, child: const Icon(Icons.close)),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              displayStringForOption: (option) => option.email,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<UserModel>.empty();
                } else {
                  return friends.where((UserModel friend) {
                    return friend.email.toLowerCase().contains(controller.text.toLowerCase());
                  });
                }
              },
              onSelected: (option) {
                controller.text = '';
                addFriend(option);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: inChat.length,
                itemBuilder: (BuildContext context, int index) {
                  final user = inChat[index];
                  return Card(
                    margin: const EdgeInsets.all(5),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: user.photoUrl != null
                                ? CachedNetworkImageProvider(user.photoUrl!)
                                : const AssetImage('assets/profile_pic.jpg'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(color: Colors.black, fontSize: 20),
                                  softWrap: true,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user.email,
                                  style: const TextStyle(color: Colors.black, fontSize: 16),
                                  softWrap: true,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              removeFriend(index);
                            },
                            child: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: size.width * 0.9,
              child: Visibility(
                visible: inChat.length > 1,
                child: TextField(
                  controller: groupNameController,
                  decoration: InputDecoration(
                      hintText: 'Group Name',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
