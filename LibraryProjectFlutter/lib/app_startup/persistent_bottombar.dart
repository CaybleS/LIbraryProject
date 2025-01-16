import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book/add_book_homepage.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/core/friends_page.dart';
import 'package:library_project/core/homepage.dart';
import 'package:library_project/core/profile.dart';
import 'package:library_project/core/settings.dart';

class PersistentBottomBar extends StatefulWidget {
  final User user;
  const PersistentBottomBar(this.user, {super.key});

  @override
  State<PersistentBottomBar> createState() => _PersistentBottomBarState();
}

class _PersistentBottomBarState extends State<PersistentBottomBar> {
  final List<Book> _userLibrary = [];
  final List<LentBookInfo> _booksLentToMe = [];
  final List<Friend> _friends = [];
  final List<Widget> _pagesList = List.filled(5, const SizedBox.shrink());
  late final VoidCallback _refreshBottombarListener;

  @override
  void initState() {
    super.initState();
    setupInitialStuff(_userLibrary, _booksLentToMe, _friends, widget.user);
    _pagesList[homepageIndex] = HomePage(widget.user, _userLibrary, _booksLentToMe, _friends, refreshNotifier);
    _pagesList[addBookPageIndex] = AddBookHomepage(widget.user, _userLibrary, refreshNotifier);
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
    cancelInitialStuff();
    refreshBottombar.removeListener(_refreshBottombarListener);
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
    return Scaffold(
      body: Stack(
        children: List.generate(
          navigatorKeys.length,
          (index) => _buildOffstageNavigator(index),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        onTap: onItemTapped,
      ),
    );
  }
}
