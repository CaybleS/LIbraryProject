import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/Social/friends_page.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  String roomID;
  final User user;
  List<Friend> inChat;
  String name;
  ChatScreen(this.user,
      {this.roomID = "", this.inChat = const [], this.name = "", super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController scrollController = ScrollController();
  bool arrowVisible = false;
  bool roomExists = false;
  final Duration buttonDuration = const Duration(milliseconds: 300);

  late Map<String, String> names;
  late String type = "individual";
  late String name = "";

  final TextEditingController messageController = TextEditingController();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    roomExists = widget.roomID != "";
    if (roomExists) {
      Map<String, dynamic> tempMap = await getChatInfo(widget.roomID);

      type = tempMap['type'];
      names = tempMap['members'];
      if (type == "group") {
        name = tempMap['name'];
      } else {
        for (var child in names.keys) {
          if (child != widget.user.uid) {
            name = names[child]!;
          }
        }
      }

      await setUpScroll();
    } else {
      if (widget.inChat.length == 1) {
        name = await getUserDisplayName(widget.inChat[0].friendId);
        type = "individual";
      } else {
        name = widget.name;
        type = "group";
      }
    }

    setState(() {});
  }

  Future<void> setUpScroll() async {
    await Future.delayed(const Duration(milliseconds: 100));
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (arrowVisible == true) {
          setState(() {
            arrowVisible = false;
          });
        }
      } else if (scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (arrowVisible == false) {
          setState(() {
            arrowVisible = true;
          });
        }
      }
    });
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

    setState(() {
      arrowVisible = false;
    });
  }

  void sendMessage() async {
    debugPrint("sending");
    if (messageController.text.isNotEmpty) {
      debugPrint("has text");
      if (roomExists) {
        debugPrint("room already exists");
        Map<String, dynamic> msgMap = {
          'sender': widget.user.uid,
          'message': messageController.text,
          'type': 'text',
          'sentTime': DateTime.now().toUtc().toIso8601String()
        };
        Map<String, dynamic> shortMap = {
          'lastMsg': messageController.text,
          'lastSender': widget.user.uid,
          'lastTime': msgMap['sentTime']
        };

        DatabaseReference newMsgRef =
            dbRef.child('messages/${widget.roomID}/').push();
        newMsgRef.set(msgMap);

        for (var n in names.keys) {
          DatabaseReference tempRef =
              dbRef.child('chatsByUser/$n/${widget.roomID}');
          tempRef.update(shortMap);
        }

        messageController.clear();
      } else {
        debugPrint("room needs creation");
        Map<String, dynamic> msgMap = {
          'sender': widget.user.uid,
          'message': messageController.text,
          'type': 'text',
          'sentTime': DateTime.now().toUtc().toIso8601String()
        };
        Map<String, dynamic> shortMap = {
          'type': type,
          'lastMsg': messageController.text,
          'lastSender': widget.user.uid,
          'lastTime': msgMap['sentTime']
        };
        Map<String, dynamic> chatInfoMap = {'type': type};
        if (type == "individual") {
          shortMap['name'] = widget.inChat[0].friendId;
        } else {
          shortMap['name'] = name;
          chatInfoMap['name'] = name;
        }
        Map<String, String> members = {};
        for (Friend f in widget.inChat) {
          members[f.friendId] = f.friendId;
        }
        members[widget.user.uid] = widget.user.uid;
        chatInfoMap['members'] = members;

        DatabaseReference chatListRef = dbRef.child('messages/').push();
        widget.roomID = chatListRef.key!;
        dbRef.child('messages/${widget.roomID}/').push().set(msgMap);

        DatabaseReference tempRef =
            dbRef.child('chatsByUser/${widget.user.uid}/${widget.roomID}');
        tempRef.set(shortMap);
        for (Friend f in widget.inChat) {
          if (type == "individual") {
            shortMap['name'] = widget.user.uid;
          }
          DatabaseReference tempRef =
              dbRef.child('chatsByUser/${f.friendId}/${widget.roomID}');
          tempRef.set(shortMap);
        }

        DatabaseReference chatInfoRef =
            dbRef.child('chatInfo/${widget.roomID}');
        chatInfoRef.set(chatInfoMap);

        messageController.clear();
        roomExists = true;
        setState(() {});

        init();
      }
    } else {
      debugPrint("no text");
    }
  }

  void uploadImage() async {
    debugPrint("image upload");
    ImagePicker imagePicker = ImagePicker();
    XFile? xFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (xFile != null) {
      debugPrint("uploaded to app");
      File image = File(xFile.path);
      String filename = const Uuid().v1();
      int status = 1;

      final Reference imageRef =
          FirebaseStorage.instance.ref().child('chatImages/$filename');
      debugPrint("reference created");

      var uploadTask = await imageRef.putFile(image).catchError((error) {
        status = 0;
      });

      if (status == 1) {
        String url = await uploadTask.ref.getDownloadURL();
        debugPrint("adding msg");
        if (roomExists) {
          Map<String, dynamic> msgMap = {
            'sender': widget.user.uid,
            'message': url,
            'type': 'image',
            'sentTime': DateTime.now().toUtc().toIso8601String()
          };
          Map<String, dynamic> shortMap = {
            'lastMsg': 'Image',
            'lastSender': widget.user.uid,
            'lastTime': msgMap['sentTime']
          };

          DatabaseReference newMsgRef =
              dbRef.child('messages/${widget.roomID}/').push();
          newMsgRef.set(msgMap);

          for (var n in names.keys) {
            DatabaseReference tempRef =
                dbRef.child('chatsByUser/$n/${widget.roomID}');
            tempRef.update(shortMap);
          }
        } else {
          Map<String, dynamic> msgMap = {
            'sender': widget.user.uid,
            'message': url,
            'type': 'image',
            'sentTime': DateTime.now().toUtc().toIso8601String()
          };
          Map<String, dynamic> shortMap = {
            'type': type,
            'lastMsg': 'Image',
            'lastSender': widget.user.uid,
            'lastTime': msgMap['sentTime']
          };
          Map<String, dynamic> chatInfoMap = {'type': type};
          if (type == "individual") {
            shortMap['name'] = widget.inChat[0].friendId;
          } else {
            shortMap['name'] = name;
            chatInfoMap['name'] = name;
          }
          Map<String, String> members = {};
          for (Friend f in widget.inChat) {
            members[f.friendId] = f.friendId;
          }
          members[widget.user.uid] = widget.user.uid;
          chatInfoMap['members'] = members;

          DatabaseReference chatListRef = dbRef.child('messages/').push();
          widget.roomID = chatListRef.key!;
          dbRef.child('messages/${widget.roomID}/').push().set(msgMap);

          DatabaseReference tempRef =
              dbRef.child('chatsByUser/${widget.user.uid}/${widget.roomID}');
          tempRef.set(shortMap);
          for (Friend f in widget.inChat) {
            if (type == "individual") {
              shortMap['name'] = widget.user.uid;
            }
            DatabaseReference tempRef =
                dbRef.child('chatsByUser/${f.friendId}/${widget.roomID}');
            tempRef.set(shortMap);
          }

          DatabaseReference chatInfoRef =
              dbRef.child('chatInfo/${widget.roomID}');
          chatInfoRef.set(chatInfoMap);

          roomExists = true;
          setState(() {});

          init();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    Widget returnWidget = const Text("");

    if (roomExists) {
      returnWidget = StreamBuilder(
          stream: dbRef
              .child('messages/${widget.roomID}')
              //.orderByChild('sentTime')
              .onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                !snapshot.hasError &&
                snapshot.data!.snapshot.value != null) {
              Map<dynamic, dynamic> messages =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<dynamic> chatList = messages.values.toList();
              chatList.sort((a, b) => a['sentTime'].compareTo(b['sentTime']));

              return ListView.builder(
                  controller: scrollController,
                  itemCount: chatList.length,
                  itemBuilder: (BuildContext context, int index) {
                    bool isSender =
                        widget.user.uid == chatList[index]['sender'];
                    List<Widget> messageBlock = [];
                    DateTime time =
                        DateTime.parse(chatList[index]['sentTime']).toLocal();

                    if (!isSender && type == "group") {
                      messageBlock.add(Text(names[chatList[index]['sender']]!));
                      messageBlock.add(SizedBox(
                        height: size.height * 0.005,
                      ));
                    }

                    if (chatList[index]['type'] == 'text') {
                      messageBlock.add(Container(
                        constraints: BoxConstraints(maxWidth: size.width * 0.9),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isSender ? Colors.blue[100] : Colors.white),
                        child: Text(
                          chatList[index]['message'],
                          style: const TextStyle(fontSize: 20),
                        ),
                      ));
                    } else if (chatList[index]['type'] == 'image') {
                      messageBlock.add(ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: size.width * 0.5,
                            maxHeight: size.height * 0.5),
                        child: Image.network(chatList[index]['message']),
                      ));
                    }

                    messageBlock.add(SizedBox(
                      height: size.height * 0.005,
                    ));
                    messageBlock.add(Text(DateFormat.jm().format(time)));

                    bool newDay = (index == 0);
                    if (!newDay) {
                      DateTime prevTime =
                          DateTime.parse(chatList[index - 1]['sentTime'])
                              .toLocal();
                      newDay = !(time.year == prevTime.year &&
                          time.month == prevTime.month &&
                          time.day == prevTime.day);
                    }

                    List<Widget> withDate = [];
                    if (newDay) {
                      withDate.add(Text(DateFormat.yMEd().format(time)));
                    }
                    withDate.add(Container(
                        alignment: isSender
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: messageBlock,
                        )));

                    return Column(children: withDate);
                  });
            } else {
              return const Text("");
            }
          });
    }

    return Scaffold(
        backgroundColor: Colors.grey[400],
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(name),
        ),
        floatingActionButton: AnimatedSlide(
          offset: arrowVisible ? Offset.zero : const Offset(0, 2),
          duration: buttonDuration,
          child: AnimatedOpacity(
            opacity: arrowVisible ? 1 : 0,
            duration: buttonDuration,
            child: Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.075),
                child: FloatingActionButton(
                  onPressed: () {
                    scrollToBottom();
                  },
                  child: const Icon(Icons.arrow_downward),
                )),
          ),
        ),
        body: Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              SizedBox(
                  height: size.height * 0.85,
                  child: Container(
                      padding: const EdgeInsets.all(10), child: returnWidget)),
              SizedBox(
                  width: size.width * 0.95,
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: const TextStyle(color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: IconButton(
                            onPressed: () {
                              uploadImage();
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
        ));
  }
}
