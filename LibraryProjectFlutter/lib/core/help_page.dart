import 'package:flutter/material.dart';
import 'package:shelfswap/ui/colors.dart';

// TODO this page will probably need to be updated occasionally as things change
// Therefore don't remove this comment
class HelpPage extends StatelessWidget {
  HelpPage({super.key});

  final _topKey = GlobalKey();

  final _addBookKey = GlobalKey();
  final _bookSearchKey = GlobalKey();
  final _barcodeBookKey = GlobalKey();
  final _addManuallyBookKey = GlobalKey();

  final _sendFriendRequestKey = GlobalKey();
  final _recieveFriendRequestKey = GlobalKey();

  final _bookRequestKey = GlobalKey();
  final _lendBookKey = GlobalKey();
  final _lendBookPageKey = GlobalKey();
  final _lendBookRequestKey = GlobalKey();

  final _markReturnedKey = GlobalKey();
  final _markAsReadyKey = GlobalKey();

  final _editBookDetailsKey = GlobalKey();
  final _editProfileKey = GlobalKey();

  final _messageKey = GlobalKey();
  final _messageFriendListKey = GlobalKey();
  final _messagePageKey = GlobalKey();
  final _groupChatKey = GlobalKey();

  Widget _backToTopButton() {
    return InkWell(
        onTap: () {
          Scrollable.ensureVisible(
            _topKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: const Text(
          "Back to top",
          style: TextStyle(fontSize: 14, color: Colors.blue),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        title: const Text("Help"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Table of Contents",
                key: _topKey,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(height: 5),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _addBookKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Add a Book to Your Library",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _bookSearchKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "\t\t\tUsing Search Bar",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _barcodeBookKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "\t\t\tUsing Barcode",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _addManuallyBookKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "\t\t\tAdd Manually",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _sendFriendRequestKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Send a Friend Request",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _recieveFriendRequestKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Recieve a Friend Request",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _bookRequestKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Request a Book from a Friend",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _lendBookKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Mark a Book as Lent",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _lendBookPageKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "\t\t\tThrough Book Page",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _lendBookRequestKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "\t\t\tThrough Book Requests",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _markAsReadyKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Tell the Book Owner a Book is Ready to be Returned",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _markReturnedKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Mark a Book You Own as Returned",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _editBookDetailsKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Edit Book Details",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _editProfileKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Edit Profile Information",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _messageKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Message Another User",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _messageFriendListKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "\t\t\tThrough Friend's List",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _messagePageKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "\t\t\tThrough Messaging Page",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                            InkWell(
                                onTap: () {
                                  Scrollable.ensureVisible(
                                    _groupChatKey.currentContext!,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Text(
                                  "Start a Group Chat",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blue),
                                )),
                          ]))),
              const SizedBox(height: 10),
              Text(
                "Add a Book to Your Library",
                key: _addBookKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Text(
                "Using Search Bar",
                key: _bookSearchKey,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the search icon on the bottom of the screen (second icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Enter the book's title or author into the search bar and tap \"Search\"",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Locate the book you want to add to your library and tap \"Add Book\"",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 10),
              Text(
                "Using Barcode",
                key: _barcodeBookKey,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the search icon on the bottom of the screen (second icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap \"Scan Barcode\"",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Line up the barcode in the red box on the screen with your phone camera",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 10),
              Text(
                "Add Manually",
                key: _addManuallyBookKey,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the search icon on the bottom of the screen (second icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap \"Add Manually\"",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Fill in book information",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Tap \"Add Book\"",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Send a Friend Request",
                key: _sendFriendRequestKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the friends icon on the bottom of the screen (third icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap the plus icon at the bottom right of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Enter your friend's username or friend code",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Tap \"Send Request\"",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Recieve a Friend Request",
                key: _recieveFriendRequestKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the friends icon on the bottom of the screen (third icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap the plus icon at the bottom right of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Tap the \"Your Friend Code\" tab at the top of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Copy and send your friend code to your friend or have them scan your QR code",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "5. After you have recieved a friend request, tap the friends icon on the bottom of the screen (third icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "6. Accept the request with the checkmark icon or deny the request with the X icon",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Request a Book from a Friend",
                key: _bookRequestKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the friends icon on the bottom of the screen (third icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Select the \"Friend's List\" tab at the top of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Find the friend you would like to lend from",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Tap the \"View Library\" button",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "5. Find the book you would like to borrow and tap it to view more information",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "6. Tap \"Request this book\"",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Mark a Book as Lent",
                key: _lendBookKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Through Book Page",
                key: _lendBookPageKey,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the home icon on the bottom of the screen (first icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Find and tap the book you would like to lend",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Tap the blue \"Lend\" button",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Find and select the friend you have lent the book to",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "5. Select the length of loan",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "6. Tap \"Flag as lent\"",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 10),
              // TODO this section might change if we add dashboard
              Text(
                "Through Book Requests",
                key: _lendBookRequestKey,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the home icon on the bottom of the screen (first icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap the \"View\" button at the bottom of the screen to view recieved and sent book requests",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Find the book you would like to lend and person you would like to mark as lent to",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Tap \"You've lent this book to them\"",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Tell the Book Owner a Book is Ready to be Returned",
                key: _markAsReadyKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the home icon on the bottom of the screen (first icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap the \"Lent to me\" tab at the top of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Find the book you are ready to return",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Tap \"Ready To Return\"",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Mark a Book You Own as Returned",
                key: _markReturnedKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the home icon on the bottom of the screen (first icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap the \"Lent\" tab at the top of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Find the book that has been returned and tap it",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Tap the blue \"Return\" button",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "5. Tap \"Yes\"",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Edit Book Details",
                key: _editBookDetailsKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the home icon on the bottom of the screen (first icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Find the book you would like to edit",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Tap the heart on the right side of the screen to add to favorites. You can view your favorites under the "
                "\"Favorites\" tab at the top of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Tap the book to view more information",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "5. Tap the \"- star\" to select a rating of the book",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "6. Tap the \"-\" under condition to note the condition of the book",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "7. Tap the \"Not read\", \"Currently Reading\", or \"Not Read\" to note your reading status",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "8. Tap the \"Edit Notes\" button note add any notes about the book you would like to track",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "9. Tap the \"Delete\" button to remove the book from your library",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Edit Profile Information",
                key: _editProfileKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the profile icon on the bottom of the screen (fifth icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap the \"Edit Profile\" button under your profile picture",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Here you can change your display name and profile picture",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. You can also add an \"About Me,\" favorite genre, and favorite books which will be viewable"
                " from your profile",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "5. Tap the \"Save Changes\" button",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Message Another User",
                key: _messageKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Through Friend's List",
                key: _messageFriendListKey,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the friend icon on the bottom of the screen (third icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Find the friend you would like to message and tap on them",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Tap the \"Message\" button under their profile picture",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Type a message or tap the camera button on the left to add a photo",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "5. Tap the airplane button on the right to send the message",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 10),
              Text(
                "Through Messaging Page",
                key: _messagePageKey,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the messaging icon on the bottom of the screen (fourth icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap the \"New Chat\" button at the bottom right of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Find and tap the friend you would like to message",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. Type a message or tap the camera button on the left to add a photo",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "5. Tap the airplane button on the right to send the message",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
              const SizedBox(height: 20),
              Text(
                "Start a Group Chat",
                key: _groupChatKey,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const Text(
                "1. Tap the messaging icon on the bottom of the screen (fourth icon)",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "2. Tap the \"New Chat\" button at the bottom right of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "3. Tap the \"Create Group\" button at the bottom right of the screen",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "4. At the top of the screen you can name the group and add a picture",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "5. Find and tap the friends you would like to add the the group",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "6. Type a message or tap the camera button on the left to add a photo",
                style: TextStyle(fontSize: 20),
              ),
              const Text(
                "7. Tap the airplane button on the right to send the message",
                style: TextStyle(fontSize: 20),
              ),
              _backToTopButton(),
            ],
          ),
        ),
      ),
    );
  }
}
