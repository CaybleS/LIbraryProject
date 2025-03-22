import 'package:flutter/foundation.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/models/book_requests_model.dart';
import 'package:shelfswap/models/user.dart';

// pages can access these at any time, knowing that they will be up to date guaranteed
// there are just the representations of database data which are updated by onvalue subscriptions
List<Book> userLibrary = [];
Map<String, LentBookInfo> booksLentToMe = {}; // it maps the book db key itself to the LentBookInfo so we can update the LentBookInfo if needed
Map<String, SentBookRequest> sentBookRequests = {}; // the string is the book db key here also, to update that book if needed
List<ReceivedBookRequest> receivedBookRequests = [];
List<String> friendIDs = [];
ValueNotifier<List<String>> requestIDs = ValueNotifier<List<String>>(List<String>.empty(growable: true));
List<String> sentFriendRequests = [];
ValueNotifier<UserModel?> userModel = ValueNotifier<UserModel?>(null);
// signal means to show the app's "welcome back" dialog when both requests and userLibrary are initially loaded
ValueNotifier<int> requestsAndBooksLoaded = ValueNotifier<int>(0);
ValueNotifier<int> numUnseenBooksReadyToReturnNotifier = ValueNotifier<int>(0);

// bottombar indicies, used for 1.) pages listening to the refreshNotifier to know if they are selected on the bottombar and thus should refresh and 2.)
// for the appbar to be able to change bottombar values based on appbar selection
const int homepageIndex = 0;
const int addBookPageIndex = 1;
const int friendsPageIndex = 2;
const int messagesIndex = 3;
const int profileIndex = 4;

// all these do is trigger some logic for any listeners, whenever they get updated. So this one is the main refresh notifier,
// I just increment it to signify that the page should refresh
ValueNotifier<int> pageDataUpdatedNotifier = ValueNotifier<int>(0);
// Basically, the valueNotifier refreshes every time it gets updated, so having it as a bool is not really the best
// since if you set it to true to signal a refresh you'd need to set it to false after and that would trigger another refresh.
// It only has 1 listener though so I just check if the value is true and if so update it and set it to false again.
// But for the normal refresh notifier this is too complicated so its just incremented to signal a refresh.
ValueNotifier<bool> refreshBottombar = ValueNotifier<bool>(false);
// this is used to allow for logic for things to happen when you click off a page via the bottombar, for example homepage
// filters should reset when you click off it on the bottombar, but not when a book is added. Thus, page data updated notifier
// and bottombar index changed notifier must exist to track these 2 different things. It works by signaling the
// page the user switches off of (using prevIndex) so if the user switches off the homepage, it immediately updates the homepage using this.
ValueNotifier<int> bottombarIndexChangedNotifier = ValueNotifier<int>(0);
bool showBottombar = true; // this and the refreshBottombar allows for logic to hide bottombar on certain pages
int selectedIndex = 0;
int prevIndex = 0;

// Indicates which tab is selected on friend page, so that other pages can send you to requests or list specifically
int friendPageTabSelected = 0;

// called from the cancelSubscriptions function in appwide_setup, which is called when logout occurs
// that function merely cancels all subscriptions while this one independently just clears these global lists/maps
// since they arent tied to any widget's lifecycle and need to be cleared manually upon logout
void resetGlobalData() { // TODO should this go in appwide_setup?
  userLibrary.clear();
  booksLentToMe.clear();
  sentBookRequests.clear();
  receivedBookRequests.clear();
  lentBookDbKeyToSubscriptionForIt.clear();
  sentBookRequestBookDbKeyToSubscriptionForIt.clear();
  friendIDs.clear();
  requestIDs.value.clear();
  sentFriendRequests.clear();
  // these track or are built up from subscriptions so they should be cleared as well
  friendIdToBooks.clear();
  friendIdToLibrarySubscription.clear();
  userIdToSubscription.clear();
  userIdToUserModel.clear();
  userIdToProfileSubscription.clear();
  userIdToProfile.clear();
  idsToFriendList.clear();
  idToFriendSubscription.clear();
  requestsAndBooksLoaded.value = 0;
  numUnseenBooksReadyToReturnNotifier.value = 0;
  friendPageTabSelected = 0;
}