import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/models/notification.dart';
import 'package:shelfswap/notifications/notification_channel_manager.dart';
import 'package:shelfswap/notifications/send_notifications.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'dart:math';

class FriendBookPage extends StatefulWidget {

  @override
  State<FriendBookPage> createState() => _FriendBookPageState();
  final User user;
  final Book bookToView;
  final String friendId;
  final bool viewingFromSentRequest;
  final bool viewingFromLentToMe;
  const FriendBookPage(this.user, this.bookToView, this.friendId, {this.viewingFromSentRequest = false, this.viewingFromLentToMe = false, super.key});
}

class _FriendBookPageState extends State<FriendBookPage> {
  late Book _friendsLibraryBook;
  late final VoidCallback _booksLentToMeUpdatedListener; // p sure its just for the thing that shows if its "lent" or "available"
  late final VoidCallback _friendsBooksUpdatedListener;
  final _daysBeforeToNotifyController = TextEditingController();
  bool? _earlyNotificationSet;

  @override
  void initState() {
    super.initState();
    _friendsLibraryBook = widget.bookToView;
    _checkIfLendReceiverEarlyNotificationIsSet();
    setState(() {});
    _booksLentToMeUpdatedListener = () {
      setState(() {});
    };
    _friendsBooksUpdatedListener = () {
      List<Book> friendsLibrary = [];
      if (widget.viewingFromSentRequest) {
        // creating a list of all books derived from all sent book requests sent to this friend
        friendsLibrary = sentBookRequests.values.where((item) => item.receiverId == widget.friendId).map((item) => item.book).toList();
      }
      else if (widget.viewingFromLentToMe) {
        friendsLibrary = booksLentToMe.values.where((item) => item.lenderId == widget.friendId).map((item) => item.book).toList();
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
        _checkIfLendReceiverEarlyNotificationIsSet();
      }
    };
    pageDataUpdatedNotifier.addListener(_booksLentToMeUpdatedListener);
    pageDataUpdatedNotifier.addListener(_friendsBooksUpdatedListener);
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_booksLentToMeUpdatedListener);
    pageDataUpdatedNotifier.removeListener(_friendsBooksUpdatedListener);
    _daysBeforeToNotifyController.dispose();
    super.dispose();
  }

  // its intended to be some user input way to specify when you want to get notified prior to a book return date
  // currently only supports 1 user input and that input cannot be edited as well
  void _checkIfLendReceiverEarlyNotificationIsSet() {
    _earlyNotificationSet = false;
    if (_friendsLibraryBook.scheduledNotificationNameToChannel != null) {
      _friendsLibraryBook.scheduledNotificationNameToChannel!.forEach((key, value) async {
        if (value == NotificationChannel.lend_receiver_early.name) {
          _earlyNotificationSet = true;
        }
      });
    }
    setState(() {});
  }

  Widget _displayStatus() {
    String availableTxt;
    Color availableTxtColor;

    if (_friendsLibraryBook.lentDbKey != null) {
      availableTxtColor = Colors.red;
      if (_isBookAlreadyLentToUser()) {
        DateTime currentTime = DateTime.now().toUtc();
        Duration daysUntilDueDate = _friendsLibraryBook.dateToReturn!.difference(currentTime);
        int daysUntilDueDateInt = daysUntilDueDate.inDays;
        if (daysUntilDueDateInt < 0) {
          if (daysUntilDueDateInt.abs() == 1) {
            availableTxt = "Lent to you\nDue ${daysUntilDueDateInt.abs()} day ago, on ${DateFormat.yMd().format(_friendsLibraryBook.dateToReturn!)}";
          }
          else {
            availableTxt = "Lent to you\nDue ${daysUntilDueDateInt.abs()} days ago, on ${DateFormat.yMd().format(_friendsLibraryBook.dateToReturn!)}";
          }
        } 
        else if (daysUntilDueDateInt == 0) {
          availableTxt = "Lent to you\nDue today";
        }
        else {
          if (daysUntilDueDateInt == 1) {
            availableTxt = "Lent to you\nDue in $daysUntilDueDateInt day, on ${DateFormat.yMd().format(_friendsLibraryBook.dateToReturn!)}";
          }
          else {
            availableTxt = "Lent to you\nDue in $daysUntilDueDateInt days, on ${DateFormat.yMd().format(_friendsLibraryBook.dateToReturn!)}";
          }
        }
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
      textAlign: TextAlign.center,
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
            ((_friendsLibraryBook.usersWhoRequested?.length ?? 0) == 1)
              // note there is no situation where there would be 0 requests for it, if there was I'd show "no requests for this book"
              // but if theres no requests you would just see the "request book button" not this
              ? "This book has 1 request for it"
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
        NotificationData notificationData = NotificationData(
          "You have a new book request",
          "Your book ${_friendsLibraryBook.title ?? "No title found"} has been requested",
          NotificationChannel.incoming_book_request,
          widget.friendId,
        );
        await sendNotification(notificationData);
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

  // only called if the book is lent to you and the book is not overdue
  Widget _displayEarlyReturnNotifierSpecifier() {
    if (_earlyNotificationSet == true) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Flexible(
            child: Text("You are set to get notified early"),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8),
            ),
            onPressed: () {
              if (_friendsLibraryBook.scheduledNotificationNameToChannel != null) {
                String? jobName;
                _friendsLibraryBook.scheduledNotificationNameToChannel!.forEach((key, value) async {
                  if (value == NotificationChannel.lend_receiver_early.name) {
                    jobName = key;
                    deleteScheduledNotification(jobName!);
                    return; // this only returns from the forEach btw not the onPressed
                  }
                });
                if (jobName != null) {
                  _friendsLibraryBook.scheduledNotificationNameToChannel!.remove(jobName);
                  _friendsLibraryBook.update();
                }
              }
            },
            child: const Text(
              "Undo",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        const SizedBox(height: 15),
        const Text("Do you want to get notified early?"),
        const SizedBox(height: 6),
        Flexible(
          child: SizedBox(
            width: 200,
            child: TextField(
              controller: _daysBeforeToNotifyController,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Days before due date",
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
                //errorText: _getInputTitleError(),
                suffixIcon: IconButton(
                onPressed: () {
                  _daysBeforeToNotifyController.clear();
                },
                icon: const Icon(Icons.clear),
                ),
              ),
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
          ),
        ),
        const SizedBox(height: 5),
        ElevatedButton(
          onPressed: () async {
            String textInput = _daysBeforeToNotifyController.text;
            if (textInput.isEmpty) {
              return;
            }
            int? textAsInt = int.tryParse(textInput);
            if (textAsInt == null) {
              SharedWidgets.displayErrorDialog(context, "Invalid input"); // this occurs with int overflow it seems
              return;
            }
            if (textAsInt <= 0) {
              SharedWidgets.displayErrorDialog(context, "Enter a valid number of days before the return date");
              return;
            }
            if (textAsInt > 100) {
              SharedWidgets.displayErrorDialog(context, "You cannot specify a date like this");
              return;
            }
            Duration daysUntilDueDate = _friendsLibraryBook.dateToReturn!.difference(DateTime.now().toUtc());
            int daysUntilDueDateInt = daysUntilDueDate.inDays;
            if (textAsInt > daysUntilDueDateInt) {
              SharedWidgets.displayErrorDialog(context, "This book is flagged to be returned in $daysUntilDueDateInt days, so you cannot schedule an early reminder past that");
              return;
            }
            else if (textAsInt == daysUntilDueDateInt) {
              SharedWidgets.displayErrorDialog(context, "This book is flagged to be returned in $textAsInt days already, so you will already be notified at that time");
              return;
            }
            String bookTitle = "No title found";
            if (widget.bookToView.title != null) {
              bookTitle = widget.bookToView.title!.substring(0, min(widget.bookToView.title!.length, 40));
            }
            String lenderName = userIdToUserModel[widget.friendId]!.name;
            DateTime notificationDate = widget.bookToView.dateToReturn!.subtract(Duration(days: int.parse(textInput)));
            int numDaysBeforeDueDateToBeNotified = widget.bookToView.dateToReturn!.difference(notificationDate).inDays;
            NotificationChannel currentChannel = NotificationChannel.lend_receiver_early;
            NotificationData timeToReturnBookSoonNotification = NotificationData(
              "It's time to return a book soon",
              "The book $bookTitle, lent by $lenderName was flagged to be returned in $numDaysBeforeDueDateToBeNotified days",
              currentChannel,
              widget.user.uid,
            );
            String whenToNotify = numDaysBeforeDueDateToBeNotified == 1 ? "$numDaysBeforeDueDateToBeNotified day" : "$numDaysBeforeDueDateToBeNotified days";
            bool shouldContinue = await SharedWidgets.displayConfirmActionDialog(
              context, "Are you sure you want to be notified $whenToNotify before this book is due, on ${DateFormat.yMd().format(_friendsLibraryBook.dateToReturn!.subtract(Duration(days: textAsInt)))}");
            if (!shouldContinue) {
              return;
            }
            String? scheduledJobName = await sendScheduledNotification(timeToReturnBookSoonNotification, notificationDate, widget.user.uid, widget.bookToView.id.key!);
            if (scheduledJobName != null) {
              widget.bookToView.scheduledNotificationNameToChannel ??= {};
              widget.bookToView.scheduledNotificationNameToChannel![scheduledJobName] = currentChannel.name;
              widget.bookToView.update();
            }
            setState(() {});
            if (mounted) {
              SharedWidgets.displayPositiveFeedbackDialog(context, "Notification Scheduled");
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.skyBlue,
            padding: const EdgeInsets.all(8),
          ),
          child: const Text(
            "Add a notification at this time",
            style: TextStyle(fontSize: 16, color: Colors.black)
          ),
        ),
      ],
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
            (widget.bookToView.borrowerId == widget.user.uid && _friendsLibraryBook.dateToReturn!.difference(DateTime.now().toUtc()).inDays > 0)
            ? Flexible( 
                flex: 2,
                child: _displayEarlyReturnNotifierSpecifier(),
              )
            : const SizedBox.shrink(),
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