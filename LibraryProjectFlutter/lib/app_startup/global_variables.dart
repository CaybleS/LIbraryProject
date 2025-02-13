import 'package:flutter/foundation.dart';
import 'package:library_project/Social/friends/friends_page.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/models/book_requests.dart';
import 'package:library_project/models/user.dart';

// pages can access these at any time, knowing that they will be up to date guaranteed
// there are just the representations of database data which are updated by onvalue subscriptions
List<Book> userLibrary = [];
List<LentBookInfo> booksLentToMe = [];
List<SentBookRequest> sentBookRequests = [];
List<ReceivedBookRequest> receivedBookRequests = [];
List<UserModel> friends = [];
List<Request> requests = [];
ValueNotifier<UserModel?> userModel = ValueNotifier<UserModel?>(null);

// bottombar indicies, used for 1.) pages listening to the refreshNotifier to know if they are selected on the bottombar and thus should refresh and 2.)
// for the appbar to be able to change bottombar values based on appbar selection
const int homepageIndex = 0;
const int addBookPageIndex = 1;
const int friendsPageIndex = 2;
const int profileIndex = 3;
const int settingsIndex = 4;

// Needed to run functions on the 5 pages when a page is selected on the bottombar. Initialized as -1 to signal that we are not really on a page yet, and when
// its set to values 0-4 for each page, if that page has a listener for when its set to that value, that page can run some stuff whenever its selected on the bottombar
// this is needed due to the bottombar loading all 5 pages in memory at a time so it allows for logic to cause refreshes ONLY for pages the user is currently on.
ValueNotifier<int> refreshNotifier = ValueNotifier<int>(-1);
ValueNotifier<bool> refreshBottombar = ValueNotifier<bool>(false);
bool showBottombar = true; // this and the refreshBottombar allows for logic to hide bottombar on certain pages
int selectedIndex = 0;
int prevIndex = 0;

// called from the cancelSubscriptions function in appwide_setup, which is called when logout occurs
// that function merely cancels all subscriptions while this one independently just clears these global lists/maps
// since they arent tied to any widget's lifecycle and need to be cleared manually upon logout
void resetGlobalData() {
  userLibrary.clear();
  booksLentToMe.clear();
  sentBookRequests.clear();
  receivedBookRequests.clear();
  friends.clear();
  requests.clear();
  // these track or are built up from subscriptions so they should be cleared as well
  friendIdToBooks.clear();
  friendIdToLibrarySubscription.clear();
  userIdToSubscription.clear();
  userIdToUserModel.clear();
  userIdToProfileSubscription.clear();
  userIdToProfile.clear();
}