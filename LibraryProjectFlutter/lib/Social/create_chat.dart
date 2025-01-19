import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/Social/friends_page.dart';
import 'package:library_project/Social/chat_screen.dart';

class CreateChatScreen extends StatefulWidget {
  final User user;

  const CreateChatScreen(this.user, {super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  late TextEditingController controller;
  final TextEditingController groupNameController = TextEditingController();
  List<Friend> friendsVisible = [];
  List<Friend> inChat = [];

  @override
  void initState() {
    super.initState();

    getList();
    getAppFriends();

  }

  getAppFriends() async {
    final friends =await getFriends(widget.user);
    print(friends);
  }

  void getList() async {
    friendsVisible = friends;//await getFriends(widget.user);
    setState(() {});
  }

  String displayString(Friend friend) {
    String text = friend.friendId;
    if (friend.name != null) {
      text = friend.name!;
      if (friend.email != null) {
        text += " - ${friend.email}";
      }
    } else if (friend.email != null) {
      text = friend.email!;
    }
    return text;
  }

  void addFriend(Friend friend) {
    inChat.add(friend);
    friendsVisible.remove(friend);

    controller.clear;

    setState(() {});
  }

  void removeFriend(int index) {
    friendsVisible.add(inChat[index]);
    inChat.remove(inChat[index]);

    setState(() {});
  }

  void createChat() {
    if (inChat.length == 1) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ChatScreen(
                    widget.user,
                    inChat: inChat,
                  )));
    } else if (inChat.length > 1 && groupNameController.text.isNotEmpty) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ChatScreen(
                    widget.user,
                    inChat: inChat,
                    name: groupNameController.text,
                  )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          createChat();
        },
        backgroundColor: inChat.isNotEmpty ? Colors.green : Colors.grey,
        label: const Text(
          "Create Chat",
          style: TextStyle(fontSize: 20),
        ),
        icon: const Icon(
          Icons.add,
          size: 30,
        ),
        splashColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[400],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Autocomplete<Friend>(
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                controller = textEditingController;
                return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: (String value) => onFieldSubmitted,
                    decoration: InputDecoration(
                        hintText: 'Add Friend',
                        hintStyle: const TextStyle(color: Colors.grey),
                        suffixIcon: InkWell(onTap: controller.clear, child: const Icon(Icons.close)),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))));
              },
              displayStringForOption: (option) => displayString(option),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<Friend>.empty();
                } else {
                  return friendsVisible.where((Friend friend) {
                    return displayString(friend).toLowerCase().contains(controller.text.toLowerCase());
                  });
                }
              },
              onSelected: (option) {
                debugPrint("Selected: ${option.friendId}");
                controller.text = '';
                addFriend(option);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: inChat.length,
                itemBuilder: (BuildContext context, int index) {
                  String nameTxt = "";
                  String emailTxt = "";

                  if (inChat[index].name != null) {
                    nameTxt = inChat[index].name!;
                    if (inChat[index].email != null) {
                      emailTxt = inChat[index].email!;
                    } else {
                      emailTxt = inChat[index].friendId;
                    }
                  } else {
                    if (inChat[index].email != null) {
                      nameTxt = inChat[index].email!;
                      emailTxt = inChat[index].friendId;
                    } else {
                      nameTxt = inChat[index].friendId;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: size.width * 0.03,
                        ),
                        SizedBox(
                            width: size.width * 0.6,
                            height: size.height * 0.095,
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: size.height * 0.02,
                                    ),
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          nameTxt,
                                          style: const TextStyle(color: Colors.black, fontSize: 20),
                                          softWrap: true,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          emailTxt,
                                          style: const TextStyle(color: Colors.black, fontSize: 16),
                                          softWrap: true,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                  ],
                                ))),
                        SizedBox(
                          height: size.height * 0.095,
                          width: size.width * 0.3,
                          child: Column(
                            children: [
                              SizedBox(
                                height: size.height * 0.035,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () {
                                    removeFriend(index);
                                  },
                                  child: const Icon(Icons.close),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: size.width * 0.9,
              child: Visibility(
                visible: inChat.length > 1,
                child: TextField(
                  controller: groupNameController,
                  decoration: InputDecoration(
                      hintText: 'Group Name',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
