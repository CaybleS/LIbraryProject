import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/models/message.dart';
import 'package:library_project/models/user.dart';

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({super.key, required this.chatRoomId, required this.contact, required this.currentUserId});

  final String chatRoomId;
  final String currentUserId;
  final UserModel contact;

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  Timer? _timer;
  final _database = FirebaseDatabase.instance.ref();
  final messageController = TextEditingController();
  late UserModel currentUser;
  final ScrollController _scrollController = ScrollController();
  bool isEditing = false;
  String editingText = '';
  String messageID = '-1';
  String replyText = '';
  bool isReply = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      final snapshot = FirebaseDatabase.instance.ref('/users/${widget.currentUserId}').once();
      snapshot.then((value) {
        setState(() {
          currentUser = UserModel.fromJson(value.snapshot.value as Map<dynamic, dynamic>);
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        title: StreamBuilder(
          stream: FirebaseDatabase.instance.ref('users/${widget.contact.uid}').onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            final user = UserModel.fromJson(snapshot.data!.snapshot.value as Map<dynamic, dynamic>);
            return Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(IconsaxPlusLinear.arrow_left_1, color: Colors.white, size: 30),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
                    ),
                    Text(
                      user.isTyping
                          ? 'is typing...'
                          : user.isActive
                              ? 'online'
                              : kGetTime(user.lastSignedIn),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                      child: user.photoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: user.photoUrl!,
                              fit: BoxFit.cover,
                              height: 50,
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            )
                          : Image.asset(
                              'assets/profile_pic.jpg',
                              fit: BoxFit.cover,
                              height: 50,
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: getChatMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }
                List<MessageModel> messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  controller: _scrollController,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isMe = message.senderId == widget.currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: (size.width - 40) * 0.875),
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: message.senderId == widget.contact.uid ? Colors.blue : Colors.grey,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(!isMe ? 4 : 20),
                            topRight: Radius.circular(isMe ? 4 : 20),
                            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(fontFamily: 'Poppins',fontSize: 16, color: isMe ? Colors.black : Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${message.sentTime.day}/${message.sentTime.month} '
                                  '${_createTimeTextWidget(message.sentTime)}',
                                  style: TextStyle(fontFamily: 'Poppins',fontSize: 14, color: isMe ? Colors.black : Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: TextField(
                controller: messageController,
                onChanged: (value) async {
                  if (_timer?.isActive ?? false) {
                    _timer?.cancel();
                  }
                  await FirebaseDatabase.instance
                      .ref()
                      .child('users/${widget.currentUserId}/')
                      .update({'isTyping': true});
                  _timer = Timer(
                    const Duration(milliseconds: 2000),
                    () async {
                      await FirebaseDatabase.instance
                          .ref()
                          .child('users/${widget.currentUserId}/')
                          .update({'isTyping': false});
                    },
                  );
                },
                decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: const TextStyle(color: Colors.grey),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: IconButton(
                        onPressed: () {
                          // uploadImage();
                        },
                        icon: const Icon(Icons.camera_alt)),
                    prefixIconColor: Colors.blue,
                    suffixIcon: IconButton(
                        onPressed: () {
                          sendMessage();
                        },
                        icon: const Icon(Icons.send_rounded)),
                    suffixIconColor: Colors.blue),
              ))
        ],
      ),
    );
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _database.child('chats/$chatId/messages').onValue.map((event) {
      final messagesMap = event.snapshot.value;
      if (messagesMap == null) return [];
      updateUnreadCount(chatId, widget.currentUserId);
      return (messagesMap as Map).entries.map((entry) {
        return MessageModel.fromJson(entry.key, entry.value);
      }).toList()
        ..sort((a, b) => b.sentTime.compareTo(a.sentTime));
    });
  }

  String _createTimeTextWidget(DateTime hm) {
    final hours = hm.hour;
    final minutes = hm.minute;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String kGetTime(DateTime lastSign) {
    int time = DateTime.now().difference(lastSign).inMinutes;
    if (time < 1) return 'last seen recently';
    if (time >= 1 && time < 60) return '$time minutes ago';
    if (time < 60 && time >= 1440) return '${time ~/ 60} hours ago';
    if (time >= 1440 && time < 10080) return 'last seen less than a week';
    return 'last seen a long time ago';
  }

  Stream getUserData() {
    return FirebaseDatabase.instance.ref('users/${widget.contact.uid}').onValue;
  }

  void sendMessage() async {
    final messageText = messageController.text.trim();
    if (messageText.isNotEmpty) {
      messageController.clear();
      if (isEditing) {
        if (messageID == '-1') return;
        await _database.child('chats/${widget.chatRoomId}/messages/$messageID').update({
          'editedText': editingText,
          'isEdited': true,
        });
      } //
      else {
        final id = _database.child('chats/${widget.chatRoomId}/messages').push().key;
        MessageModel message = MessageModel(
          id: id!,
          text: messageText,
          senderId: currentUser.uid,
          sentTime: DateTime.now(),
        );
        if (isReply) {
          message.replyTo = replyText;
          message.userReply = widget.contact.name;
        }

        await _database.child('chats/${widget.chatRoomId}/messages/$id').set(message.toJson());
        await _database.child('chats/${widget.chatRoomId}').update(Chat(
              id: widget.chatRoomId,
              lastMessage: messageText,
              lastMessageTime: DateTime.now(),
              name: widget.contact.name,
              participants: [widget.currentUserId, widget.contact.uid],
            ).toJson());

        _database.child('chats/${widget.chatRoomId}/participants').once().then((participantsSnapshot) {
          final participants = participantsSnapshot.snapshot.value as Map<dynamic, dynamic>?;

          if (participants == null) return;
          participants.forEach((participantId, _) {
            _database.child('userChats/$participantId/${widget.chatRoomId}').update({
              'lastMessage': {
                'text': messageText,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
              'unreadCount': participantId == currentUser.uid ? 0 : ServerValue.increment(1)
            });
          });
        });
      }
    }

    // if (roomExists) {
    //   debugPrint("room already exists");
    //   Map<String, dynamic> msgMap = {
    //     'sender': widget.user.uid,
    //     'message': messageController.text,
    //     'type': 'text',
    //     'sentTime': DateTime.now().toUtc().toIso8601String()
    //   };
    //   Map<String, dynamic> shortMap = {
    //     'lastMsg': messageController.text,
    //     'lastSender': widget.user.uid,
    //     'lastTime': msgMap['sentTime']
    //   };
    //
    //   DatabaseReference newMsgRef = dbRef.child('messages/${widget.roomID}/').push();
    //   newMsgRef.set(msgMap);
    //
    //   for (var n in names.keys) {
    //     DatabaseReference tempRef = dbRef.child('chatsByUser/$n/${widget.roomID}');
    //     tempRef.update(shortMap);
    //   }
    //
    //   messageController.clear();
    // } else {
    //   debugPrint("room needs creation");
    //   Map<String, dynamic> msgMap = {
    //     'sender': widget.user.uid,
    //     'message': messageController.text,
    //     'type': 'text',
    //     'sentTime': DateTime.now().toUtc().toIso8601String()
    //   };
    //   Map<String, dynamic> shortMap = {
    //     'type': type,
    //     'lastMsg': messageController.text,
    //     'lastSender': widget.user.uid,
    //     'lastTime': msgMap['sentTime']
    //   };
    //   Map<String, dynamic> chatInfoMap = {'type': type};
    //   if (type == "individual") {
    //     shortMap['name'] = widget.inChat[0].friendId;
    //   } else {
    //     shortMap['name'] = name;
    //     chatInfoMap['name'] = name;
    //   }
    //   Map<String, String> members = {};
    //   for (Friend f in widget.inChat) {
    //     members[f.friendId] = f.friendId;
    //   }
    //   members[widget.user.uid] = widget.user.uid;
    //   chatInfoMap['members'] = members;
    //
    //   DatabaseReference chatListRef = dbRef.child('messages/').push();
    //   widget.roomID = chatListRef.key!;
    //   dbRef.child('messages/${widget.roomID}/').push().set(msgMap);
    //
    //   DatabaseReference tempRef = dbRef.child('chatsByUser/${widget.user.uid}/${widget.roomID}');
    //   tempRef.set(shortMap);
    //   for (Friend f in widget.inChat) {
    //     if (type == "individual") {
    //       shortMap['name'] = widget.user.uid;
    //     }
    //     DatabaseReference tempRef = dbRef.child('chatsByUser/${f.friendId}/${widget.roomID}');
    //     tempRef.set(shortMap);
    //   }
    //
    //   DatabaseReference chatInfoRef = dbRef.child('chatInfo/${widget.roomID}');
    //   chatInfoRef.set(chatInfoMap);
    //
    //   messageController.clear();
    //   roomExists = true;
    //   setState(() {});
    //
    //   init();
    // }
  }

  Future<void> updateUnreadCount(String chatId, String userId) async {
    await FirebaseDatabase.instance.ref("userChats/$userId/$chatId/unreadCount").set(0);
  }
}
