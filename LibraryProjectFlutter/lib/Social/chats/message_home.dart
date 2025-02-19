import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:library_project/Social/chats/private_chat_screen.dart';
import 'package:library_project/core/appbar.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/core/conditional_widget.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/Social/chats/chat_screen.dart';
import 'package:library_project/Social/chats/create_chat.dart';
import 'package:library_project/models/message.dart';
import 'package:library_project/models/user.dart';
import 'package:library_project/ui/widgets/user_avatar_widget.dart';

class MessageHome extends StatefulWidget {
  final User user; // only used for rendering the appbar
  const MessageHome(this.user, {super.key});

  @override
  State<MessageHome> createState() => _MessageHomeState();
}

class _MessageHomeState extends State<MessageHome> {
  final _database = FirebaseDatabase.instance.ref();
  ValueNotifier<String> searchQuery = ValueNotifier('');
  // Since this page is loaded into memory via offstage from the bottombar right when the app starts up, it would previously try to setup
  // streams listening on user's data, but the user is not fetched yet. So this listener simply waits for the user data to be fetched
  // and just refreshes the page. There is also logic to not render the page at all in the build method until the userModel value is set.
  late final VoidCallback _userHasBeenSetListener;

  @override
  void initState() {
    super.initState();
    _userHasBeenSetListener = () {
      if (userModel.value != null) {
        // user is set here so we can start rendering this page
        setState(() {});
        userModel.removeListener(_userHasBeenSetListener);
      }
    };
    userModel.addListener(_userHasBeenSetListener);
  }

  @override
  void dispose() {
    userModel.removeListener(_userHasBeenSetListener); // if the listener is already removed this call gets ignored so its fine
    super.dispose();
  }

  void goToNewChatScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (userModel.value == null) { // This page's logic requires userModel value to be set. This page's initState() handles it.
      return const SizedBox.shrink();
    }
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: CustomAppBar(widget.user, title: "Chats"),
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
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
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
                                contact = UserModel.fromJson(snapshot.data!.snapshot.value as Map<dynamic, dynamic>, snapshot.data!.snapshot.key!);
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
    return DateFormat('hh:mm a').format(date.toLocal());
  }

  Widget _createAvatarWidget(Chat chat, UserModel? contact) {
    final avatarColor = contact?.avatarColor ?? chat.avatarColor;
    final chatImage = chat.chatImage;
    final photoUrl = contact?.photoUrl;

    return UserAvatarWidget(
      photoUrl: chat.type == ChatType.group ? chatImage : photoUrl,
      name: chat.type == ChatType.group ? chat.name : contact!.name,
      avatarColor: avatarColor,
    );
  }

  Widget _chatItemBuilder(BuildContext context, Chat chat, UserModel? contact) {
    return Dismissible(
      key: Key(chat.id),
      onDismissed: (direction) {
        _removeChat(chat);
      },
      confirmDismiss: (direction) async {
        return showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: Material(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _createAvatarWidget(chat, contact),
                          const SizedBox(width: 5),
                          Text(
                            chat.type == ChatType.private ? 'Delete chat' : 'Leave group',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: chat.type == ChatType.private
                            ? TextSpan(
                                style: const TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 16),
                                children: [
                                  const TextSpan(text: 'Permanently delete the chat with '),
                                  TextSpan(
                                    text: contact!.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: '?'),
                                ],
                              )
                            : TextSpan(
                                style: const TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 16),
                                children: [
                                  const TextSpan(text: 'Are you sure you want to delete and leave the group '),
                                  TextSpan(
                                    text: chat.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: '?'),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context, false);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Text('Cancel', style: TextStyle(fontSize: 16, fontFamily: 'Poppins')),
                            ),
                          ),
                          const SizedBox(width: 20),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context, true);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                'Delete chat',
                                style: TextStyle(fontSize: 16, fontFamily: 'Poppins', color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: Colors.red,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconsaxPlusLinear.trash, color: Colors.white),
            Text(
              'Delete',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            ),
          ],
        ),
      ),
      child: GestureDetector(
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
      ),
    );
  }

  void _removeChat(Chat chat) async {
    await dbReference.child('userChats/${userModel.value!.uid}/${chat.id}').remove();
    if (chat.type == ChatType.group) {
      await dbReference.child('chats/${chat.id}/participants/${userModel.value!.uid}').remove();
      await checkAndDeleteGroupIfEmpty(chat);
    }

    int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    await dbReference.child('chats/${chat.id}/cleared/${userModel.value!.uid}').set(timestamp);
  }

  Future<void> checkAndDeleteGroupIfEmpty(Chat chat) async {
    final snapshot = await dbReference.child('chats/${chat.id}/participants').get();

    if (snapshot.value == null || (snapshot.value as Map).isEmpty) {
      await dbReference.child('chats/${chat.id}').remove();
    } //
    else {
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
