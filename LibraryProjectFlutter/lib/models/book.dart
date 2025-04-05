import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/add_book/custom_add/book_cover_changers.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/database/database.dart';
import 'package:shelfswap/models/book_requests_model.dart';
import 'package:shelfswap/models/notification.dart';
import 'package:shelfswap/notifications/aws_scheduler_interface.dart';
import 'package:shelfswap/notifications/notification_channel_manager.dart';
import 'package:shelfswap/notifications/send_notifications.dart';

//putting this definition here allows us to not use bools for read state.
enum ReadingState { notRead, currentlyReading, read }
// more can be added here based on what users want
class Book {
  String? title;
  String? author;
  String? lentDbKey; // stored so that 1.) books are flagged as lent and 2.) books can be mapped to lent books in that part of the database
  bool favorite = false;
  String? coverUrl;
  String? cloudCoverUrl; // needed to detect when a book is using our cloud storage to store cover url so it can be deleted as needed
  String? borrowerId;
  String? description;
  String? googleBooksId; // needed for add book duplicate checking only in cases where google books api books dont have title/author (else we can just use those)
  int? isbn13; // stored mainly for goodreads exporting but it can be shown on some pages as well if desired
  String? bookCondition;
  String? bookNotes;
  String? rating;
  String? hasRead;
  bool? isManualAdded; // needed because manually added books should be changable by users
  DateTime? dateLent;
  DateTime? dateToReturn;
  bool? readyToReturn;
  // basically this 1.) stores how many requests this book has and 2.) stores who exactly is requesting it. We need to know who, to delete the
  // request themselves from the database as needed.
  List<String>? usersWhoRequested;
  // storing channel name to easily determine what "lend_receiver_early" notifications we have since those can potentially be
  // adjusted by the receiver
  Map<String, String>? scheduledNotificationNameToChannel;
  late DatabaseReference _id;

  Book(
      {this.title,
      this.author,
      this.coverUrl,
      this.description,
      this.googleBooksId,
      this.isbn13,
      this.isManualAdded = false,
      this.rating = "-",
      this.bookCondition = "-"
      }
  );

  DatabaseReference get id {
    return _id;
  }

  // probably couldve written this better but it works so im not touching it
  // note this isnt a "strictly equal" object checker, its moreso just to check
  // if books are logically same (like same title and author means its the same book)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType || other is! Book) {
      return false;
    }
    if (googleBooksId != null && (googleBooksId == other.googleBooksId)) {
      return true;
    }
    if (isbn13 != null && (isbn13 == other.isbn13)) {
      return true;
    }
    // I want to compare titles and authors as lowercase but I need to make sure nothing is null first
    if (title == null || other.title == null || author == null || other.author == null) {
      return false;
    }
    if (title!.toLowerCase() == other.title!.toLowerCase() && author!.toLowerCase() == other.author!.toLowerCase()) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return Object.hash(googleBooksId, title?.toLowerCase(), author?.toLowerCase());
  }

  void favoriteButtonClicked() {
    favorite = !favorite;
    update();
  }

  void setId(DatabaseReference id) {
    _id = id;
  }

  void update() {
    updateBook(this, _id);
  }
  
  Future<void> remove(String userId) async {
    if (cloudCoverUrl != null) {
      deleteCoverFromStorage(cloudCoverUrl!);
    }
    if (usersWhoRequested != null) {
      for (int i = 0; i < usersWhoRequested!.length; i++) {
        // need to await it to remove all users who requested (removing all received requests is easy, removing all sent not as much)
        await removeBookRequestData(usersWhoRequested![i], userId, _id.key!, removeAllReceivedRequests: true);
      }
    }
    if (scheduledNotificationNameToChannel != null) {
      scheduledNotificationNameToChannel!.forEach((k, v) async {
        await deleteScheduledJob(k);
      });
    }
    removeRef(_id);
  }

  Future<void> setupScheduledLendNotifications(DateTime dateLent, DateTime dateToReturn, String borrowerId, String lenderId) async {
    scheduledNotificationNameToChannel ??= {};
    late String? scheduledJobName;
    late NotificationChannel currentChannel;
    String bookTitle = title ?? "No title found";
    String? lenderName = userIdToUserModel[lenderId]?.name; // TODO check if this actually exists
    String? receiverName = userIdToUserModel[borrowerId]?.name;
    currentChannel = NotificationChannel.lend_receiver_time_to_return;
    NotificationData timeToReturnBook = NotificationData(
      "It's time to return a book",
      "It's time to return the book $bookTitle lent by $lenderName",
      currentChannel,
      borrowerId,
    );
    scheduledJobName = await sendScheduledNotification(timeToReturnBook, dateToReturn);
    if (scheduledJobName != null) {
      scheduledNotificationNameToChannel![scheduledJobName] = currentChannel.name;
    }
    currentChannel = NotificationChannel.lend_sender_did_you_get_book_back;
    NotificationData didYouGetBookBack = NotificationData(
      "Did you get this book back?",
      "The date to return has occured for book $bookTitle lent to $receiverName",
      currentChannel,
      lenderId,
    );
    scheduledJobName = await sendScheduledNotification(didYouGetBookBack, dateToReturn);
    if (scheduledJobName != null) {
      scheduledNotificationNameToChannel![scheduledJobName] = currentChannel.name;
    }
    currentChannel = NotificationChannel.lend_receiver_late;
    NotificationData bookWasDueAWeekAgo = NotificationData(
      "You have an overdue book lent to you",
      "$bookTitle was set to be returned a week ago. Please return it to $lenderName",
      currentChannel,
      borrowerId,
    );
    scheduledJobName = await sendScheduledNotification(bookWasDueAWeekAgo, dateToReturn.add(const Duration(days: 7)));
    if (scheduledJobName != null) {
      scheduledNotificationNameToChannel![scheduledJobName] = currentChannel.name;
    }
    update();
  }

  // note that this function assumes the borrowerId is valid, so this value should be protected before function call
  void lendBook(DateTime dateLent, DateTime dateToReturn, String borrowerId, String lenderId) {
    LentBookInfo lentBookInfo = LentBookInfo(lenderId);
    this.dateLent = dateLent;
    this.dateToReturn = dateToReturn;
    DatabaseReference lentToMeId = addLentBookInfo(_id, lentBookInfo, borrowerId);
    this.borrowerId = borrowerId;
    lentDbKey = lentToMeId.key;
    unsendBookRequest(borrowerId, lenderId);
    update();
    // this intentionally not awaited to show the user instant feedback
    setupScheduledLendNotifications(dateLent, dateToReturn, borrowerId, lenderId);
  }

  void returnBook() {
    // I dont know if this can ever be null, dont think so, but just to be safe I check
    if (lentDbKey != null && borrowerId != null) {
      removeLentBookInfo(lentDbKey!, borrowerId!);
      lentDbKey = null;
      borrowerId = null;
      dateLent = null;
      dateToReturn = null;
      readyToReturn = null;
      if (scheduledNotificationNameToChannel != null) {
        scheduledNotificationNameToChannel!.forEach((key, value) async {
          await deleteScheduledJob(key);
        });
      }
      scheduledNotificationNameToChannel = null;
      update();
    }
  }

  void sendBookRequest(String senderId, String receiverId) {
    if (_id.key != null) {
      DateTime currTime = DateTime.now().toUtc();
      SentBookRequest sentBookRequest = SentBookRequest(receiverId, currTime);
      addSentBookRequest(sentBookRequest, senderId, _id.key!);
      addReceivedBookRequest(senderId, currTime, receiverId, _id.key!);
      usersWhoRequested ??= [];
      if (!usersWhoRequested!.contains(senderId)) {
        usersWhoRequested!.add(senderId);
      }
      update();
    } 
  }

  void unsendBookRequest(String senderId, String receiverId) {
    if (_id.key != null && usersWhoRequested != null && usersWhoRequested!.contains(senderId)) {
      removeBookRequestData(senderId, receiverId, _id.key!);
      usersWhoRequested!.remove(senderId);
      if (usersWhoRequested!.isEmpty) {
        usersWhoRequested = null;
      }
      update();
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, bool>? usersWhoRequestedMap;
    if (usersWhoRequested != null) {
      usersWhoRequestedMap = {for (String e in usersWhoRequested!) e: true};
    }
    return {
      'title': title,
      'author': author,
      'lentDbKey': lentDbKey,
      'favorite': favorite,
      'coverUrl': coverUrl,
      'description': description,
      'googleBooksId': googleBooksId,
      'isbn13': isbn13,
      'isManualAdded': isManualAdded,
      'cloudCoverUrl': cloudCoverUrl,
      'borrowerId' : borrowerId,
      'bookCondition' : bookCondition,
      'publicBookNotes' : bookNotes,
      'rating' : rating,
      'hasRead' : hasRead,
      'dateLent': dateLent?.toIso8601String(),
      'dateToReturn': dateToReturn?.toIso8601String(),
      'readyToReturn': readyToReturn == null ? null : true,
      'usersWhoRequested': usersWhoRequestedMap,
      'scheduledNotificationNames': scheduledNotificationNameToChannel,
    };
  }

  Image getCoverImage() {
    if (cloudCoverUrl != null) {
      return Image(image: CachedNetworkImageProvider(cloudCoverUrl!));
    }
    else if (coverUrl != null) {
      return Image(image: CachedNetworkImageProvider(coverUrl!));
    } else {
      return Image.asset(
        "assets/no_cover.jpg",
        fit: BoxFit.fill,
      );
    }
  }

    void updateReadingState(String? newState) {
    hasRead = newState;
    update();
  }
}

Book createBookFromJson(record) {
  Book book = Book(
    title: record['title'],
    author: record['author'],
    coverUrl: record['coverUrl'],
    description: record['description'],
    googleBooksId: record['googleBooksId'],
    isbn13: record['isbn13'],
    isManualAdded: record['isManualAdded'],
  );
  book.lentDbKey = record['lentDbKey'];
  book.favorite = record['favorite'];
  book.cloudCoverUrl = record['cloudCoverUrl'];
  book.borrowerId = record['borrowerId'];
  book.bookCondition = record['bookCondition'];
  book.bookNotes = record['publicBookNotes'];
  book.rating = record['rating'];
  book.hasRead = record['hasRead'];
  book.dateLent = record['dateLent'] != null ? DateTime.parse(record['dateLent']) : null;
  book.dateToReturn = record['dateToReturn'] != null ? DateTime.parse(record['dateToReturn']) : null;
  book.readyToReturn = record['readyToReturn'];
  // now fetching users who requested, stored as a list kinda but with indicies in the database (it seems everything is stored as map so the keys are 0, 1, etc.)
  if (record['usersWhoRequested'] != null) {
    book.usersWhoRequested ??= [];
    dynamic usersWhoRequestedInDb = record['usersWhoRequested'];
    usersWhoRequestedInDb.forEach((k, v) {
      book.usersWhoRequested!.add(k);
    });
  }
  book.scheduledNotificationNameToChannel = (record['scheduledNotificationNames'] as Map?)?.map(
    (key, value) => MapEntry(key.toString(), value.toString()),
  );
  // book.scheduledNotificationNameToChannel = record['scheduledNotificationNames'];
  return book;
}

class LentBookInfo {
  String? bookDbKey;
  String? lenderId;
  late Book book;
  // not storing id because to my knowledge its not needed since I delete this object's db records through the book object

  LentBookInfo(this.lenderId);

  Map<String, dynamic> toJson(String bookDbKey) {
    return {
      'bookDbKey': bookDbKey,
      'lenderId' : lenderId,
    };
  }
}

LentBookInfo createLentBookInfo(Book book, dynamic record) {
  String? lenderId = record['lenderId'];
  LentBookInfo lentBook = LentBookInfo(lenderId);
  lentBook.bookDbKey = record['bookDbKey'];
  lentBook.book = book;
  return lentBook;
}
