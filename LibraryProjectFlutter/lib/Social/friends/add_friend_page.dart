import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/friends/friend_scanner_driver.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../database/database.dart';

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

  late FriendScannerDriver _qrScanInstance;
  bool _displayProgressIndicator =
      false; // used to display CircularProgressIndicator whenever necessary

  @override
  void initState() {
    super.initState();
    _qrScanInstance = FriendScannerDriver();
  }

  void onSubmit(BuildContext context) async {
    String txt = controller.text;
    String id = await findUser(txt);
    if (id != '' && id != widget.user.uid) {
      if (!friends.any((friend) => friend.uid == id)) {
        sendFriendRequest(widget.user, id);
        SharedWidgets.displayPositiveFeedbackDialog(
            context, 'Friend Request Sent!');
        Navigator.pop(context);
      } else {
        setState(() {
          _msg = "You are already friends with this user";
          showErrorTxt = true;
        });
      }
    } else {
      setState(() {
        _msg = "User not found";
        showErrorTxt = true;
      });
    }
  }

  Future<void> _scanButtonClicked() async {
    if (_displayProgressIndicator) {
      return;
    }
    controller.clear();
    setState(() {
      _displayProgressIndicator = true;
    });
    String? scannedID = await _qrScanInstance.runScanner(context);
    // after scanning, the scanner pops here and a search by isbn occurs. However I want to clear the last search values before this search
    // occurs, so that for example the search info helper text gets cleared. It's convoluted logic but it works.
    // if (scannedID != null) {
    //   _bookSearchInstance.resetLastSearchValues();
    //   setState(() {});
    // }
    if (mounted && scannedID != null) {
      // await _qrScanInstance.scannerSearchByIsbn(context, scannedID);
      if (await userExists(scannedID)) {
        // var contain = friends.where((element) => element.friendId == scannedID);
        var contain = friends.where((element) => element.uid == scannedID);
        if (contain.isEmpty) {
          sendFriendRequest(widget.user, scannedID);
          SharedWidgets.displayPositiveFeedbackDialog(
              context, 'Friend Request Sent!');
        }
      }
    }
    // this is commented out just because I decided not to include it, but its arguably good to have so I'm not deleting its implementation
    // if (scannedISBN != null) {
    //   // putting the scanned ISBN into the search query, for better user experience, done after the search rather than before
    //   _searchQueryController.text = scannedISBN;
    // }
    setState(() {
      _displayProgressIndicator = false;
    });
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
        Text("ID: ${widget.user.uid}",
            style: const TextStyle(fontSize: 20, color: Colors.black)),
        QrImageView(
          data: widget.user.uid,
          size: 300,
        )
      ],
    );
  }

  Widget addFriendDisplay() {
    return Column(children: [
      const Text(
        "Friend's ID or Email:",
        style: TextStyle(fontSize: 20),
      ),
      const SizedBox(
        height: 10,
      ),
      SharedWidgets.displayTextField(
          'ID or email', controller, showErrorTxt, _msg),
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
              style: TextStyle(fontSize: 16, color: Colors.black))),
      const SizedBox(
        height: 10,
      ),
      ElevatedButton(
          onPressed: () {
            _scanButtonClicked();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
          child: const Text('Scan Code',
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
                _selected == "enter" ? addFriendDisplay() : friendCodeDisplay(),
                _displayProgressIndicator
                    ? SharedWidgets.displayCircularProgressIndicator()
                    : Container()
              ],
            )));
  }
}
