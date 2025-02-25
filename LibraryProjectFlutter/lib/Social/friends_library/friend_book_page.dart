import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';

class FriendBookPage extends StatefulWidget {

  @override
  State<FriendBookPage> createState() => _FriendBookPageState();
  final User user;
  final Book bookToView;
  final String friendId;
  const FriendBookPage(this.user, this.bookToView, this.friendId, {super.key});
}

class _FriendBookPageState extends State<FriendBookPage> {
  late final VoidCallback _booksLentToMeUpdatedListener; // p sure its just for the thing that shows if its "lent" or "available"

  @override
  void initState() {
    super.initState();
    _booksLentToMeUpdatedListener = () {
      setState(() {});
    };
    pageDataUpdatedNotifier.addListener(_booksLentToMeUpdatedListener);
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_booksLentToMeUpdatedListener);
    super.dispose();
  }
  Widget _displayStatus() {
    String availableTxt;
    Color availableTxtColor;

    if (widget.bookToView.lentDbKey != null) {
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
    for (int i = 0; i < booksLentToMe.length; i++) {
      if (booksLentToMe[i].book == widget.bookToView) {
        return true;
      }
    }
    return false;
  }

  Widget _displayRequestButtonOrText() {
    if (_isBookAlreadyLentToUser()) {
      return const Text("You currently have this book lent to you!");
    }
    if (widget.bookToView.usersWhoRequested != null && widget.bookToView.usersWhoRequested!.contains(widget.user.uid)) {
      return Column(
        children: [
          const Text("You have already requested this book!"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              widget.bookToView.unsendBookRequest(widget.user.uid, widget.friendId);
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
            ((widget.bookToView.usersWhoRequested?.length ?? 0) <= 1)
              ? (widget.bookToView.usersWhoRequested?.length == 1)
                ? "This book has 1 request for it"
                : "This book has no requests for it"
              : "This book has ${widget.bookToView.usersWhoRequested?.length ?? 0} requests for it",
            style: const TextStyle(fontSize: 14), textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ElevatedButton(
      onPressed: () async {
        for (int i = 0; i < userLibrary.length; i++) {
          if (widget.bookToView == userLibrary[i]) {
            if (!await SharedWidgets.displayWarningDialog(context, "You already own this book!", "Request Anyway")) {
              return;
            }
          }
        }
        if (mounted) {
          SharedWidgets.displayPositiveFeedbackDialog(context, "Book Requested");
        }
        widget.bookToView.sendBookRequest(widget.user.uid, widget.friendId);
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
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Row(
                children: [
                  AspectRatio(
                    aspectRatio: 0.7,
                    child: widget.bookToView.getCoverImage(),
                  ),
                  const SizedBox(width: 5),
                  Flexible( 
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.bookToView.title ?? "No title found",
                            style: const TextStyle(fontSize: 20),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            widget.bookToView.author ?? "No author found",
                            style: const TextStyle(fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  widget.bookToView.description ?? "No description found",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text("Current Status:", style: TextStyle(fontSize: 16)),
            Flexible(
              child: _displayStatus(),
            ),
            const SizedBox(height: 12),
            _displayRequestButtonOrText(),
          ],
        ),
      ),
    );
  }
}