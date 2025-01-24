import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/private_chat_screen.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/Social/chat_screen.dart';
import 'package:library_project/Social/create_chat.dart';
import 'package:library_project/models/user.dart';
import '../app_startup/appwide_setup.dart';
import '../core/appbar.dart';

class MessageHome extends StatefulWidget {
  final User user;

  const MessageHome(this.user, {super.key});

  @override
  State<MessageHome> createState() => _MessageHomeState();
}

class _MessageHomeState extends State<MessageHome> {
  List<Chat> rooms = [];
  final _database = FirebaseDatabase.instance.ref();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  void goToNewChatScreen() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateChatScreen(widget.user)));
  }

  void openChat(String roomID) async {
    showBottombar = false;
    refreshBottombar.value = true;
    await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(widget.user, roomID: roomID)));
    showBottombar = true;
    refreshBottombar.value = true;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: displayAppBar(context, widget.user, "Chats"),
      backgroundColor: Colors.grey[400],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          goToNewChatScreen();
        },
        backgroundColor: Colors.green,
        label: const Text(
          "New Chat",
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
                setState(() {
                  searchQuery = value;
                });
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
                  return Center(child: Text("Error: ${snapshot.error}",style: const TextStyle(fontFamily: 'Poppins'),));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No chats found.",style: TextStyle(fontFamily: 'Poppins'),));
                }
                List<Chat> chats = snapshot.data!;
                if (searchQuery.isNotEmpty) {
                  chats = chats.where((chat) => chat.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                }

                return ListView.separated(
                  itemCount: chats.length,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final contactId =
                        chat.participants[0] == widget.user.uid ? chat.participants[1] : chat.participants[0];
                    return FutureBuilder(
                      future: _database.child('users/$contactId').once(),
                      builder: (context, snapshot) {
                        if (snapshot.data?.snapshot.value == null) {
                          return Container();
                        } //
                        final contact = UserModel.fromJson(snapshot.data!.snapshot.value as Map<dynamic, dynamic>);
                        return GestureDetector(
                          onTap: () async {
                            showBottombar = false;
                            refreshBottombar.value = true;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrivateChatScreen(
                                    chatRoomId: chat.id, contact: contact, currentUserId: widget.user.uid),
                              ),
                            );
                            showBottombar = true;
                            refreshBottombar.value = true;
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage: chat.chatImage != null
                                            ? CachedNetworkImageProvider(chat.chatImage!)
                                            : const AssetImage('assets/profile_pic.jpg'),
                                      ),
                                      if (contact.isActive)
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
                                          contact.name,
                                          style:
                                              const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 18),
                                          softWrap: true,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          chat.lastMessage ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: chat.messages!.values.first.senderId == widget.user.uid
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
                                        _formatTimestamp(chat.lastMessageTime),
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
                                            style: const TextStyle(
                                                fontFamily: 'Poppins', color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Chat>> getChatList() {
    return _database.child('userChats/${widget.user.uid}').onValue.asyncMap((event) async {
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
          chats.add(chatModel.copyWith(
            unreadCount: unreadCount,
            lastMessage: lastMessage['text'],
            lastMessageTime: DateTime.fromMillisecondsSinceEpoch(lastMessage['timestamp']),
          ));
        }
      }
      return chats;
    });
  }

  String _formatTimestamp(DateTime? date) {
    if (date == null) return '';
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
