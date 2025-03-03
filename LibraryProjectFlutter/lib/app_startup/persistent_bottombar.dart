import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:library_project/Social/chats/message_home.dart';
import 'package:library_project/Social/friends/friends_page.dart';
import 'package:library_project/add_book/add_book_homepage.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/core/homepage.dart';
import 'package:library_project/Social/profile/profile.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/ui/colors.dart';

class PersistentBottomBar extends StatefulWidget {
  final User user;
  const PersistentBottomBar(this.user, {super.key});

  @override
  State<PersistentBottomBar> createState() => _PersistentBottomBarState();
}

class _PersistentBottomBarState extends State<PersistentBottomBar> {
  final List<Widget> _pagesList = List.filled(5, const SizedBox.shrink());
  late final VoidCallback _refreshBottombarListener;

  @override
  void initState() {
    super.initState();
    setupDatabaseSubscriptions(widget.user);
    _pagesList[homepageIndex] = HomePage(widget.user);
    _pagesList[addBookPageIndex] = AddBookHomepage(widget.user);
    _pagesList[friendsPageIndex] = FriendsPage(widget.user);
    _pagesList[messagesIndex] = MessageHome(widget.user);
    _pagesList[profileIndex] = Profile(widget.user, widget.user.uid);
    _refreshBottombarListener = () {
      if (refreshBottombar.value == true) {
        setState(() {});
        refreshBottombar.value = false;
      }
    };
    refreshBottombar.addListener(_refreshBottombarListener);
  }

  @override
  void dispose() {
    // Note that some things are done in strange ways since many of these variables are in appwide_setup and are thus not tied to the
    // lifecycle of this bottombar, so instead of removing them I basically just reset them here.
    for (GlobalKey<NavigatorState> key in navigatorKeys) {
      key.currentState?.dispose();
    }
    cancelDatabaseSubscriptions();
    refreshBottombar.removeListener(_refreshBottombarListener);
    resetBottombarValues();
    super.dispose();
  }

  // each bottombar tab has its own offstage (which loads the page into memory), and each of the 5 pages
  // has its own navigation stack, identified by its GlobalKey. Note that push and pop work as normal on these
  // since push and pop just use the most recent parent navigator.
  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: selectedIndex != index,
      child: Navigator(
        key: navigatorKeys[index],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(builder: (context) {
            return _pagesList[index];
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        // this allows the android back button to work properly
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          bool shouldPop =
              !await navigatorKeys[selectedIndex].currentState!.maybePop();
          if (shouldPop) {
            // ensuring the app closes, since in this case this only runs to close the app I believe
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: Stack(
            children: List.generate(
              navigatorKeys.length,
              (index) => _buildOffstageNavigator(index),
            ),
          ),
          bottomNavigationBar: (showBottombar)
              ? BottomNavigationBar(
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: "Homepage",
                    ),
                    BottomNavigationBarItem(
                      // can be search, my_library_add, add, add_circle, bookmark_add. I just think the search is intuitive enough, others dont look amazing
                      icon: Icon(Icons.search),
                      label: "Add book",
                    ),
                    BottomNavigationBarItem(
                      icon: FriendsIcon(),
                      label: "Friends",
                    ),
                    BottomNavigationBarItem(
                      icon: DynamicMessagesIcon(),
                      label: "Messages",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.account_circle_rounded),
                      label: "Profile",
                    ),
                  ],
                  currentIndex: selectedIndex,
                  selectedItemColor: AppColor.appbarColor,
                  unselectedItemColor: Colors.grey,
                  backgroundColor: Colors.white,
                  onTap: bottombarItemTapped,
                )
              : const SizedBox.shrink(),
        ));
  }
}

class FriendsIcon extends StatefulWidget {
  const FriendsIcon({super.key});

  @override
  State<FriendsIcon> createState() => _FriendsIconState();
}

class _FriendsIconState extends State<FriendsIcon> {
  late final VoidCallback _requestListener;
  int requests = 0;

  @override
  void initState() {
    super.initState();
    _requestListener = () {
      if (requests != requestIDs.value.length) {
        requests = requestIDs.value.length;
        setState(() {});
      }
    };
    requestIDs.addListener(_requestListener);
  }

  @override
  void dispose() {
    requestIDs.removeListener(_requestListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return requests == 0 ? const Icon(Icons.people_alt_rounded) : Badge.count(
      count: requests,
      child: const Icon(Icons.people_alt_rounded),
    );
  }
}

class DynamicMessagesIcon extends StatefulWidget {
  const DynamicMessagesIcon({super.key});

  @override
  State<DynamicMessagesIcon> createState() => _DynamicMessagesIconState();
}

class _DynamicMessagesIconState extends State<DynamicMessagesIcon> {
  late Stream<int> _chatListStream;
  late final VoidCallback _userHasBeenSetListener;

  @override
  void initState() {
    super.initState();
    _userHasBeenSetListener = () {
      if (userModel.value != null) {
        // user definitely exists so we get the chat list now
        _chatListStream = _getChatList();
        setState(() {});
        userModel.removeListener(_userHasBeenSetListener);
      }
    };
    userModel.addListener(_userHasBeenSetListener);
    _chatListStream =
        _getChatList(); // initially this will fail since user will be set to null but when user is set it will fetch the correct info
  }

  @override
  void dispose() {
    userModel.removeListener(
        _userHasBeenSetListener); // if the listener is already removed this call gets ignored so its fine
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.message_rounded,
        ),
        StreamBuilder(
          stream: _chatListStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.hasError) {
              return const SizedBox.shrink();
            }
            int unreadMessages = snapshot.data!;
            if (unreadMessages == 0) {
              return const SizedBox.shrink();
            }
            return Positioned(
              bottom: 14, // putting it on top right of the icon
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadMessages.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Stream<int> _getChatList() {
    if (userModel.value == null) {
      return Stream.value(0);
    }
    return dbReference
        .child('userChats/${userModel.value!.uid}')
        .onValue
        .asyncMap((event) {
      final chatsMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (chatsMap == null) {
        return 0;
      }
      int unreadMessages = 0;
      for (var entry in chatsMap.entries) {
        final unreadCount = entry.value['unreadCount'] as int;
        if (unreadCount > 0) unreadMessages += unreadCount;
      }
      return unreadMessages;
    });
  }
}
