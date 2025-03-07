import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shelfswap/Social/chats/edit_chat_info_screen.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/core/conditional_widget.dart';
import 'package:shelfswap/database/database.dart';
import 'package:shelfswap/models/chat.dart';
import 'package:shelfswap/models/message.dart';
import 'package:shelfswap/models/user.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/widgets/user_avatar_widget.dart';

class ChatInfoScreen extends StatefulWidget {
  const ChatInfoScreen({super.key, required this.chat});

  final Chat chat;

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  List<UserModel> members = [];
  late TextEditingController controller;
  late Chat chat = widget.chat;

  @override
  void initState() {
    getMembers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, chat);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.appbarColor,
          actions: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                    context, MaterialPageRoute(builder: (context) => EditChatInfoScreen(chat: chat)));
                if (result != null) {
                  setState(() {
                    chat = result;
                  });
                }
              },
              child: const Icon(
                IconsaxPlusLinear.edit_2,
                size: 30,
              ),
            ),
            const SizedBox(width: 10),
          ],
          leading: GestureDetector(
            onTap: () => Navigator.pop(context, chat),
            child: const Icon(Icons.arrow_back),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(60)),
                child: ConditionalWidget.single(
                  context: context,
                  conditionBuilder: (context) => chat.chatImage != null,
                  widgetBuilder: (context) {
                    return CachedNetworkImage(
                      imageUrl: chat.chatImage!,
                      fit: BoxFit.cover,
                      height: 120,
                      width: 120,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    );
                  },
                  fallbackBuilder: (context) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: chat.avatarColor,
                      ),
                      width: 120,
                      height: 120,
                      alignment: Alignment.center,
                      child: Text(
                        chat.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.black, fontSize: 50),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                chat.name,
                style: const TextStyle(color: Colors.black, fontSize: 20),
              ),
              const SizedBox(height: 5),
              Text(
                '${chat.participants.length} members',
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _showAddMemberBottomSheet();
                              },
                              child: Row(
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                    ),
                                    width: 50,
                                    height: 50,
                                    alignment: Alignment.center,
                                    child: const Icon(IconsaxPlusLinear.add, color: Colors.white, size: 30),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Add Members',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              _leaveGroup();
                            },
                            child: const Text(
                              'Leave Group',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final user = members[index];
                            return Row(
                              children: [
                                UserAvatarWidget(
                                    photoUrl: user.photoUrl, name: user.name, avatarColor: user.avatarColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    Text(
                                      members[index].name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      // kGetTime(members[index].lastSignedIn),
                                      members[index].username,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    members[index].uid == chat.createdBy ? 'Owner' : '',
                                    style: const TextStyle(
                                      color: Colors.green, fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return const SizedBox(height: 10);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  getMembers() async {
    for (final userId in chat.participants) {
      final userRef = await dbReference.child('users/$userId').once();
      if (userRef.snapshot.value != null) {
        members.add(UserModel.fromJson(userRef.snapshot.value as Map<dynamic, dynamic>, userRef.snapshot.key!));
      }
    }
    setState(() {});
  }

  _showAddMemberBottomSheet() {
    List<UserModel> newMembers = [];
    showModalBottomSheet(
      context: context,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.5,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Members',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 10),
                Autocomplete<UserModel>(
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    controller = textEditingController;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onSubmitted: (String value) => onFieldSubmitted,
                      decoration: InputDecoration(
                        hintText: 'Add Friend',
                        hintStyle: const TextStyle(color: Colors.grey),
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
                      var filtered = userIdToUserModel.entries.where((MapEntry friend) => friendIDs.contains(friend.value.uid) && friend.value.uid.toLowerCase().contains(controller.text.toLowerCase()));
                      return Map.fromEntries(filtered).entries.map((entry) => entry.value);
                    }
                  },
                  onSelected: (option) {
                    controller.text = '';
                    if (!members.contains(option) && !newMembers.contains(option)) {
                      newMembers.add(option);
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    await _addMemberToGroup(newMembers);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: ListView.separated(
                    itemCount: newMembers.length,
                    itemBuilder: (context, index) {
                      final user = newMembers[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Row(
                          children: [
                            UserAvatarWidget(photoUrl: user.photoUrl, name: user.name, avatarColor: user.avatarColor),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  newMembers[index].name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  newMembers[index].username,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(height: 10);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ).whenComplete(() {
      setState(() {});
    });
  }

  Future<void> _addMemberToGroup(List<UserModel> newMembers) async {
    if (newMembers.isNotEmpty) {
      for (final member in newMembers) {
        members.add(member);
        chat.participants.add(member.uid);
        final id = dbReference.child('messages/${chat.id}').push().key;
        MessageModel message = MessageModel(
          id: id!,
          text: '${userModel.value!.name} added ${member.name} to a group',
          senderId: userModel.value!.uid,
          sentTime: DateTime.now().toUtc(),
          type: MessageType.event,
        );
        await dbReference.child('messages/${chat.id}/$id').set(message.toJson());
      }
      for (final participantId in chat.participants) {
        await dbReference.child('userChats/$participantId/${chat.id}').update({
          'lastMessage': {
            'text': '${userModel.value!.name} added ${newMembers.last.name} to a group',
            'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
            'sender': userModel.value!.uid
          },
          'unreadCount': participantId == userModel.value!.uid ? 0 : ServerValue.increment(newMembers.length),
        });
      }
      await dbReference.child('chats/${chat.id}/participants').set({for (var uid in chat.participants) uid: true});
    }
    if (mounted) Navigator.pop(context);
  }

  void _leaveGroup() async {
    await dbReference.child('chats/${chat.id}/participants/${userModel.value!.uid}').remove();
    await dbReference.child('userChats/${userModel.value!.uid}/${chat.id}').remove();

    await checkAndDeleteGroupIfEmpty();
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  Future<void> checkAndDeleteGroupIfEmpty() async {
    final snapshot = await dbReference.child('chats/${chat.id}/participants').get();

    if (snapshot.value == null || (snapshot.value as Map).isEmpty) {
      await dbReference.child('chats/${chat.id}').remove();
    }//
    else{
      int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      await dbReference.child('chats/${chat.id}/cleared/${userModel.value!.uid}').set(timestamp);

      final id = dbReference.child('messages/${chat.id}').push().key;
      MessageModel message = MessageModel(
        id: id!,
        text: '${userModel.value!.name} left the group',
        senderId: userModel.value!.uid,
        sentTime: DateTime.now().toUtc(),
        type: MessageType.event,
      );
      await dbReference.child('messages/${chat.id}/$id').set(message.toJson());

      for (final participantId in chat.participants) {
        if(participantId == userModel.value!.uid) continue;
        await dbReference.child('userChats/$participantId/${chat.id}').update({
          'lastMessage': {
            'text': '${userModel.value!.name} left the group',
            'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
            'sender': userModel.value!.uid
          },
          'unreadCount': ServerValue.increment(1),
        });
      }
    }
  }
}
