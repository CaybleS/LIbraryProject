import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';

class AddFriendPage extends StatefulWidget {
  final User user;
  const AddFriendPage(this.user, {super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final controller = TextEditingController();
  String _msg = "";

  void onSubmit(BuildContext context) async {
    String id = controller.text;
    if (await userExists(id)) {
      print('--------------------------------------------------');
      print('--------------------------------------------------');
      // TODO: get friends id
      // sendFriendRequest(widget.user, id);
      // Navigator.pop(context);
    } else {
      setState(() {
        _msg = "User not found";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
        ),
        backgroundColor: Colors.grey[400],
        body: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  "Friend's Email:",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                      fillColor: Colors.white, filled: true),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  _msg,
                  style: const TextStyle(fontSize: 25, color: Colors.red),
                ),
                const SizedBox(
                  height: 5,
                ),
                ElevatedButton(
                    onPressed: () {
                      onSubmit(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(129, 199, 132, 1)),
                    child: const Text('Send Request',
                        style: TextStyle(fontSize: 16, color: Colors.black)))
              ],
            )));
  }
}