import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/Social/friends/friends_page.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/book_requests.dart';
import 'dart:async';
import 'package:library_project/models/user.dart';

const int homepageIndex = 0;
const int addBookPageIndex = 1;
const int friendsPageIndex = 2;
const int profileIndex = 3;
const int settingsIndex = 4;

// pages can access these at any time, knowing that they will be up to date guaranteed
List<Book> userLibrary = [];
List<LentBookInfo> booksLentToMe = [];
List<SentBookRequest> sentBookRequests = [];
List<ReceivedBookRequest> receivedBookRequests = [];
List<UserModel> friends = [];
List<Request> requests = [];
ValueNotifier<UserModel?> userModel = ValueNotifier<UserModel?>(null);
late StreamSubscription<DatabaseEvent> _userLibrarySubscription;
late StreamSubscription<DatabaseEvent> _userSubscription;
late StreamSubscription<DatabaseEvent> _lentToMeSubscription;
late StreamSubscription<DatabaseEvent> _sentBookRequestsSubscription;
late StreamSubscription<DatabaseEvent> _receivedBookRequestsSubscription;
late StreamSubscription<DatabaseEvent> _friendsSubscription;
late StreamSubscription<DatabaseEvent> _requestsSubscription;
// Needed to run functions on the 5 pages when a page is selected on the bottombar. Initialized as -1 to signal that we are not really on a page yet, and when
// its set to values 0-4 for each page, if that page has a listener for when its set to that value, that page can run some stuff whenever its selected on the bottombar
// this is needed due to the bottombar loading all 5 pages in memory at a time so it allows for logic to cause refreshes ONLY for pages the user is currently on.
ValueNotifier<int> refreshNotifier = ValueNotifier<int>(-1);
ValueNotifier<bool> refreshBottombar = ValueNotifier<bool>(false);
int selectedIndex = 0;
int _prevIndex = 0;
bool showBottombar = true;
Map<String, StreamSubscription<DatabaseEvent>> friendIdToLibrarySubscription = {};
Map<String, List<Book>> friendIdToBooks = {};

void setupDatabaseSubscriptions(User user) {
  _userSubscription = setupUserSubscription(userModel, user.uid);
  _userLibrarySubscription = setupUserLibrarySubscription(userLibrary, user, _ownedBooksUpdated);
  _lentToMeSubscription = setupLentToMeSubscription(booksLentToMe, user, _lentToMeBooksUpdated);
  _sentBookRequestsSubscription = setupSentBookRequestsSubscription(sentBookRequests, user, _sentBookRequestsUpdated);
  _receivedBookRequestsSubscription = setupReceivedBookRequestsSubscription(receivedBookRequests, user, _receivedBookRequestsUpdated);
  _friendsSubscription = setupFriendsSubscription(friends, user, _friendsUpdated);
  _requestsSubscription = setupRequestsSubscription(requests, user, _friendsUpdated);
}

void cancelDatabaseSubscriptions() {
  _userLibrarySubscription.cancel();
  _userSubscription.cancel();
  _lentToMeSubscription.cancel();
  _friendsSubscription.cancel();
  _requestsSubscription.cancel();
  _sentBookRequestsSubscription.cancel();
  _receivedBookRequestsSubscription.cancel();
  friendIdToLibrarySubscription.forEach((k, v) => v.cancel());
  _resetGlobalData();
}

void _resetGlobalData() {
  userLibrary.clear();
  booksLentToMe.clear();
  sentBookRequests.clear();
  receivedBookRequests.clear();
  friends.clear();
  requests.clear();
  // these track or are built up from subscriptions so they should be cleared as well
  friendIdToBooks.clear();
  friendIdToLibrarySubscription.clear();
}

// everytime the user logs out and the bottombar gets disposed these varibles still exist so they are reset when bottombar is disposed
void resetBottombarValues() {
  refreshBottombar = ValueNotifier<bool>(false);
  refreshNotifier = ValueNotifier<int>(-1);
  selectedIndex = 0;
  _prevIndex = 0;
}

// So for the pages which are affected by userLibrary, if we are currently on them, this signals the refresh notifier function
// for them, which will call setState and refresh the page with the updated userLibrary.
void _ownedBooksUpdated() {
  if (selectedIndex == homepageIndex || selectedIndex == addBookPageIndex) {
    refreshNotifier.value = -1;
    refreshNotifier.value = selectedIndex;
  }
}

void _lentToMeBooksUpdated() {
  // if we are on the pages which care about books lent to the user we refresh it
  // it needs homepage index for lent to me tab, and friends page index since friend_book_page cares about it 
  if (selectedIndex == homepageIndex || selectedIndex == friendsPageIndex) {
    refreshNotifier.value = -1;
    refreshNotifier.value = selectedIndex;
  }
}

void _sentBookRequestsUpdated() {
  if (selectedIndex == homepageIndex) {
    refreshNotifier.value = -1;
    refreshNotifier.value = selectedIndex;
  }
}

void _receivedBookRequestsUpdated() {
  if (selectedIndex == homepageIndex) {
    refreshNotifier.value = -1;
    refreshNotifier.value = selectedIndex;
  }
}

void _friendsUpdated() {
  if (selectedIndex == homepageIndex || selectedIndex == friendsPageIndex) {
    refreshNotifier.value = -1;
    refreshNotifier.value = selectedIndex;
  }
}

void friendsBooksUpdated() {
  if (selectedIndex == friendsPageIndex) {
    refreshNotifier.value = -1;
    refreshNotifier.value = selectedIndex;
  }
}

void lentToMeRequestsUpdated() {
  if (selectedIndex == homepageIndex) {
    refreshNotifier.value = -1;
    refreshNotifier.value = selectedIndex;
  }
}

// the bottombar works by using 5 nested navigators for each 5 bottombar options, with global keys to identify each one
final List<GlobalKey<NavigatorState>> navigatorKeys = [
  GlobalKey<NavigatorState>(),
  GlobalKey<NavigatorState>(),
  GlobalKey<NavigatorState>(),
  GlobalKey<NavigatorState>(),
  GlobalKey<NavigatorState>(),
];

// both the bottombar and the appbar call this function
void bottombarItemTapped(int index) {
  if (index == selectedIndex) {
    // If the user taps the current tab, pop to the root route of that tab
    navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
  } else {
    // so if you're in deeply nested pages on homepage route for example, this takes you to the homepage itself. It needs to be
    // done this way so that the popping occurs while switching from a tab rather than switching to a tab so that users don't see it.
    navigatorKeys[_prevIndex].currentState?.popUntil((route) => route.isFirst);
    selectedIndex = index; // switching to selected tab
    refreshBottombar.value = true;
  }
  refreshNotifier.value = index;
  _prevIndex = index;
}
