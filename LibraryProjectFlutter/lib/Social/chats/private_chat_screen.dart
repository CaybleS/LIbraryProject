import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/models/message.dart';
import 'package:library_project/models/user.dart';
import 'package:library_project/ui/widgets/user_avatar_widget.dart';
import 'package:uuid/uuid.dart';

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({super.key, required this.chatRoomId, required this.contact});

  final String chatRoomId;
  final UserModel contact;

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  Timer? _timer;
  final _database = FirebaseDatabase.instance.ref();
  final messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isEditing = false;
  String editingText = '';
  String messageID = '-1';
  String replyText = '';
  bool isReply = false;

  @override
  void initState() {
    super.initState();
    updateUnreadCount(widget.chatRoomId, userModel.value!.uid);
    scrollToBottom();
  }

  Future<void> scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 1));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
                      user.isTyping ? 'is typing...' : kGetTime(user.lastSignedIn),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: UserAvatarWidget(photoUrl: user.photoUrl, name: user.name, avatarColor: user.avatarColor),
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
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  itemCount: messages.length,
                  controller: _scrollController,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isMe = message.senderId == userModel.value!.uid;
                    bool isTopMessage = messages.length == index + 1;
                    return Column(
                      children: [
                        if (isTopMessage || !_isSameDay(messages[index + 1].sentTime, message.sentTime))
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.6),
                                borderRadius: const BorderRadius.all(Radius.circular(20)),
                              ),
                              child: Text(
                                _formatDate(messages[index].sentTime),
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: (size.width - 40) * 0.875),
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            padding: EdgeInsets.all(message.type == MessageType.image ? 2 : 10),
                            decoration: BoxDecoration(
                              color: message.senderId == widget.contact.uid ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(
                                    isMe || isTopMessage || messages[index + 1].senderId != messages[index].senderId
                                        ? 20
                                        : 4),
                                topRight: Radius.circular(
                                    !isMe || isTopMessage || messages[index + 1].senderId != messages[index].senderId
                                        ? 20
                                        : 4),
                                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.type == MessageType.text) ...[
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                        fontFamily: 'Poppins', fontSize: 16, color: isMe ? Colors.black : Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _createTimeTextWidget(message.sentTime),
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: isMe ? Colors.black : Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                                if (message.type == MessageType.image)
                                  Stack(
                                    alignment: Alignment.bottomLeft,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(isMe ||
                                                  isTopMessage ||
                                                  messages[index + 1].senderId != messages[index].senderId
                                              ? 20
                                              : 4),
                                          topRight: Radius.circular(!isMe ||
                                                  isTopMessage ||
                                                  messages[index + 1].senderId != messages[index].senderId
                                              ? 20
                                              : 4),
                                          bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                                          bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: message.text,
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.8),
                                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                                        ),
                                        margin: const EdgeInsets.only(left: 5, bottom: 5),
                                        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 7),
                                        child: Text(
                                          _createTimeTextWidget(message.sentTime),
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
              onChanged: (value) {
                if (_timer?.isActive ?? false) {
                  _timer?.cancel();
                }
                FirebaseDatabase.instance.ref().child('users/${userModel.value!.uid}/').update({'isTyping': true});
                _timer = Timer(
                  const Duration(milliseconds: 2000),
                  () {
                    FirebaseDatabase.instance.ref().child('users/${userModel.value!.uid}/').update({'isTyping': false});
                  },
                );
              },
              style: const TextStyle(fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: 'Message',
                hintStyle: const TextStyle(color: Colors.grey),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: IconButton(
                  onPressed: () {
                    uploadImage();
                  },
                  icon: const Icon(IconsaxPlusLinear.camera),
                ),
                prefixIconColor: Colors.blue,
                suffixIcon: IconButton(
                  onPressed: () {
                    sendMessage();
                  },
                  icon: const Icon(IconsaxPlusLinear.send_1),
                ),
                suffixIconColor: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    final messagesRef = _database.child('messages/$chatId');
    final clearedRef = _database.child('chats/$chatId/cleared/${userModel.value!.uid}');

    return clearedRef.onValue.asyncExpand((event) {
      int? clearedAt = event.snapshot.value as int?;

      return messagesRef.orderByChild('sentTime').startAt(clearedAt ?? 0).onValue.map((event) {
        final messagesMap = event.snapshot.value;

        if (messagesMap == null) return [];
        return (messagesMap as Map).entries.map((entry) {
          return MessageModel.fromJson(entry.key, entry.value);
        }).toList()
          ..sort((a, b) => b.sentTime.compareTo(a.sentTime));
      });
    });
  }

  String _createTimeTextWidget(DateTime hm) {
    return DateFormat('hh:mm a').format(hm);
  }

  String kGetTime(DateTime lastSign) {
    int time = DateTime.now().toUtc().difference(lastSign.toUtc()).inMinutes;
    print(time);
    if (time <= 1) return 'Active now';
    if (time > 1 && time < 60) return 'Last seen $time minutes ago';
    if (time > 60 && time <= 1440) return 'Last seen ${time ~/ 60} hour${time ~/ 60 == 1?'':'s'} ago';
    if (time >= 1440 && time < 10080) return 'Last seen less than a week';
    return 'Last seen a long time ago';
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
        await _database.child('messages/${widget.chatRoomId}/$messageID').update({
          'editedText': editingText,
          'isEdited': true,
        });
      } //
      else {
        final id = _database.child('messages/${widget.chatRoomId}').push().key;
        MessageModel message = MessageModel(
          id: id!,
          text: messageText,
          senderId: userModel.value!.uid,
          sentTime: DateTime.now(),
        );
        if (isReply) {
          message.replyTo = replyText;
          message.userReply = widget.contact.name;
        }

        await _database.child('messages/${widget.chatRoomId}/$id').set(message.toJson());
        await _database.child('chats/${widget.chatRoomId}').update(Chat(
              id: widget.chatRoomId,
              name: '${widget.contact.name}*${userModel.value!.name}',
              participants: [userModel.value!.uid, widget.contact.uid],
            ).toJson());
        await _database.child('userChats/${userModel.value!.uid}/${widget.chatRoomId}').update({
          'lastMessage': {
            'text': messageText,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sender': userModel.value!.uid
          },
          'unreadCount': 0
        });
        await _database.child('userChats/${widget.contact.uid}/${widget.chatRoomId}').update({
          'lastMessage': {
            'text': messageText,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sender': userModel.value!.uid
          },
          'unreadCount': ServerValue.increment(1)
        });
      }
      scrollToBottom();
    }
  }

  Future<void> updateUnreadCount(String chatId, String userId) async {
    await _database.child('userChats/$userId/$chatId/unreadCount').set(0);
  }

  bool _isSameDay(DateTime sentTime, DateTime sentTime2) {
    return sentTime.day == sentTime2.day && sentTime.month == sentTime2.month && sentTime.year == sentTime2.year;
  }

  String _formatDate(DateTime sentTime) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (_isSameDay(sentTime, now)) return 'Today';
    if (_isSameDay(sentTime, yesterday)) return 'Yesterday';
    return DateFormat('MM/dd/yyyy').format(sentTime);
  }

  void uploadImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? xFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (xFile != null) {
      File image = File(xFile.path);
      String filename = const Uuid().v1();

      final Reference imageRef = FirebaseStorage.instance.ref().child('chatImages/$filename');

      var uploadTask = await imageRef.putFile(image).catchError((error) {
        return null;
      });

      String url = await uploadTask.ref.getDownloadURL();
      final messageId = _database.child('messages/${widget.chatRoomId}').push().key!;
      MessageModel message = MessageModel(
        id: messageId,
        senderId: userModel.value!.uid,
        text: url,
        type: MessageType.image,
        sentTime: DateTime.now(),
      );
      Map<String, dynamic> userLastMessage = {
        'text': '${userModel.value!.name}: Photo',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sender': userModel.value!.uid
      };
      await _database.child('messages/${widget.chatRoomId}/$messageId').set(message.toJson());

      await _database
          .child('userChats/${userModel.value!.uid}/${widget.chatRoomId}')
          .update({'lastMessage': userLastMessage, 'unreadCount': 0});
      await _database
          .child('userChats/${widget.contact.uid}/${widget.chatRoomId}')
          .update({'lastMessage': userLastMessage, 'unreadCount': ServerValue.increment(1)});
      scrollToBottom();
    }
  }
}
