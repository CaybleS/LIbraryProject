// TODO stuff which can be here. Just ideas to be clear, not requirements. Delete this eventually.
// logout, clear library, delete account, certain stats, specify am/pm or 24 hr in chats (its extra feature so not really good to have at this point),
// goodreads stuff, rate button which links to google play store, feedback form which links to an anonymous feedback google form or something TODO put feedback form for user testing.

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book/goodreads/goodreads_dialog.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/app_startup/auth.dart';
import 'package:library_project/app_startup/login.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/book_requests_model.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Settings extends StatefulWidget {
  final User user;

  @override
  State<Settings> createState() => _SettingsState();
  const Settings(this.user, {super.key});
}

class _SettingsState extends State<Settings> {
  // at least for the logout its definitely needed, idk about the others, it might not be needed but its meant to prevent spam pressing
  // a button to try to do something many times, for example if we are trying to logout and its not done and user clicks it again,
  // it shouldnt try do the logout stuff again. I'm just being safe since this page does some big things
  bool _pressedAButton = false;
  late final VoidCallback _userLibraryListener;
  late final VoidCallback _booksLentToMeListener;
  int numBooksLent = 0;

  @override
  void initState() {
    super.initState();
    // the userLibraryListener doesnt execute when we go to this page so this needs to be here
    numBooksLent = _getNumBooksLent();
    setState(() {});
    _userLibraryListener = () {
      numBooksLent = _getNumBooksLent();
      setState(() {});
    };
    _booksLentToMeListener = () {
      setState(() {});
    };
    pageDataUpdatedNotifier.addListener(_userLibraryListener);
    pageDataUpdatedNotifier.addListener(_booksLentToMeListener);
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_userLibraryListener);
    pageDataUpdatedNotifier.removeListener(_booksLentToMeListener);
    super.dispose();
  }

  int _getNumBooksLent() {
    int totalBooksLent = 0;
    for (int i = 0; i < userLibrary.length; i++) {
      if (userLibrary[i].lentDbKey != null) {
        totalBooksLent++;
      }
    }
    return totalBooksLent;
  }

  Future<bool> _showTwoConfirmActionDialogs(String msg1, String msg2) async {
    bool shouldRemove = await SharedWidgets.displayConfirmActionDialog(context, msg1);
    if (!shouldRemove) {
      return false;
    }
    await Future.delayed(const Duration(milliseconds: 300)); // arbitrary time
    if (mounted) {
      bool shouldRemove2 = await SharedWidgets.displayConfirmActionDialog(context, msg2);
      if (!shouldRemove2) {
        return false;
      }
    }
    return true;
  }

  Future<void> _removeAllBooksButtonClicked() async {
    if (userLibrary.isEmpty) {
      SharedWidgets.displayErrorDialog(context, "There is nothing to remove.");
      return;
    }
    bool hasBookLentOut = false;
    for (int i = 0; i < userLibrary.length; i++) {
      if (userLibrary[i].lentDbKey != null) {
        hasBookLentOut = true;
        break;
      }
    }
    if (hasBookLentOut) {
      SharedWidgets.displayErrorDialog(context, "Please return your lent books before clearing your library.");
      return;
    }
    String confirmMsgToShow1 = "Are you sure you want to do this? This will remove all of your books.";
    String confirmMsgToShow2 = "Are you absolutely certain you want to remove all ${userLibrary.length} books?";
    bool shouldProceed = await _showTwoConfirmActionDialogs(confirmMsgToShow1, confirmMsgToShow2);
    if (!shouldProceed) {
      return;
    }
    for (int i = 0; i < userLibrary.length; i++) {
      await userLibrary[i].remove(widget.user.uid);
    }
    if (mounted) {
      SharedWidgets.displayPositiveFeedbackDialog(context, "Removed All Books");
    }
  }

  Future<void> _deleteAccountButtonClicked() async {
    bool hasBookLentOut = false;
    for (int i = 0; i < userLibrary.length; i++) {
      if (userLibrary[i].lentDbKey != null) {
        hasBookLentOut = true;
        break;
      }
    }
    // the order is delibrate because if you have books lent to you and books lent out, dealing with the books lent to you is harder; it requires
    // contacting other people since you can't unlend books to yourself. Dealing with lent out books is easy so warning them of that is less important.
    if (booksLentToMe.isNotEmpty) {
      if (mounted) {
        SharedWidgets.displayErrorDialog(context, "You have books lent to you. You cannot delete your account when you have books lent to you.");
        return;
      }
    }
    if (hasBookLentOut) {
      if (mounted) {
        SharedWidgets.displayErrorDialog(context, "You have books lent out. You cannot delete your account when you have books lent out.");
        return;
      }
    }
    // after we check if they can actually delete the account, now we show 2 confirmation dialogs
    String confirmMsgToShow1 = "Are you sure you want to do this? This will delete all account info.";
    String confirmMsgToShow2 = "This cannot be undone. Are you sure you wish to delete everything?";
    bool shouldProceed = await _showTwoConfirmActionDialogs(confirmMsgToShow1, confirmMsgToShow2);
    if (!shouldProceed) {
      return;
    }
    if (mounted) {
      // to execute delete() the user needs to be recently authenticated so we just do this before deleting their database stuff
      // TODO improve error handling for this
      bool reauthenticationWorked = await reauthenticateUser(context, widget.user);
      if (!reauthenticationWorked && mounted) {
        SharedWidgets.displayErrorDialog(context, "There was an error with reauthentication. Please try again");
        return;
      }
    }
    // 1.) removing all book requests involving this user
    await removeAllBookRequestsInvolvingThisUser(widget.user.uid, widget.user.uid, deletingThisAccount: true);
    // 2.) removing users books
    DatabaseReference usersBooks = dbReference.child('books/${widget.user.uid}');
    await removeRef(usersBooks);
    // note that "lent to me" books dont need to removed since we checked to make sure they dont have any books lent to them before letting them delete account.
    // (assumming everything works correctly. I wonder if its actually optimal to try to remove them anyways just to be safe. No right?)
    // 3.) removing user's username
    DatabaseReference usersUsername = dbReference.child('usernames/${userIdToUserModel[widget.user.uid]!.username}');
    await removeRef(usersUsername);
    // 4.) removing user's user properties
    DatabaseReference usersProperties = dbReference.child('users/${widget.user.uid}');
    await removeRef(usersProperties);
    // TODO below stuff needs to be done
    // remove the friends
    // and friend requests
    // and chats
    // and userTokens (for notification stuff, its easy but its not implemented completely yet so)
    // and scheduledNotifications stuff (shouldnt exist since no books are lent assuming we even have time to implement it)
    cancelDatabaseSubscriptions(); // honestly no clue when this should be called but it should be eventually probably at the very end right?
    // TODO someone else pls check this order cuz idk delete this comment if u think its good
    userModel.value = null;
    for (var data in widget.user.providerData) {
      if (data.providerId == "google.com") {
        await signOutGoogle(); // dont know if this is even needed or if it works
      }
    }
    await widget.user.delete();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacement(MaterialPageRoute(builder: (context) => const LoginPage()));
    }
    if (mounted) {
      SharedWidgets.displayPositiveFeedbackDialog(context, "Account Deleted");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 25, 10, 25),
        child: Column(
          children: [
            const Row(), // idk how else to make the columns children be in the center of the screen if you know how just do it cuz this cant be optimal ..
            IntrinsicWidth( // making all 4 buttons the size of the biggest one, this and CrossAxisAlignment.stretch achieve this
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_pressedAButton) {
                          return;
                        }
                        _pressedAButton = true;
                        await displayGoodreadsDialog(context, widget.user);
                        _pressedAButton = false;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.skyBlue,
                        padding: const EdgeInsets.all(8),
                      ),
                      child: const Text(
                        "Import/Export Goodreads books",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_pressedAButton) {
                          return;
                        }
                        _pressedAButton = true;
                        await _removeAllBooksButtonClicked();
                        _pressedAButton = false;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 165, 0),
                        padding: const EdgeInsets.all(8),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Remove all books",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_pressedAButton) {
                          return;
                        }
                        _pressedAButton = true;
                        await logout(context);
                        _pressedAButton = false;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 147, 164, 180),
                        padding: const EdgeInsets.all(8),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_pressedAButton) {
                          return;
                        }
                        _pressedAButton = true;
                        await _deleteAccountButtonClicked();
                        _pressedAButton = false;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 72, 72),
                        padding: const EdgeInsets.all(8),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "Delete account",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ),              
                ],
              ),
            ),
            const Spacer(), // I want the stats on the bottom and this is just the perfect use case for Spacer thats crazy
            const Text(
              "Your Stats",
              style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
            ),
            Text(
              "Added books: ${userLibrary.length}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            Text(
              "Books lent out: $numBooksLent",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            Text(
              "Books lent to you: ${booksLentToMe.length}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> displayReenterPasswordDialog(BuildContext context, User user) async {
  String? passwordInput = await showDialog(
    context: context,
    builder: (context) => DisplayReenterPasswordDialog(user),
  );
  return passwordInput ?? "";
}

class DisplayReenterPasswordDialog extends StatefulWidget {
  final User user;
  const DisplayReenterPasswordDialog(this.user, {super.key});

  @override
  State<DisplayReenterPasswordDialog> createState() => _DisplayReenterPasswordDialogState();
}

class _DisplayReenterPasswordDialogState extends State<DisplayReenterPasswordDialog> {
  bool _noPasswordInput = false;
  final _inputPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inputPasswordController.addListener(() {
      if (_noPasswordInput && _inputPasswordController.text.isNotEmpty) {
        setState(() {
          _noPasswordInput = false;
        });
    }});
  }

  @override
  void dispose() {
    _inputPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(25)), // dialog has a border, Material widget doesnt
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.user.email!),
              TextField(
                controller: _inputPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  fillColor: Colors.white,
                  filled: true,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                  errorText: _noPasswordInput ? "Please enter a password" : null,
                  suffixIcon: IconButton(
                  onPressed: () {
                    _inputPasswordController.clear();
                  },
                  icon: const Icon(Icons.clear),
                  ),
                ),
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _inputPasswordController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.skyBlue,
                  padding: const EdgeInsets.all(8),
                ),
                child: const Text(
                  "Reauthenticate",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
