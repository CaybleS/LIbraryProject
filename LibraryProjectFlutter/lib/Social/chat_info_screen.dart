import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/models/message.dart';
import 'package:library_project/models/user.dart';

class ChatInfoScreen extends StatefulWidget {
  const ChatInfoScreen({super.key, required this.chat});

  final Chat chat;

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  List<UserModel> members = [];
  late TextEditingController controller;

  @override
  void initState() {
    getMembers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              IconsaxPlusLinear.edit_2,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
        leading: GestureDetector(
          onTap: () => Navigator.pop(
            context,
            members,
          ),
          child: const Icon(IconsaxPlusLinear.arrow_left_1, color: Colors.white, size: 30),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              child: widget.chat.chatImage != null
                  ? CachedNetworkImage(
                      imageUrl: widget.chat.chatImage!,
                      fit: BoxFit.cover,
                      height: 120,
                      width: 120,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.chat.avatarColor,
                      ),
                      width: 120,
                      height: 120,
                      alignment: Alignment.center,
                      child: Text(
                        widget.chat.name[0].toUpperCase(),
                        style: const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 50),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.chat.name,
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 20),
            ),
            const SizedBox(height: 5),
            Text(
              '${widget.chat.participants.length} members',
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.black),
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
                                  style:
                                      TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            // TODO: implement leave group
                            // _leaveGroup();
                          },
                          child: const Text(
                            'Leave Group',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          return Row(
                            children: [
                              _createUserAvatar(members[index]),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    members[index].name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                  ),
                                  Text(
                                    // kGetTime(members[index].lastSignedIn),
                                    members[index].email,
                                    style: const TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                members[index].uid == widget.chat.createdBy ? 'Owner' : '',
                                style: const TextStyle(
                                    fontFamily: 'Poppins', color: Colors.green, fontWeight: FontWeight.w500),
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
    );
  }

  getMembers() async {
    for (final userId in widget.chat.participants) {
      final userRef = await dbReference.child('users/$userId').once();
      if (userRef.snapshot.value != null) {
        members.add(UserModel.fromJson(userRef.snapshot.value as Map<dynamic, dynamic>));
      }
    }
    setState(() {});
  }

  _createUserAvatar(UserModel member) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(50)),
      child: member.photoUrl != null
          ? CachedNetworkImage(
              imageUrl: member.photoUrl!,
              fit: BoxFit.cover,
              height: 50,
              width: 50,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: member.avatarColor,
              ),
              width: 50,
              height: 50,
              alignment: Alignment.center,
              child: Text(
                member.name[0].toUpperCase(),
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 25),
              ),
            ),
    );
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
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 10),
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
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: ListView.separated(
                    itemCount: newMembers.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Row(
                          children: [
                            _createUserAvatar(newMembers[index]),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  newMembers[index].name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                ),
                                Text(
                                  newMembers[index].email,
                                  style: const TextStyle(fontFamily: 'Poppins'),
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
        widget.chat.participants.add(member.uid);
        final id = dbReference.child('messages/${widget.chat.id}').push().key;
        MessageModel message = MessageModel(
          id: id!,
          text: '${userModel.value!.name} added ${member.name} to a group',
          senderId: userModel.value!.uid,
          sentTime: DateTime.now(),
          type: MessageType.event,
        );
        await dbReference.child('messages/${widget.chat.id}/$id').set(message.toJson());
      }
      for (final participantId in widget.chat.participants) {
        await dbReference.child('userChats/$participantId/${widget.chat.id}').update({
          'lastMessage': {
            'text': '${userModel.value!.name} added ${newMembers.last.name} to a group',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sender': userModel.value!.uid
          },
          'unreadCount': participantId == userModel.value!.uid ? 0 : ServerValue.increment(newMembers.length),
        });
      }
      await dbReference
          .child('chats/${widget.chat.id}/participants')
          .set({for (var uid in widget.chat.participants) uid: true});
    }
    if (mounted) Navigator.pop(context);
  }
}
