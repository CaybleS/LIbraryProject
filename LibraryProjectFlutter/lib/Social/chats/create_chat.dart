import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:library_project/Social/chats/create_group_chat_screen.dart';
import 'package:library_project/Social/chats/private_chat_screen.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/models/user.dart';
import 'package:library_project/ui/widgets/user_avatar_widget.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final controller = TextEditingController();
  List<UserModel> friendsResult = friends;

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
    // if (members.length == 1) {
    // } //
    // else if (members.length > 1 && groupNameController.text.trim().isNotEmpty) {
    //   members.add(userModel.value!);
    //   String chatId = _database.child('chats/').push().key!;
    //   Chat chat = Chat(
    //     id: chatId,
    //     name: groupNameController.text.trim(),
    //     avatarColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
    //     participants: members.map((e) => e.uid).toList(),
    //     type: ChatType.group,
    //     createdBy: userModel.value!.uid,
    //   );
    //
    //   await _database.child('chats/$chatId').set(chat.toJson());
    //   final messageId = _database.child('messages/$chatId').push().key;
    //   MessageModel message = MessageModel(
    //     id: messageId!,
    //     text: '${userModel.value!.name} created the group «${groupNameController.text.trim()}»',
    //     senderId: userModel.value!.uid,
    //     sentTime: DateTime.now(),
    //     type: MessageType.event,
    //   );
    //   await _database.child('messages/$chatId/$messageId').set(message.toJson());
    //
    //   for (var member in members) {
    //     await _database.child('userChats/${member.uid}/$chatId').set({
    //       'lastMessage': {
    //         'text': '${userModel.value!.name} created the group «${groupNameController.text.trim()}»',
    //         'timestamp': DateTime.now().millisecondsSinceEpoch,
    //         'sender': userModel.value!.uid,
    //       },
    //       'unreadCount': 0,
    //     });
    //   }
    //   showBottombar = false;
    //   refreshBottombar.value = true;
    //   if (mounted) {
    //     await Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => ChatScreen(chat: chat),
    //       ),
    //     );
    //   }
    //   showBottombar = true;
    //   refreshBottombar.value = true;
    // }
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
        backgroundColor: Colors.blue,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(IconsaxPlusLinear.arrow_left_1, color: Colors.white, size: 30),
        ),
        title: const Text(
          'Create Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupChatScreen()));
        },
        backgroundColor: Colors.green,
        label: const Text(
          'Create Group',
          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
        ),
        splashColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onChanged: (value) {
                if (value.isEmpty) {
                  friendsResult = friends;
                } //
                else {
                  friendsResult =
                      friends.where((element) => element.name.toLowerCase().contains(value.toLowerCase())).toList();
                }
                setState(() {});
              },
              style: const TextStyle(fontFamily: 'Poppins'),
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
                    controller.clear();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: friendsResult.length,
                itemBuilder: (BuildContext context, int index) {
                  final user = friendsResult[index];
                  return GestureDetector(
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
                            UserAvatarWidget(photoUrl: user.photoUrl, name: user.name, avatarColor: user.avatarColor),
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
