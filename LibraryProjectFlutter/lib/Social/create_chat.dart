import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/chat_screen.dart';
import 'package:library_project/Social/private_chat_screen.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/models/message.dart';
import 'package:library_project/models/user.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _database = FirebaseDatabase.instance.ref();
  late TextEditingController controller;
  final TextEditingController groupNameController = TextEditingController();
  List<UserModel> members = [];

  @override
  void initState() {
    super.initState();
  }

  void addFriend(UserModel friend) {
    if (members.contains(friend)) return;
    members.add(friend);

    controller.clear;

    setState(() {});
  }

  void removeFriend(int index) {
    members.remove(members[index]);

    setState(() {});
  }

  void createChat() async {
    if (members.length == 1) {
      String id = await getChatRoomId(userModel.value!.uid, members.first.uid);
      showBottombar = false;
      refreshBottombar.value = true;
      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PrivateChatScreen(chatRoomId: id, contact: members.first),
          ),
        );
      }
      showBottombar = true;
      refreshBottombar.value = true;
    } //
    else if (members.length > 1 && groupNameController.text.trim().isNotEmpty) {
      members.add(userModel.value!);
      String id = _database.child('chats/').push().key!;
      Chat chat = Chat(
        id: id,
        name: groupNameController.text.trim(),
        avatarColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
        participants: members.map((e) => e.uid).toList(),
        type: ChatType.group,
        createdBy: userModel.value!.uid,
      );

      await _database.child('chats/$id').set(chat.toJson());
      final messageId = _database.child('chats/$id/messages').push().key;
      MessageModel message = MessageModel(
        id: messageId!,
        text: '${userModel.value!.name} created the group «${groupNameController.text.trim()}»',
        senderId: userModel.value!.uid,
        sentTime: DateTime.now(),
      );
      await _database.child('chats/$id/messages/$messageId').set(message.toJson());

      for (var member in members) {
        await _database.child('userChats/${member.uid}/$id').set({
          'lastMessage': {
            'text': '${userModel.value!.name} created the group «${groupNameController.text.trim()}»',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sender': userModel.value!.uid,
          },
          'unreadCount': 0,
        });
      }
      showBottombar = false;
      refreshBottombar.value = true;
      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      }
      showBottombar = true;
      refreshBottombar.value = true;
    }
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          createChat();
        },
        backgroundColor: members.isNotEmpty ? Colors.green : Colors.grey,
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
                itemCount: members.length,
                itemBuilder: (BuildContext context, int index) {
                  final user = members[index];
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
                visible: members.length > 1,
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
