import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/chat.dart';
import 'package:library_project/Social/chat_screen.dart';
import 'package:library_project/Social/create_chat.dart';
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

  @override
  void initState() {
    super.initState();
    updateChats();
  }

  void updateChats() async {
    // rooms = tempChatList;
    // rooms.sort((a, b) => b.lastTime.compareTo(a.lastTime));
    rooms = await getChatList(widget.user);
    rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    setState(() {});
  }

  void goToNewChatScreen() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => CreateChatScreen(widget.user)));
    updateChats();
  }

  void openChat(String roomID) async {
    showBottombar = false;
    refreshBottombar.value = true;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(widget.user, roomID: roomID)));
    showBottombar = true;
    refreshBottombar.value = true;
    updateChats();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: displayAppBar(context, widget.user, "message"),
      backgroundColor: Colors.grey[400],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          goToNewChatScreen();
        },
        backgroundColor: Colors.green,
        label: const Text(
          "New Chat",
          style: TextStyle(fontSize: 20),
        ),
        icon: const Icon(
          Icons.add,
          size: 30,
        ),
        splashColor: Colors.blue,
      ),
      body: Column(
        children: [
          SizedBox(
            height: size.height * 0.01,
          ),
          Container(
            alignment: Alignment.center,
            width: size.width * .85,
            child: const SearchBar(),
          ),
          SizedBox(
            height: size.height * 0.01,
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (BuildContext context, int index) {
                    // return rooms[index].getCard(size, index, openChat);
                    return SizedBox();
                  }))
        ],
      ),
    );
  }
}
