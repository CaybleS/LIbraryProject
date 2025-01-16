import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import '../app_startup/auth.dart';
import '../Social/message_home.dart';

PreferredSizeWidget displayAppBar(BuildContext context, User user, String curPage) {
  void goToHome() {
    onItemTapped(homepageIndex);
  }

  void goToProfile() {
    onItemTapped(profileIndex);
  }

  void goToSettings() {
    onItemTapped(settingsIndex);
  }

  void goToFriends() {
    onItemTapped(friendsPageIndex);
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
