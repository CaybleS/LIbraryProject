import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/profile_info.dart';
import 'dart:async';
import 'package:library_project/models/user.dart';

late StreamSubscription<DatabaseEvent> _userLibrarySubscription;
late StreamSubscription<DatabaseEvent> _lentToMeSubscription;
late StreamSubscription<DatabaseEvent> _sentBookRequestsSubscription;
late StreamSubscription<DatabaseEvent> _receivedBookRequestsSubscription;
late StreamSubscription<DatabaseEvent> _friendsSubscription;
late StreamSubscription<DatabaseEvent> _requestsSubscription;
Map<String, StreamSubscription<DatabaseEvent>> friendIdToLibrarySubscription = {};
Map<String, List<Book>> friendIdToBooks = {};
Map<String, StreamSubscription<DatabaseEvent>> userIdToSubscription = {};
Map<String, UserModel> userIdToUserModel = {};
Map<String, StreamSubscription<DatabaseEvent>> userIdToProfileSubscription = {};
Map<String, ProfileInfo> userIdToProfile = {};

void setupDatabaseSubscriptions(User user) {
  userIdToSubscription[user.uid] = setupUserSubscription(userIdToUserModel, user.uid, userUpdated);
  userIdToProfileSubscription[user.uid] = setupProfileSubscription(userIdToProfile, user.uid, profileUpdated);
  _userLibrarySubscription = setupUserLibrarySubscription(userLibrary, user, _ownedBooksUpdated);
  _lentToMeSubscription = setupLentToMeSubscription(booksLentToMe, user, _lentToMeBooksUpdated);
  _sentBookRequestsSubscription = setupSentBookRequestsSubscription(sentBookRequests, user, _sentBookRequestsUpdated);
  _receivedBookRequestsSubscription = setupReceivedBookRequestsSubscription(receivedBookRequests, user, _receivedBookRequestsUpdated);
  _friendsSubscription = setupFriendsSubscription(friends, user, _friendsUpdated);
  _requestsSubscription = setupRequestsSubscription(requests, user, _friendsUpdated);
}

void cancelDatabaseSubscriptions() {
  _userLibrarySubscription.cancel();
  _lentToMeSubscription.cancel();
  _friendsSubscription.cancel();
  _requestsSubscription.cancel();
  _sentBookRequestsSubscription.cancel();
  _receivedBookRequestsSubscription.cancel();
  friendIdToLibrarySubscription.forEach((k, v) => v.cancel());
  userIdToSubscription.forEach((k, v) => v.cancel());
  userIdToProfileSubscription.forEach((k, v) => v.cancel());
  resetGlobalData(); // we cancelled the subscriptions but still need to clear the lists and such, this does that
}

// everytime the user logs out and the bottombar gets disposed these varibles still exist so they are reset when bottombar is disposed
void resetBottombarValues() {
  refreshBottombar = ValueNotifier<bool>(false);
  refreshNotifier = ValueNotifier<int>(-1);
  selectedIndex = 0;
  prevIndex = 0;
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

// TODO should these be on social page somewhere? Idk where but probably, or m,aybe not, idk.
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

void userUpdated() {
  if (selectedIndex == profileIndex || selectedIndex == friendsPageIndex) {
    refreshNotifier.value = -1;
    refreshNotifier.value = selectedIndex;
  }
}

void profileUpdated() {
  if (selectedIndex == profileIndex || selectedIndex == friendsPageIndex) {
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
    navigatorKeys[prevIndex].currentState?.popUntil((route) => route.isFirst);
    selectedIndex = index; // switching to selected tab
    refreshBottombar.value = true;
  }
  refreshNotifier.value = index;
  prevIndex = index;
}
