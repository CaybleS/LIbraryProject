import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:library_project/Social/friends/friends_page.dart';
import 'package:library_project/add_book/add_book_homepage.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/core/homepage.dart';
import 'package:library_project/Social/profile.dart';
import 'package:library_project/core/settings.dart';

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
    _pagesList[profileIndex] = Profile(widget.user);
    _pagesList[settingsIndex] = Settings(widget.user);
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
    return PopScope( // this allows the android back button to work properly
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        bool shouldPop = !await navigatorKeys[selectedIndex].currentState!.maybePop();
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
                icon: Icon(Icons.search),
                label: "Add book",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                label: "Friends",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_rounded),
                label: "Profile",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Settings",
              ),
            ],
            currentIndex: selectedIndex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            onTap: bottombarItemTapped,
          )
          : const SizedBox.shrink(),
      )
    );
  }
}
