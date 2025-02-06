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
9.) maybe this page could have goodreads import or will it be on add books page? idk probably latter right? only issue atm is covers for that
(it could also have export too, issue being it would only export the books which have isbns in google books/open library apis, which is fine I guess, is it worth idk)
10.) idk



*/


import 'package:flutter/material.dart';
import 'package:library_project/add_book/goodreads_import.dart';
import 'appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Settings extends StatefulWidget {
  final User user;

  @override
  State<Settings> createState() => _SettingsState();
  const Settings(this.user, {super.key});
}

class _SettingsState extends State<Settings> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(curPage: "settings"),
      backgroundColor: Colors.grey[400],
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // maybe this could be on add book page instead of here but i dunno where to put it. Is it intuitive to have it here, or there?
            ElevatedButton(onPressed: () async { await tryGoodreadsImport(widget.user, context);}, child: const Text("Goodreads import from csv:")),
          ],
        ),
      ),
    );
  }
}
