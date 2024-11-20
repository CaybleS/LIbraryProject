import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../Widgets/ShowImage_Widget.dart';

class ChatRoomScreen extends StatelessWidget {
  ChatRoomScreen({super.key, required this.chatRoomId, required this.userMap});

  final Map<String, dynamic> userMap;
  final String chatRoomId;
  final TextEditingController _message = TextEditingController();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? imageFile;
  int status = 1;
  final ScrollController _scrollController = ScrollController();
  Future getImage() async {
    ImagePicker picker = ImagePicker();
    await picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future<void> scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future uploadImage() async {
    String fileName = const Uuid().v1();
    int status = 1;

    await _database.ref('chatRoom/$chatRoomId/chats').child(fileName).set({
      "sendBy": _auth.currentUser!.displayName,
      "message": "",
      "type": "image",
      "time": DateTime.now().millisecondsSinceEpoch,
    });

    var ref =
        FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    var uploadTask = await ref.putFile(imageFile!).catchError((error) async {
      await _database
          .ref('chatRoom/$chatRoomId/chats')
          .child(fileName)
          .remove();

      status = 0;
    });

    if (status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();

      await _database
          .ref('chatRoom/$chatRoomId/chats')
          .child(fileName)
          .update({"message": imageUrl});

      debugPrint(imageUrl);
    }
  }

  void onSendMessage() async {
    if (_message.text.isNotEmpty) {
      Map<String, dynamic> messages = {
        "sendBy": _auth.currentUser!.displayName,
        "message": _message.text,
        "type": "text",
        "time": DateTime.now().millisecondsSinceEpoch,
      };
      _message.clear();
      await _database.ref("chatRoom/$chatRoomId/chats").push().set(messages);
      scrollToBottom();
    } else {
      debugPrint("Enter Text");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
          title: StreamBuilder(
        stream: _database.ref("users/${userMap["uid"]}/status").onValue,
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            return Column(
              children: [
                Text(userMap["name"]),
                Text(
                  snapshot.data!.snapshot.value.toString(),
                  style: const TextStyle(fontSize: 12),
                )
              ],
            );
          } else {
            return Container();
          }
        },
      )),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _database
                  .ref("chatRoom/$chatRoomId/chats")
                  .orderByChild("time")
                  .onValue,
              builder: (BuildContext context,
                  AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> chatMap =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List chatList = chatMap.values.toList();
                  chatList.sort((a, b) => a['time'].compareTo(b['time']));
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: chatList.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> map =
                          Map<String, dynamic>.from(chatList[index]);
                      return messages(size, map, context);
                    },
                  );
                } else {
                  return const Center(child: Text("No messages yet"));
                }
              },
            ),
          ),
          Container(
            alignment: Alignment.center,
            height: size.height / 10,
            width: size.width,
            child: SizedBox(
              height: size.height / 12,
              width: size.width / 1.17,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () => getImage(),
                          icon: const Icon(Icons.photo),
                        ),
                        hintText: "Send Message",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onSendMessage,
                    icon: const Icon(Icons.send),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    return map['type'] == "text"
        ? Container(
            width: size.width,
            alignment: map['sendBy'] == _auth.currentUser!.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: map['sendBy'] == _auth.currentUser!.displayName
                    ? Colors.lightBlueAccent
                    : Colors.black38,
              ),
              child: Text(
                map['message'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          )
        : Container(
            height: size.height / 2.5,
            width: size.width,
            color: map['sendBy'] == _auth.currentUser!.displayName
                ? Colors.lightBlueAccent
                : Colors.black38,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            alignment: map['sendBy'] == _auth.currentUser!.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShowImage(
                    imageUrl: map['message'],
                  ),
                ),
              ),
              child: Container(
                height: size.height / 2.5,
                width: size.width / 2,
                decoration: BoxDecoration(border: Border.all()),
                alignment: map['message'] != "" ? null : Alignment.center,
                child: map['message'] != ""
                    ? Image.network(
                        map['message'],
                        fit: BoxFit.cover,
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          );
  }
}
