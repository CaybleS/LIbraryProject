import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';

class FriendBookPage extends StatefulWidget {

  @override
  State<FriendBookPage> createState() => _FriendBookPageState();
  final User user;
  final Book bookToView;
  final String friendId;
  final bool viewingFromSentRequest;
  const FriendBookPage(this.user, this.bookToView, this.friendId, {this.viewingFromSentRequest = false, super.key});
}

class _FriendBookPageState extends State<FriendBookPage> {
  late Book _friendsLibraryBook;
  late final VoidCallback _booksLentToMeUpdatedListener; // p sure its just for the thing that shows if its "lent" or "available"
  late final VoidCallback _friendsBooksUpdatedListener;

  @override
  void initState() {
    super.initState();
    _friendsLibraryBook = widget.bookToView;
    _booksLentToMeUpdatedListener = () {
      setState(() {});
    };
    _friendsBooksUpdatedListener = () {
      List<Book> friendsLibrary = [];
      if (widget.viewingFromSentRequest) {
        // creating a list of all books derived from all sent book requests sent to this friend
        friendsLibrary = sentBookRequests.values.where((item) => item.receiverId == widget.friendId).map((item) => item.book).toList();
      }
      else {
        friendsLibrary = List.from(friendIdToBooks[widget.friendId] ?? []);
      }
      if (!friendsLibrary.contains(_friendsLibraryBook)) {
        Navigator.pop(context);
        SharedWidgets.displayErrorDialog(context, "Your friend no longer has this book");
      }
      else {
        // I think this logic works. The only thing is that for custom added books it acts as if they no longer have it since the indexOf
        // uses the book's overrided operator== I think and if they changed title on custom added books it acts as if its a different book (it kinda is so)
        _friendsLibraryBook = friendsLibrary.elementAt(friendsLibrary.indexOf(_friendsLibraryBook));
      }
    };
    pageDataUpdatedNotifier.addListener(_booksLentToMeUpdatedListener);
    pageDataUpdatedNotifier.addListener(_friendsBooksUpdatedListener);
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_booksLentToMeUpdatedListener);
    pageDataUpdatedNotifier.removeListener(_friendsBooksUpdatedListener);
    super.dispose();
  }
  Widget _displayStatus() {
    String availableTxt;
    Color availableTxtColor;

    if (_friendsLibraryBook.lentDbKey != null) {
      availableTxtColor = Colors.red;
      if (_isBookAlreadyLentToUser()) {
        availableTxt = "Lent to you";
      }
      else {
        availableTxt = "Lent";
      }
    } else {
      availableTxt = "Available";
      availableTxtColor = const Color(0xFF43A047);
    }

    return Text(
      availableTxt,
      style: TextStyle(fontSize: 16, color: availableTxtColor),
    );
  }

  bool _isBookAlreadyLentToUser() {
    return booksLentToMe.values.any((v) => v.book == _friendsLibraryBook);
  }

  Widget _displayRequestButtonOrText() {
    if (_isBookAlreadyLentToUser()) {
      return const Text("You currently have this book lent to you!", style: TextStyle(fontSize: 14));
    }
    if (_friendsLibraryBook.usersWhoRequested != null && _friendsLibraryBook.usersWhoRequested!.contains(widget.user.uid)) {
      return Column(
        children: [
          const Text("You have already requested this book!"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _friendsLibraryBook.unsendBookRequest(widget.user.uid, widget.friendId);
              SharedWidgets.displayPositiveFeedbackDialog(context, "Request Unsent");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.all(8),
            ),
            child: const Text(
              "Unsend Request",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ((_friendsLibraryBook.usersWhoRequested?.length ?? 0) <= 1)
              ? (_friendsLibraryBook.usersWhoRequested?.length == 1)
                ? "This book has 1 request for it"
                : "This book has no requests for it"
              : "This book has ${_friendsLibraryBook.usersWhoRequested?.length ?? 0} requests for it",
            style: const TextStyle(fontSize: 14), textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ElevatedButton(
      onPressed: () async {
        for (int i = 0; i < userLibrary.length; i++) {
          if (_friendsLibraryBook == userLibrary[i]) {
            if (!await SharedWidgets.displayWarningDialog(context, "You already own this book!", "Request Anyway")) {
              return;
            }
          }
        }
        if (mounted) {
          SharedWidgets.displayPositiveFeedbackDialog(context, "Book Requested");
        }
        _friendsLibraryBook.sendBookRequest(widget.user.uid, widget.friendId);
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.skyBlue,
        padding: const EdgeInsets.all(8),
      ),
      child: const Text(
        "Request this book",
        style: TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Info"),
        centerTitle: true,
        backgroundColor: AppColor.appbarColor,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 21),
        child: Column(
          children: [
            Flexible(
              child: Row(
                children: [
                  AspectRatio(
                    aspectRatio: 0.7,
                    child: _friendsLibraryBook.getCoverImage(),
                  ),
                  const SizedBox(width: 5),
                  Flexible( 
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _friendsLibraryBook.title ?? "No title found",
                          style: const TextStyle(fontSize: 20),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _friendsLibraryBook.author ?? "No author found",
                          style: const TextStyle(fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Flexible(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Text(
                        _friendsLibraryBook.description ?? "No description found",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("Current Status:", style: TextStyle(fontSize: 16)),
                  _displayStatus(),
                  const SizedBox(height: 12),
                  _displayRequestButtonOrText(),
                  // TODO what on earth is happening on this page why is the spacer weird why are the flex weird why is it overflowing on small phone when requesting stuff i dont understand
                  // (ui overflow problems that make no sense)
                ],
              ),
            ),
            const Spacer(),
            const Text(
              "Book Owned by:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Name: ${userIdToUserModel[widget.friendId]!.name}",
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Username: ${userIdToUserModel[widget.friendId]!.username}",
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}