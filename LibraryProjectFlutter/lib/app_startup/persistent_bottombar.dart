import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book/add_book_homepage.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/core/friends_page.dart';
import 'package:library_project/core/homepage.dart';
import 'package:library_project/core/profile.dart';
import 'package:library_project/core/settings.dart';
import 'package:library_project/database/database.dart';
import 'dart:async';

class PersistentBottomBar extends StatefulWidget {
  final User user;
  const PersistentBottomBar(this.user, {super.key});

  @override
  State<PersistentBottomBar> createState() => _PersistentBottomBarState();
}

class _PersistentBottomBarState extends State<PersistentBottomBar> {
  int _selectedIndex = 0;
  int _prevIndex = 0;
  final List<Book> _userLibrary = [];
  final List<LentBookInfo> _booksLentToMe = [];
  // Needed to run functions on the 5 pages when a page is selected on the bottombar. Initialized as -1 to signal that we are not really on a page yet, and when
  // its set to values 0-4 for each page, if that page has a listener for when its set to that value, that page can run some stuff whenever its selected on the bottombar
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(-1);
  final List<Widget> _pagesList = List.filled(5, const SizedBox.shrink());
  late StreamSubscription<DatabaseEvent> _userLibrarySubscription;
  late StreamSubscription<DatabaseEvent> _lentToMeSubscription;

  @override
  void initState() {
    super.initState();
    // these 3 things are very important, super important even! So important that they shouldn't be hidden in a persistent bottombar file!
    // but idk how else to do it so whatever.
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    _userLibrarySubscription = setupUserLibrarySubscription(_userLibrary, widget.user, _ownedBooksUpdated);
    _lentToMeSubscription = setupLentToMeSubscription(_booksLentToMe, widget.user, _lentToMeBooksUpdated);
    _pagesList[0] = HomePage(widget.user, _userLibrary, _booksLentToMe, _refreshNotifier);
    _pagesList[1] = AddBookHomepage(widget.user, _userLibrary, _refreshNotifier);
    _pagesList[2] = FriendsPage(widget.user);
    _pagesList[3] = Profile(widget.user);
    _pagesList[4] = Settings(widget.user);
  }

  @override
  void dispose() {
    _userLibrarySubscription.cancel();
    _lentToMeSubscription.cancel();
    super.dispose();
  }

  void _ownedBooksUpdated() {
    // So for the pages which are affected by userLibrary, if we are currently on them, this signals the refresh notifier function
    // for them, which will call setState and refresh the page with the updated userLibrary
    if (_selectedIndex == 0 || _selectedIndex == 1) {
      _refreshNotifier.value = -1;
      _refreshNotifier.value = _selectedIndex;
    }
  }

  void _lentToMeBooksUpdated() {
    // if we are on the pages which care about books lent to the user we refresh it
    if (_selectedIndex == 0) {
      _refreshNotifier.value = -1;
      _refreshNotifier.value = _selectedIndex;
    }
  }

  // the bottombar works by using 5 nested navigators for each 5 bottombar options, with global keys to identify each one
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      // If the user taps the current tab, pop to the root route of that tab
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }
    else {
      // so if you're in deeply nested pages on homepage route for example, this takes you to the homepage itself. It needs to be
      // done this way so that the popping occurs while switching from a tab rather than switching to a tab so that users don't see it.
      _navigatorKeys[_prevIndex].currentState?.popUntil((route) => route.isFirst);
      setState(() {
        _selectedIndex = index; // switching to selected tab
      });
    }
    _refreshNotifier.value = index;
    _prevIndex = index;
  }

  // each bottombar tab has its own offstage (which loads the page into memory), and each of the 5 pages
  // has its own navigation stack, identified by its GlobalKey. Note that push and pop work as normal on these
  // since push and pop just use the most recent parent navigator.
  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) {
              return _pagesList[index];
            }
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(
          _navigatorKeys.length, 
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
