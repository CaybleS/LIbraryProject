import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  bool showErrorTxt = false;
  String _selected = "enter";

  void onSubmit(BuildContext context) async {
    String txt = controller.text;
    String id = await findUser(txt);
    if (id != '') {
      // debugPrint('--------------------------------------------------');
      // debugPrint('--------------------------------------------------');
      sendFriendRequest(widget.user, id);
      SharedWidgets.displayPositiveFeedbackDialog(
          context, 'Friend Request Sent!');
      Navigator.pop(context);
    } else {
      setState(() {
        _msg = "User not found";
        showErrorTxt = true;
      });
    }
  }

  Widget displayNavigationButtons() {
    List<Color> buttonColor = [
      AppColor.skyBlue,
      AppColor.skyBlue,
    ];

    switch (_selected) {
      case "enter":
        buttonColor[0] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case "info":
        buttonColor[1] = const Color.fromARGB(255, 117, 117, 117);
        break;
      default:
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor[0],
              padding: const EdgeInsets.all(8)),
          onPressed: () {
            if (_selected == "enter") {
              return;
            } else {
              setState(() {
                _selected = "enter";
              });
            }
          },
          child: const Text(
            "Add Friend",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor[1],
              padding: const EdgeInsets.all(8)),
          onPressed: () {
            if (_selected == "info") {
              return;
            } else {
              setState(() {
                _selected = "info";
              });
            }
          },
          child: const Text(
            "Your Friend Code",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
      ],
    );
  }

  Widget friendCodeDisplay() {
    return Column(
      children: [
        Text("ID: ${widget.user.uid}", style: const TextStyle(fontSize: 20, color: Colors.black)),
        QrImageView(data: widget.user.uid, size: 300,)
      ],
    );
  }

  Widget addFriendDisplay() {
    return Column(children: [
      const Text(
        "Friend's ID, Email, or Username:",
        style: TextStyle(fontSize: 20),
      ),
      const SizedBox(
        height: 10,
      ),
      SharedWidgets.displayTextField(
          'ID, email, or name', controller, showErrorTxt, _msg),
      const SizedBox(
        height: 10,
      ),
      ElevatedButton(
          onPressed: () {
            onSubmit(context);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
          child: const Text('Send Request',
              style: TextStyle(fontSize: 16, color: Colors.black)))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
        ),
        backgroundColor: Colors.grey[400],
        body: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                displayNavigationButtons(),
                const SizedBox(
                  height: 10,
                ),
                _selected == "enter" ? addFriendDisplay() : friendCodeDisplay()
              ],
            )));
  }
}
