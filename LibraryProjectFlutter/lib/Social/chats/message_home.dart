import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:library_project/Social/chats/private_chat_screen.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/appbar.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/Social/chats/chat_screen.dart';
import 'package:library_project/Social/chats/create_chat.dart';
import 'package:library_project/models/message.dart';
import 'package:library_project/models/user.dart';
import 'package:library_project/ui/widgets/user_avatar_widget.dart';

class MessageHome extends StatefulWidget {
  final User user;

  const MessageHome(this.user, {super.key});

  @override
  State<MessageHome> createState() => _MessageHomeState();
}

class _MessageHomeState extends State<MessageHome> {
  ValueNotifier<String> searchQuery = ValueNotifier('');
  ValueNotifier<List<Chat>> chatsNotifier = ValueNotifier<List<Chat>>([]);
  List<Chat> allChats = [];
  List<UserModel> contacts = [];

  @override
  void initState() {
    super.initState();
    searchQuery.addListener(_filterChats);
    userModel.addListener(_onUserModelChanged);

    if (userModel.value != null) {
      _loadChats();
    }
  }

  @override
  void dispose() {
    searchQuery.removeListener(_filterChats);
    searchQuery.dispose();
    userModel.removeListener(_onUserModelChanged);
    chatsNotifier.dispose();
    super.dispose();
  }

  void _onUserModelChanged() {
    if (userModel.value != null) {
      _loadChats();
    }
  }

  void _filterChats() {
    if (searchQuery.value.isEmpty) {
      chatsNotifier.value = List.from(allChats);
      return;
    }

    final query = searchQuery.value.toLowerCase();
    chatsNotifier.value = allChats.where((chat) {
      if (chat.type == ChatType.private) {
        final contactId = chat.participants[0] == userModel.value!.uid ? chat.participants[1] : chat.participants[0];
        final contact = userIdToUserModel[contactId];
        if (contact != null) {
          return contact.name.toLowerCase().contains(query);
        }
        return false;
      } //
      else {
        return chat.name.toLowerCase().contains(query);
      }
    }).toList();
  }

  Future<void> _loadChats() async {
    dbReference.child('userChats/${userModel.value!.uid}').onValue.listen((event) async {
      final chatsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (chatsMap == null) {
        allChats = [];
        chatsNotifier.value = [];
        return;
      }

      List<Chat> loadedChats = [];
      for (var entry in chatsMap.entries) {
        final chatId = entry.key;
        final unreadCount = entry.value['unreadCount'] as int;
        final lastMessage = entry.value['lastMessage'];

        try {
          final chatSnapshot = await dbReference.child('chats/$chatId').get();
          if (chatSnapshot.exists) {
            final chatData = chatSnapshot.value as Map<dynamic, dynamic>;
            final chatModel = Chat.fromJson(chatId, chatData);

            Chat updatedChat;
            if (lastMessage != null) {
              updatedChat = chatModel.copyWith(
                unreadCount: unreadCount,
                lastMessage: lastMessage['text'],
                lastMessageSender: lastMessage['sender'],
                lastMessageTime: DateTime.fromMillisecondsSinceEpoch(lastMessage['timestamp']),
              );
            } else {
              updatedChat = chatModel;
            }

            loadedChats.add(updatedChat);
          }
        } catch (e) {
          print('Error loading chat $chatId: $e');
        }
      }

      loadedChats.sort((a, b) => (b.lastMessageTime ?? DateTime(1970)).compareTo(a.lastMessageTime ?? DateTime(1970)));

      allChats = loadedChats;
      _filterChats();
    });
  }

  void goToNewChatScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateChatScreen()));
  }

  Widget _buildChatItem(BuildContext context, Chat chat) {
    if (chat.type == ChatType.private) {
      final contactId = chat.participants[0] == userModel.value!.uid ? chat.participants[1] : chat.participants[0];

      final contact = userIdToUserModel[contactId];
      if (contact == null) {
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
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      return _chatItemBuilder(context, chat, contact);
    } //
    else {
      return _chatItemBuilder(context, chat, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userModel,
      builder: (context, value, child) {
        if (value == null) {
          return const SizedBox.shrink();
        }
        final size = MediaQuery.of(context).size;
        return Scaffold(
          appBar: CustomAppBar(widget.user, title: "Chats"),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: goToNewChatScreen,
            backgroundColor: Colors.green,
            label: const Text(
              'New Chat',
              style: TextStyle(fontSize: 20),
            ),
            icon: const Icon(
              Icons.add,
              size: 30,
            ),
            splashColor: Colors.blue,
            heroTag: UniqueKey(),
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
                  hintText: 'Search',
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ValueListenableBuilder<List<Chat>>(
                  valueListenable: chatsNotifier,
                  builder: (context, chats, child) {
                    if (chats.isEmpty) {
                      return const Center(
                        child: Text(
                          'No chats found.',
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: chats.length,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return _buildChatItem(context, chat);
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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

  // TODO this is very cool but its very unintuitive I would never have guessed that you could do this
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
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: chat.type == ChatType.private
                            ? TextSpan(
                                style: const TextStyle(color: Colors.black, fontSize: 16),
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
                                style: const TextStyle(color: Colors.black, fontSize: 16),
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
                              child: Text('Cancel', style: TextStyle(fontSize: 16)),
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
                                style: TextStyle(fontSize: 16, color: Colors.red),
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
              style: TextStyle(color: Colors.white),
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
                builder: (context) => PrivateChatScreen(
                  chatRoomId: chat.id,
                  contact: contact!,
                ),
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
                        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                        softWrap: true,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        (chat.type == ChatType.private && contact!.isTyping) ? 'is typing...' : chat.lastMessage ?? '',
                        style: TextStyle(
                          fontSize: 14,
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                          style: const TextStyle(color: Colors.white, fontSize: 12),
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
        content: '${userModel.value!.name} left the group',
        senderId: userModel.value!.uid,
        sentTime: DateTime.now().toUtc(),
        type: MessageType.event,
      );
      await dbReference.child('messages/${chat.id}/$id').set(message.toJson());

      for (final participantId in chat.participants) {
        if (participantId == userModel.value!.uid) continue;
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
