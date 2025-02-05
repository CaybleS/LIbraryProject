import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/database/subscriptions.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/models/profile_info.dart';
import 'dart:async';
import 'package:shelfswap/models/user.dart';

late StreamSubscription<DatabaseEvent> _userLibrarySubscription;
late StreamSubscription<DatabaseEvent> _lentToMeSubscription;
// all 3 of these, the lent book info, sent, and received book requests, all store in their data structure a book of some kind
// so we need subscriptions to ensure this book is up to date with the database. For example, a received book request on a non-lent book
// would be tied to a non-lent book even if that book later gets lent out, which is why this is definitely needed.
Map<String, StreamSubscription> lentBookDbKeyToSubscriptionForIt = {};
Map<String, StreamSubscription> sentBookRequestBookDbKeyToSubscriptionForIt =
    {};
late StreamSubscription<DatabaseEvent> _sentBookRequestsSubscription;
late StreamSubscription<DatabaseEvent> _receivedBookRequestsSubscription;
late StreamSubscription<DatabaseEvent> _friendsSubscription;
late StreamSubscription<DatabaseEvent> _requestsSubscription;
late StreamSubscription<DatabaseEvent> _sentFriendRequestsSubscription;
Map<String, StreamSubscription<DatabaseEvent>> friendIdToLibrarySubscription =
    {};
Map<String, List<Book>> friendIdToBooks = {};
Map<String, StreamSubscription<DatabaseEvent>> userIdToSubscription = {};
Map<String, UserModel> userIdToUserModel = {};
Map<String, StreamSubscription<DatabaseEvent>> userIdToProfileSubscription = {};
Map<String, ProfileInfo> userIdToProfile = {};
Map<String, StreamSubscription<DatabaseEvent>> idToFriendSubscription = {};
Map<String, List<String>> idsToFriendList = {};
Completer<void> userLibraryLoaded = Completer<void>();

void setupDatabaseSubscriptions(User user, BuildContext context) {
  userIdToSubscription[user.uid] = setupUserSubscription(
      userIdToUserModel, user.uid, userUpdated,
      context: context);
  userIdToProfileSubscription[user.uid] =
      setupProfileSubscription(userIdToProfile, user.uid, profileUpdated);
  _userLibrarySubscription =
      setupUserLibrarySubscription(userLibrary, user, _ownedBooksUpdated);
  _lentToMeSubscription =
      setupLentToMeSubscription(booksLentToMe, user, _lentToMeBooksUpdated);
  _sentBookRequestsSubscription = setupSentBookRequestsSubscription(
      sentBookRequests, user, _sentBookRequestsUpdated);
  _receivedBookRequestsSubscription = setupReceivedBookRequestsSubscription(
      receivedBookRequests, user, _receivedBookRequestsUpdated);
  _friendsSubscription =
      setupFriendsSubscription(friendIDs, user, _friendsUpdated);
  _requestsSubscription =
      setupRequestsSubscription(requestIDs, user, _friendRequestsUpdated);
  _sentFriendRequestsSubscription = setupSentFriendRequestSubscription(
      sentFriendRequests, user.uid, _sentFriendRequestsUpdated);
}

void cancelDatabaseSubscriptions(User user) {
  _userLibrarySubscription.cancel();
  _lentToMeSubscription.cancel();
  _friendsSubscription.cancel();
  _requestsSubscription.cancel();
  _sentBookRequestsSubscription.cancel();
  _receivedBookRequestsSubscription.cancel();
  _sentFriendRequestsSubscription.cancel();
  friendIdToLibrarySubscription.forEach((k, v) => v.cancel());
  userIdToSubscription.forEach((k, v) => v.cancel());
  userIdToProfileSubscription.forEach((k, v) => v.cancel());
  idToFriendSubscription.forEach((k, v) => v.cancel());
  lentBookDbKeyToSubscriptionForIt.forEach((k, v) => v.cancel());
  sentBookRequestBookDbKeyToSubscriptionForIt.forEach((k, v) => v.cancel());
  resetGlobalData(user); // we cancelled the subscriptions but still need to clear the lists and such, this does that
}

// everytime the user logs out and the bottombar gets disposed these varibles still exist so they are reset when bottombar is disposed
void resetBottombarValues() {
  refreshBottombar.value = false;
  pageDataUpdatedNotifier.value = 0;
  bottombarIndexChangedNotifier.value = 0;
  selectedIndex = 0;
  prevIndex = 0;
}

void updatePageDataRefreshNotifier() {
  // incrementing this signals an update to everyone whos listening to it. Ensure this function call is
  // protected by logic in the form of checking selectedIndex to make sure we only refresh pages which are selected
  // on the bottombar, since the offstage bottombar loads the 5 pages into memory. Note that this is only a concern
  // with the main pages (homepage, add books page, profile), not the nested pages since those are disposed when user
  // clicks off them (prevIndex logic) and thus are never in memory when the user's selectedIndex isn't the one for that page.
  pageDataUpdatedNotifier.value = (pageDataUpdatedNotifier.value + 1) %
      100; // the mod just to ensure the value cant overflow since theoretically it can without it
}

// So for the pages which are affected by userLibrary, if we are currently on them, this signals the refresh notifier function
// for them, which will call setState and refresh the page with the updated userLibrary.
void _ownedBooksUpdated() {
  if (selectedIndex == homepageIndex ||
      selectedIndex == addBookPageIndex ||
      selectedIndex == profileIndex) {
    updatePageDataRefreshNotifier();
  }
}

void _lentToMeBooksUpdated() {
  // if we are on the pages which care about books lent to the user we refresh it
  // it needs homepage index for lent to me tab, and friends page index since friend_book_page cares about it
  if (selectedIndex == homepageIndex ||
      selectedIndex == friendsPageIndex ||
      selectedIndex == profileIndex) {
    updatePageDataRefreshNotifier();
  }
}

void _sentBookRequestsUpdated() {
  if (selectedIndex == homepageIndex) {
    updatePageDataRefreshNotifier();
  }
}

void _receivedBookRequestsUpdated() {
  if (selectedIndex == homepageIndex) {
    updatePageDataRefreshNotifier();
  }
}

void _friendsUpdated() {
  if (selectedIndex == homepageIndex || selectedIndex == friendsPageIndex) {
    updatePageDataRefreshNotifier();
  }
}

void _sentFriendRequestsUpdated() {
  if (selectedIndex == friendsPageIndex) {
    updatePageDataRefreshNotifier();
  }
}

void _friendRequestsUpdated() {
  if (selectedIndex == friendsPageIndex) {
    updatePageDataRefreshNotifier();
  }
}

void friendsBooksUpdated() {
  if (selectedIndex == friendsPageIndex) {
    updatePageDataRefreshNotifier();
  }
}

void lentToMeRequestsUpdated() {
  if (selectedIndex == homepageIndex) {
    updatePageDataRefreshNotifier();
  }
}

void userUpdated() {
  if (selectedIndex == profileIndex || selectedIndex == friendsPageIndex) {
    updatePageDataRefreshNotifier();
  }
}

void profileUpdated() {
  if (selectedIndex == profileIndex || selectedIndex == friendsPageIndex) {
    updatePageDataRefreshNotifier();
  }
}

void friendOfFriendUpdated() {
  if (selectedIndex == profileIndex) {
    updatePageDataRefreshNotifier();
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
  if (index == friendsPageIndex && requestIDs.value.isNotEmpty) {
    // Will put user on the requests page when clicking on bottombar when there is a number (aka when you have a friend request)
    friendPageTabSelected = 1;
  }

  if (index == selectedIndex) {
    // If the user taps the current tab, pop to the root route of that tab
    navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
  } else {
    bottombarIndexChangedNotifier.value = -1;
    // signaling the page we switched off so it can refresh itself now if it wants to
    bottombarIndexChangedNotifier.value = prevIndex;
    // for this popUntil, if you're in deeply nested pages on homepage route for example, this takes you to the homepage itself. It needs to
    // be done this way so that the popping occurs while switching from a tab rather than switching to a tab so that users don't see it.
    navigatorKeys[prevIndex].currentState?.popUntil((route) => route.isFirst);
    selectedIndex = index; // switching to selected tab
    refreshBottombar.value = true;
  }
  // The refresh notifier has logic to only refresh the 5 bottombar pages in memory when we have selected them so we to refresh
  // these pages when we go to them. No need to refresh them when changes occur when we aren't on them, but then this needs to occur.
  updatePageDataRefreshNotifier();
  prevIndex = index;
}
