import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/friends_page.dart';
import 'package:library_project/Social/message_home.dart';
import 'homepage.dart';
import 'Social/profile.dart';
import 'settings.dart';
import 'Firebase/auth.dart';

PreferredSizeWidget displayAppBar(
    BuildContext context, User user, String curPage) {
  void goToHome() {
    if (curPage != "home") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomePage(user)));
    }
  }

  void goToProfile() {
    if (curPage != "profile") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Profile(user)));
    }
  }

  void goToSettings() {
    if (curPage != "settings") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Settings(user)));
    }
  }

  void goToFriends() {
    if (curPage != "friends") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => FriendsPage(user)));
    }
  }

  void goToMessages() {
    if (curPage != "message") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => MessageHome(user)));
    }
  }

  return AppBar(
    backgroundColor: Colors.blue,
    leading: MenuAnchor(
      menuChildren: [
        MenuItemButton(
            onPressed: () => {goToHome()}, child: const Icon(Icons.home)),
        MenuItemButton(
            onPressed: () => {goToProfile()}, child: const Icon(Icons.person)),
        MenuItemButton(
            onPressed: () => {goToSettings()},
            child: const Icon(Icons.settings)),
        MenuItemButton(
            onPressed: () => {logout(context)}, child: const Icon(Icons.logout))
      ],
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(
            Icons.menu,
            size: 30,
          ),
        );
      },
    ),
    actions: [
      IconButton(
          onPressed: () {
            goToMessages();
          },
          icon: const Icon(Icons.message_rounded, size: 30)),
      const SizedBox(
        width: 10,
      ),
      IconButton(
          onPressed: () {
            goToFriends();
          },
          icon: const Icon(Icons.person_add_alt_1, size: 30)),
      const SizedBox(
        width: 10,
      )
    ],
  );
}
