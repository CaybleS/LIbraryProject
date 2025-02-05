import 'package:flutter/material.dart';
import 'package:library_project/Social/message_home.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/app_startup/auth.dart';
import 'package:library_project/database/database.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.curPage});

  final String curPage;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  void goToHome() {
    bottombarItemTapped(homepageIndex);
  }

  void goToProfile() {
    bottombarItemTapped(profileIndex);
  }

  void goToSettings() {
    bottombarItemTapped(settingsIndex);
  }

  void goToFriends() {
    bottombarItemTapped(friendsPageIndex);
  }

  void goToMessages() {
    if (widget.curPage != "chats") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const MessageHome()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      leading: MenuAnchor(
        menuChildren: [
          MenuItemButton(onPressed: () => {goToHome()}, child: const Icon(Icons.home)),
          MenuItemButton(onPressed: () => {goToProfile()}, child: const Icon(Icons.person)),
          MenuItemButton(onPressed: () => {goToSettings()}, child: const Icon(Icons.settings)),
          MenuItemButton(onPressed: () => {logout(context)}, child: const Icon(Icons.logout))
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
        GestureDetector(
          onTap: () {
            goToMessages();
          },
          child: Stack(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.message_rounded,
                  size: 30,
                ),
              ),
              StreamBuilder(
                stream: getChatList(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  int unreadMessages = snapshot.data!;

                  if (unreadMessages == 0) {
                    return const SizedBox(height: 22);
                  }
                  return Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadMessages.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
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

  Stream<int> getChatList() {
    if (userModel.value == null) return Stream.value(0);
    return dbReference.child('userChats/${userModel.value!.uid}').onValue.asyncMap((event) {
      final chatsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (chatsMap == null) return 0;
      int unreadMessages = 0;
      for (var entry in chatsMap.entries) {
        final unreadCount = entry.value['unreadCount'] as int;
        if (unreadCount > 0) unreadMessages += unreadCount;
      }
      return unreadMessages;
    });
  }
}
