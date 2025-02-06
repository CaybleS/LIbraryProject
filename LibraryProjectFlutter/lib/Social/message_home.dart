import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:library_project/Social/private_chat_screen.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/core/conditional_parent_widget.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/Social/chat_screen.dart';
import 'package:library_project/Social/create_chat.dart';
import 'package:library_project/models/user.dart';

class MessageHome extends StatefulWidget {
  const MessageHome({super.key});

  @override
  State<MessageHome> createState() => _MessageHomeState();
}

class _MessageHomeState extends State<MessageHome> {
  final _database = FirebaseDatabase.instance.ref();
  ValueNotifier<String> searchQuery = ValueNotifier('');

  void goToNewChatScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(IconsaxPlusLinear.arrow_left_1, color: Colors.white, size: 30),
        ),
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      backgroundColor: Colors.grey[400],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          goToNewChatScreen();
        },
        backgroundColor: Colors.green,
        label: const Text(
          'New Chat',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 20),
        ),
        icon: const Icon(
          Icons.add,
          size: 30,
        ),
        splashColor: Colors.blue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            width: size.width * .85,
            child: SearchBar(
              onChanged: (value) {
                searchQuery.value = value;
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder(
              stream: getChatList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text(
                    'No chats found.',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ));
                }
                List<Chat> chats = snapshot.data!;

                return ValueListenableBuilder<String>(
                  valueListenable: searchQuery,
                  builder: (context, value, child) {
                    List<Chat> filteredChats = snapshot.data!;
                    if (value.isNotEmpty) {
                      filteredChats =
                          chats.where((chat) => chat.name.toLowerCase().contains(value.toLowerCase())).toList();
                    } //
                    else {
                      filteredChats = snapshot.data!;
                    }
                    if (filteredChats.isEmpty) {
                      return const Center(
                        child: Text(
                          'No chats found.',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: filteredChats.length,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        UserModel? contact;
                        return ConditionalWidget.single(
                          context: context,
                          conditionBuilder: (context) => chat.type == ChatType.private,
                          widgetBuilder: (context) {
                            final contactId = chat.participants[0] == userModel.value!.uid
                                ? chat.participants[1]
                                : chat.participants[0];
                            return StreamBuilder(
                              stream: _database.child('users/$contactId').onValue,
                              builder: (context, snapshot) {
                                if (snapshot.data?.snapshot.value == null) {
                                  return Container(
                                    height: 70,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
                                          ),
                                          width: 50,
                                          height: 50,
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'L',
                                            style: TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 20),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Loading...',
                                              style:
                                                  TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 18),
                                            ),
                                            Text(
                                              'Loading...',
                                              style: TextStyle(fontFamily: 'Poppins', color: Colors.black),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                } //
                                contact = UserModel.fromJson(snapshot.data!.snapshot.value as Map<dynamic, dynamic>);
                                return _chatItemBuilder(context, chat, contact);
                              },
                            );
                          },
                          fallbackBuilder: (context) {
                            return _chatItemBuilder(context, chat, contact);
                          },
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Chat>> getChatList() {
    return _database.child('userChats/${userModel.value!.uid}').onValue.asyncMap((event) async {
      final chatsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (chatsMap == null) return [];

      final List<Chat> chats = [];
      for (var entry in chatsMap.entries) {
        final chatId = entry.key;
        final unreadCount = entry.value['unreadCount'] as int;
        final lastMessage = entry.value['lastMessage'];
        final chatRef = _database.child('chats/$chatId');

        final chatSnapshot = await chatRef.get();
        if (chatSnapshot.exists) {
          final chatData = chatSnapshot.value as Map<dynamic, dynamic>;
          final chatModel = Chat.fromJson(chatId, chatData);
          if (lastMessage != null) {
            chats.add(chatModel.copyWith(
              unreadCount: unreadCount,
              lastMessage: lastMessage['text'],
              lastMessageSender: lastMessage['sender'],
              lastMessageTime: DateTime.fromMillisecondsSinceEpoch(lastMessage['timestamp']),
            ));
          } //
          else {
            chats.add(chatModel);
          }
        }
      }
      return chats..sort((a, b) => b.lastMessageTime!.compareTo(a.lastMessageTime!));
    });
  }

  String _formatTimestamp(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  Widget _createAvatarWidget(Chat chat, UserModel? contact) {
    final avatarColor = contact?.avatarColor ?? chat.avatarColor;
    final chatImage = chat.chatImage;
    final photoUrl = contact?.photoUrl;

    return CircleAvatar(
      radius: 25,
      backgroundImage: chat.type == ChatType.group
          ? (chatImage != null ? CachedNetworkImageProvider(chatImage) : null)
          : (photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null),
      child: chatImage == null && photoUrl == null
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor,
              ),
              width: 50,
              height: 50,
              alignment: Alignment.center,
              child: Text(
                chat.type == ChatType.group ? chat.name[0].toUpperCase() : contact!.name[0].toUpperCase(),
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 20),
              ),
            )
          : null,
    );
  }

  Widget _chatItemBuilder(BuildContext context, Chat chat, UserModel? contact) {
    return GestureDetector(
      onTap: () async {
        showBottombar = false;
        refreshBottombar.value = true;
        if (chat.type == ChatType.private) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrivateChatScreen(chatRoomId: chat.id, contact: contact!),
            ),
          );
        } //
        else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chat: chat),
            ),
          );
        }
        showBottombar = true;
        refreshBottombar.value = true;
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Stack(
                children: [
                  _createAvatarWidget(chat, contact),
                  if (chat.type == ChatType.private && contact!.isActive == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.lightGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.type == ChatType.private ? contact!.name : chat.name,
                      style: const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 18),
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      (chat.type == ChatType.private && contact!.isTyping) ? 'is typing...' : chat.lastMessage ?? '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: (chat.lastMessageSender != userModel.value!.uid ||
                                chat.type == ChatType.private && contact!.isTyping)
                            ? Colors.blue
                            : Colors.black,
                      ),
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTimestamp(chat.lastMessageTime!),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey),
                  ),
                  if (chat.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${chat.unreadCount}',
                        style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
