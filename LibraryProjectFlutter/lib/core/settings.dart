/*TODO (remove these comments when done) things to put in settings. Some of these are just ideas, some of these must exist.
1.) ability to disable or enable every single notification, independently
(this should probably be a nested listview which can be hidden which is common design for settings it seems) (at least thats my first/only thought for ui of it)
2.) ability to clear entire user library (prob should exist at this point now that goodreads importing exists imo)
3.) ability to not show real name (the name pulled from google) (maybe they should be able to edit this name also but idk)
(could this extend to only showing your real name to certain people or is that extra?)
4.) 🚨🚨delete account🚨🚨 
(how would this affect chats with this user? Most things just get deleted but would their messages in the chats remain, and would their name in
the chats remain, imo their name should change to <Deleted User> or something but msg should remain. No idea if thats feasible tho or how to do it)
5.) Logout
6.) certain stats such as num books lent out, num books lent to me, etc.
7.) letting users specify AM/PM or 24 hour time in chats
8.) maybe a "dont ask again", independent for every SharedWidgets.displayConfirmActionDialog? After thinking on it, dont like the idea, but its an idea. Better for web.
9.) maybe this page could have goodreads import or will it be on add books page? idk probably latter right?
(it could also have export too, issue being it would only export the books which have isbns in google books/open library apis, which is fine I guess, is it worth idk)
10.) idk
// TODO stuff which can be here. Delete this eventually.
// logout, clear library, delete account, certain stats, specify am/pm or 24 hr in chats, goodreads stuff, rate button which links to google play store,
// feedback form which links to an anonymous feedback google form or something



*/


import 'package:flutter/material.dart';
import 'package:library_project/add_book/goodreads/goodreads_dialog.dart';
import 'package:library_project/app_startup/auth.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'appbar.dart';
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
  // it shouldnt try do the logout stuff again. I'm just being safe since this page does some big things TODO appbar needs that also since spam pressing logout will cause error
  bool _pressedAButton = false;
  late final VoidCallback _userLibraryListener;
  late final VoidCallback _booksLentToMeListener;
  int numBooksLent = 0;

  @override
  void initState() {
    super.initState();
    _userLibraryListener = () {
      if (refreshNotifier.value == settingsIndex) {
        numBooksLent = 0;
        for (int i = 0; i < userLibrary.length; i++) {
          if (userLibrary[i].lentDbKey != null) {
            numBooksLent++;
          }
        }
        setState(() {});
      }
    };
    _booksLentToMeListener = () {
      if (refreshNotifier.value == settingsIndex) {
        setState(() {});
      }
    };
    refreshNotifier.addListener(_userLibraryListener);
    refreshNotifier.addListener(_booksLentToMeListener);
  }

  @override
  void dispose() {
    refreshNotifier.removeListener(_userLibraryListener);
    refreshNotifier.removeListener(_booksLentToMeListener);
    super.dispose();
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
    // TODO ensure that the removing here also deals with scheduled notifications since currently it doesn't
    for (int i = 0; i < userLibrary.length; i++) {
      await userLibrary[i].remove(widget.user.uid);
    }
    if (mounted) {
      SharedWidgets.displayPositiveFeedbackDialog(context, "Removed All Books");
    }
  }
  
  // TODO this. Honestly seems hard to implement.
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
      SharedWidgets.displayPositiveFeedbackDialog(context, "This does not work yet");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(curPage: "settings"),
      backgroundColor: Colors.grey[400],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 25),
        child: Column(
          children: [
            const Text(
              "Settings",
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            ElevatedButton(
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
            ElevatedButton(
              onPressed: () {
                if (_pressedAButton) {
                  return;
                }
                _pressedAButton = true;
                logout(context);
                _pressedAButton = false;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.skyBlue,
                padding: const EdgeInsets.all(8),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                      backgroundColor: AppColor.skyBlue,
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
                      backgroundColor: AppColor.skyBlue,
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
            const Spacer(), // I want the stats on the bottom and this is just the perfect use case for Spacer thats crazy
            const Text(
              "Your Stats",
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            Text(
              "Added books: ${userLibrary.length}",
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              "Books lent out: $numBooksLent",
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              "Books lent to you: ${booksLentToMe.length}",
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
