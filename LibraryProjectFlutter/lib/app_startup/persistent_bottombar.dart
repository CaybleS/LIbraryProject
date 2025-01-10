import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book/add_book_homepage.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/core/friends_page.dart';
import 'package:library_project/core/homepage.dart';
import 'package:library_project/core/profile.dart';
import 'package:library_project/core/settings.dart';
import 'package:library_project/database/database.dart';

class PersistentBottomBar extends StatefulWidget {
  final User user;
  const PersistentBottomBar(this.user, {super.key});

  @override
  State<PersistentBottomBar> createState() => _PersistentBottomBarState();
}

class _PersistentBottomBarState extends State<PersistentBottomBar> {
  int _selectedIndex = 0;
  int _prevIndex = 0;
  List<Book> _userLibrary = [];
  // Needed to run functions on the 5 pages when a page is selected on the bottombar. Initialized as -1 to signal that we are not really on a page yet, and when
  // its set to values 0-4 for each page, if that page has a listener for when its set to that value, that page can run some stuff whenever its selected on the bottombar
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(-1);
  final List<Widget> _pagesList = List.filled(5, const SizedBox.shrink());

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    // Since selected index is initially 0, this means the page which renders instantly is the homepage, being rendered before userLibrary is fetched from the DB
    // and then rebuilt when its all fetched. Without the ValueKey set, the homepage wouldn't rebuild even if this pagesList index was updated (which seems weird to me but true).
    // Could technically just show a progress indicator and only load homepage after userLibrary is fetched but I like this approach better.
    _pagesList[0] = HomePage(widget.user, _userLibrary, _refreshNotifier, key: ValueKey(_userLibrary));
  }

  Future<void> _fetchUserData() async {
    _userLibrary = await getUserLibrary(widget.user);
    setState(() {
      // ensuring these pages only build after all necessary data is fetched, or in the case of homepage, rebuilt when userLibrary is fetched
      _pagesList[0] = HomePage(widget.user, _userLibrary, _refreshNotifier, key: ValueKey(_userLibrary));
      _pagesList[1] = AddBookHomepage(widget.user, _userLibrary);
      _pagesList[2] = FriendsPage(widget.user);
      _pagesList[3] = Profile(widget.user);
      _pagesList[4] = Settings(widget.user);
      _refreshNotifier.value = 0;
    });
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
