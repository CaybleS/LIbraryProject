import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'friends_page.dart';
import 'profile.dart';
import 'settings.dart';

PreferredSizeWidget displayAppBar(
    BuildContext context, User user, String curPage) {
  void goToHome() {
    if (curPage != "home") {
      Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst); // as long as we pushReplacement to the homepage initially, this will always take us there
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
            child: const Icon(Icons.settings))
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
          onPressed: () {goToFriends();}, icon: const Icon(Icons.person_add_alt_1, size: 30)),
      const SizedBox(
        width: 10,
      )
    ],
  );
}
