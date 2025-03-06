import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:library_project/Social/friends/friend_scanner_driver.dart';
import 'package:library_project/Social/profile/profile.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/global_variables.dart';
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
  late final VoidCallback _friendpageListener;

  late FriendScannerDriver _qrScanInstance;
  bool _displayProgressIndicator =
      false; // used to display CircularProgressIndicator whenever necessary

  @override
  void initState() {
    super.initState();
    _friendpageListener = () {
      if (selectedIndex == friendsPageIndex) {
        setState(() {});
        ();
      }
    };
    pageDataUpdatedNotifier.addListener(_friendpageListener);
    _qrScanInstance = FriendScannerDriver();
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_friendpageListener);
    super.dispose();
  }

  void onSubmit(BuildContext context) async {
    String txt = controller.text;
    String id = await findUser(txt);
    bool requestToMe = requestIDs.value.contains(
        id); // if there is already a request sent from this user, add as friend
    if (requestToMe) {
      await addFriend(id, widget.user.uid);
      SharedWidgets.displayPositiveFeedbackDialog(context, "Friend Added");
    } else {
      if (id != widget.user.uid) {
        if (id != '') {
          if (!friendIDs.contains(id)) {
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
      } else {
        setState(() {
          _msg = "Cannot send friend request to yourself";
          showErrorTxt = true;
        });
      }
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
        var contain = friendIDs.where((element) => element == scannedID);
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
      AppColor.skyBlue,
    ];

    switch (_selected) {
      case "enter":
        buttonColor[0] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case "info":
        buttonColor[1] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case "sent":
        buttonColor[2] = const Color.fromARGB(255, 117, 117, 117);
        break;
      default:
    }

    return SizedBox(
        height: 50,
        child: ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  const SizedBox(
                    width: 20,
                  ),
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
                  const SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor[2],
                        padding: const EdgeInsets.all(8)),
                    onPressed: () {
                      if (_selected == "sent") {
                        return;
                      } else {
                        setState(() {
                          _selected = "sent";
                        });
                      }
                    },
                    child: const Text(
                      "View Sent Requests",
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ),
                ],
              )
            ]));
  }

  Widget friendCodeDisplay() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Text("ID: ${widget.user.uid}",
              style: const TextStyle(fontSize: 20, color: Colors.black)),
          IconButton(onPressed: () {Clipboard.setData(ClipboardData(text: widget.user.uid));}, icon: const Icon(Icons.copy))
        ]),
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
        "Friend's ID or Username:",
        style: TextStyle(fontSize: 20),
      ),
      const SizedBox(
        height: 10,
      ),
      SharedWidgets.displayTextField(
          'ID or username', controller, showErrorTxt, _msg),
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
              style: TextStyle(fontSize: 16, color: Colors.black))),
    ]);
  }

  Widget displaySentRequests() {
    return sentFriendRequests.isNotEmpty
        ? Expanded(
            child: ListView.builder(
                itemCount: sentFriendRequests.length,
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Profile(
                                    widget.user, sentFriendRequests[index])));
                      },
                      child: SizedBox(
                          height: 100,
                          child: Card(
                              margin: const EdgeInsets.all(5),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: ClipOval(
                                            child: SizedBox(
                                                width: 50,
                                                child: userIdToUserModel[
                                                                sentFriendRequests[
                                                                    index]]
                                                            ?.photoUrl !=
                                                        null
                                                    ? Image.network(
                                                        userIdToUserModel[
                                                                sentFriendRequests[
                                                                    index]]!
                                                            .photoUrl!)
                                                    : Image.asset(
                                                        'assets/profile_pic.jpg')))),
                                    Expanded(
                                        child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Column(children: [
                                        const SizedBox(
                                          height: 22.5,
                                        ),
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Text(
                                            userIdToUserModel[
                                                    sentFriendRequests[index]]!
                                                .name,
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Text(
                                            userIdToUserModel[
                                                    sentFriendRequests[index]]!
                                                .username,
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14),
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      ]),
                                    )),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 150),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: ElevatedButton(
                                            onPressed: () async {
                                              await removeFriendRequest(
                                                  widget.user.uid,
                                                  sentFriendRequests[index]);
                                              setState(() {});
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            child: const Text('Unsend Request',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black))),
                                      ),
                                    )
                                  ]))));
                }))
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.appbarColor,
        ),
        body: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                displayNavigationButtons(),
                const SizedBox(
                  height: 10,
                ),
                _selected == "enter"
                    ? addFriendDisplay()
                    : (_selected == "info"
                        ? friendCodeDisplay()
                        : displaySentRequests()),
                _displayProgressIndicator
                    ? SharedWidgets.displayCircularProgressIndicator()
                    : const SizedBox.shrink()
              ],
            )));
  }
}
