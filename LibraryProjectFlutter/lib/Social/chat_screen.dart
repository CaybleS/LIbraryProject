import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:library_project/Social/chat_info_screen.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/models/message.dart';
import 'package:library_project/models/user.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController scrollController = ScrollController();
  final Duration buttonDuration = const Duration(milliseconds: 300);
  bool isEditing = false;
  String editingText = '';
  String messageID = '-1';
  String replyText = '';
  bool isReply = false;
  List<UserModel> members = [];

  final TextEditingController messageController = TextEditingController();
  final dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      init();
    });
  }

  void init() async {
    await Future.forEach(widget.chat.participants, (userId) async {
      final userRef = await dbRef.child('users/$userId').once();
      if (userRef.snapshot.value != null) {
        members.add(UserModel.fromJson(userRef.snapshot.value as Map<dynamic, dynamic>));
      }
    });
    setState(() {});
  }

  Future<void> scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 1));
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    Widget returnWidget = StreamBuilder(
      stream: getChatMessages(widget.chat.id),
      builder: (context, snapshot) {
        if (snapshot.hasData && !snapshot.hasError) {
          List<MessageModel> messages = snapshot.data!;

          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 5),
            itemCount: messages.length,
            reverse: true,
            itemBuilder: (BuildContext context, int index) {
              final message = messages[index];
              bool isMe = userModel.value!.uid == message.senderId;
              bool isTopMessage = messages.length == index + 1;
              if (message.type == MessageType.event) {
                return Column(
                  children: [
                    if (index == messages.length - 1)
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
                      alignment: Alignment.center,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: (size.width - 40) * 0.875),
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.6),
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return FutureBuilder(
                future: dbRef.child('users/${message.senderId}').once(),
                builder: (context, snapshot) {
                  if (snapshot.data == null || snapshot.data!.snapshot.value == null) {
                    return const SizedBox();
                  }
                  final user = UserModel.fromJson(snapshot.data!.snapshot.value as Map<dynamic, dynamic>);
                  return Column(
                    children: [
                      if (!_isSameDay(messages[index + 1].sentTime, message.sentTime))
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            const SizedBox(width: 10),
                            if (!isMe) _createUserAvatar(user),
                            Container(
                              constraints: BoxConstraints(maxWidth: (size.width - 50) * 0.8),
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              padding: EdgeInsets.all(message.type == MessageType.image ? 2 : 10),
                              decoration: BoxDecoration(
                                color: message.senderId == userModel.value!.uid ? Colors.grey : Colors.blue,
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
                                  if (!isMe) ...[
                                    Padding(
                                      padding: EdgeInsets.only(left: message.type == MessageType.image ? 10 : 0),
                                      child: Text(
                                        user.name,
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  if (message.type == MessageType.text) ...[
                                    Text(
                                      message.text,
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          color: isMe ? Colors.black : Colors.white),
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
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        } //
        else {
          return const Text("");
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        title: Row(
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
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                    context, MaterialPageRoute(builder: (context) => ChatInfoScreen(chat: widget.chat)));
                if (result != null) {
                  setState(() {
                    members = [...(result as List<UserModel>)];
                  });
                }
              },
              child: Column(
                children: [
                  Text(
                    widget.chat.name,
                    style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
                  ),
                  Text(
                    '${members.length} members',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatInfoScreen(chat: widget.chat)));
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    child: widget.chat.chatImage != null
                        ? CachedNetworkImage(
                            imageUrl: widget.chat.chatImage!,
                            fit: BoxFit.cover,
                            height: 50,
                            width: 50,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.chat.avatarColor,
                            ),
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              widget.chat.name[0].toUpperCase(),
                              style: const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 20),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: returnWidget,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: TextField(
              controller: messageController,
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
    return dbRef.child('messages/$chatId').onValue.map((event) {
      final messagesMap = event.snapshot.value;
      if (messagesMap == null) return [];
      FirebaseDatabase.instance.ref('userChats/${userModel.value!.uid}/$chatId/unreadCount').set(0);
      return (messagesMap as Map).entries.map((entry) {
        return MessageModel.fromJson(entry.key, entry.value);
      }).toList()
        ..sort((a, b) => b.sentTime.compareTo(a.sentTime));
    });
  }

  String _createTimeTextWidget(DateTime hm) {
    return DateFormat('hh:mm a').format(hm);
  }

  void sendMessage() async {
    final messageText = messageController.text.trim();
    if (messageText.isNotEmpty) {
      messageController.clear();
      if (isEditing) {
        if (messageID == '-1') return;
        await dbRef.child('messages/${widget.chat.id}/$messageID').update({
          'editedText': editingText,
          'isEdited': true,
        });
      } //
      else {
        // if (isReply) {
        //   message.replyTo = replyText;
        //   message.userReply = widget.contact.name;
        // }

        final id = dbRef.child('messages/${widget.chat.id}/').push().key;
        MessageModel message = MessageModel(
          id: id!,
          text: messageText,
          senderId: userModel.value!.uid,
          sentTime: DateTime.now(),
        );

        await dbRef.child('messages/${widget.chat.id}/$id').set(message.toJson());

        for (final participantId in widget.chat.participants) {
          dbRef.child('userChats/$participantId/${widget.chat.id}').update({
            'lastMessage': {
              'text': '${userModel.value!.name}: $messageText',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'sender': userModel.value!.uid
            },
            'unreadCount': participantId == userModel.value!.uid ? 0 : ServerValue.increment(1)
          });
        }
      }
      scrollToBottom();
    }
  }

  Widget _createUserAvatar(UserModel user) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(50)),
      child: user.photoUrl != null
          ? CachedNetworkImage(
              imageUrl: user.photoUrl!,
              fit: BoxFit.cover,
              height: 50,
              width: 50,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user.avatarColor,
              ),
              width: 50,
              height: 50,
              alignment: Alignment.center,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.black, fontSize: 20),
              ),
            ),
    );
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
      final messageId = dbRef.child('messages/${widget.chat.id}').push().key!;
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
      await dbRef.child('messages/${widget.chat.id}/$messageId').set(message.toJson());

      for (final participantId in widget.chat.participants) {
        dbRef.child('userChats/$participantId/${widget.chat.id}').update({
          'lastMessage': userLastMessage,
          'unreadCount': participantId == userModel.value!.uid ? 0 : ServerValue.increment(1)
        });
      }
      scrollToBottom();
    }
  }
}
