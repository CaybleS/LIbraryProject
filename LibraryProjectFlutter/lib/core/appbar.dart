import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/app_startup/auth.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/core/settings.dart';
import 'package:shelfswap/ui/colors.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final User user;
  final String title;
  const CustomAppBar(this.user, {this.title = "", super.key});

  @override
  // this is the default appbar "toolbar" height I believe, kToolbarHeight is usually 56px but it seems it can vary
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _pressedAButton = false; // meant to prevent spam logout presses from executing it multiple times
  
  void goToHome() {
    bottombarItemTapped(homepageIndex);
  }

  void goToProfile() {
    bottombarItemTapped(profileIndex);
  }

  void goToSettings(BuildContext context) {
    // dont need to check if current page is settings here since settings isnt a "root" page so it doesnt use the custom appbar, 
    // so you cant get to settings from settings anyways
    Navigator.push(context, MaterialPageRoute(builder: (context) => Settings(widget.user)));
  }

  void goToFriends() {
    bottombarItemTapped(friendsPageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.appbarColor,
      leading: MenuAnchor(
        menuChildren: [
          MenuItemButton(onPressed: () => {
            goToHome()
          }, child: const Icon(Icons.home)),
          const Divider(),
          MenuItemButton(onPressed: () => {
            goToSettings(context)
          }, child: const Icon(Icons.settings)),
          const Divider(),
          MenuItemButton(
            onPressed: () async {
              if (_pressedAButton) {
                return;
              }
              _pressedAButton = true;
              await logout(context);
              _pressedAButton = false;
            },
            child: const Icon(Icons.logout),
          ),
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
      title: Text(widget.title),
      centerTitle: true,
    );
  }
}
