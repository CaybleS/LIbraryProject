import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book/custom_add/book_cover_changers.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/book_requests.dart';

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
  int? bookCondition;
  String? publicBookNotes;
  int? rating;
  ReadingState? hasRead;
  bool isManualAdded; // needed because manually added books should be changable by users
  DateTime? dateLent;
  DateTime? dateToReturn;
  // basically this 1.) stores how many requests this book has and 2.) stores who exactly is requesting it. We need to know who, to delete the
  // request themselves from the database as needed.
  List<String>? usersWhoRequested;
  late DatabaseReference _id;

  Book(
      {this.title,
      this.author,
      this.coverUrl,
      this.description,
      this.googleBooksId,
      this.isManualAdded = false}
  );

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
    if (lentDbKey != null && borrowerId != null) {
      removeLentBookInfo(lentDbKey!, borrowerId!);
    }
    if (cloudCoverUrl != null) {
      deleteCoverFromStorage(cloudCoverUrl!);
    }
    if (usersWhoRequested != null) {
      for (int i = 0; i < usersWhoRequested!.length; i++) {
        await removeBookRequestData(usersWhoRequested![i], userId, _id.key!, removeAllReceivedRequests: true);
      }
    }
    removeRef(_id);
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
  }

  void returnBook() {
    // I dont know if this can ever be null, dont think so, but just to be safe I check
    if (lentDbKey != null && borrowerId != null) {
      removeLentBookInfo(lentDbKey!, borrowerId!);
      lentDbKey = null;
      borrowerId = null;
      dateLent = null;
      dateToReturn = null;
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
    return {
      'title': title,
      'author': author,
      'lentDbKey': lentDbKey,
      'favorite': favorite,
      'coverUrl': coverUrl,
      'description': description,
      'googleBooksId': googleBooksId,
      'isManualAdded': isManualAdded,
      'cloudCoverUrl': cloudCoverUrl,
      'borrowerId' : borrowerId,
      'bookCondition' : bookCondition,
      'publicBookNotes' : publicBookNotes,
      'rating' : rating,
      'hasRead' : hasRead,
      'dateLent': dateLent?.toIso8601String(),
      'dateToReturn': dateToReturn?.toIso8601String(),
      'usersWhoRequested': usersWhoRequested,
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

    void updateReadingState(ReadingState? newState) {
    hasRead = newState;
    update();
  }
}

Book createBook(record) {
  Book book = Book(
    title: record['title'],
    author: record['author'],
    coverUrl: record['coverUrl'],
    description: record['description'],
    googleBooksId: record['googleBooksId'],
    isManualAdded: record['isManualAdded'],
  );
  book.lentDbKey = record['lentDbKey'];
  book.favorite = record['favorite'];
  book.cloudCoverUrl = record['cloudCoverUrl'];
  book.borrowerId = record['borrowerId'];
  book.bookCondition = record['bookCondition'];
  book.publicBookNotes = record['publicBookNotes'];
  book.rating = record['rating'];
  book.hasRead = record['hasRead'];
  book.dateLent = record['dateLent'] != null ? DateTime.parse(record['dateLent']) : null;
  book.dateToReturn = record['dateToReturn'] != null ? DateTime.parse(record['dateToReturn']) : null;
  // now fetching users who requested, stored as a list kinda but with indicies in the database (it seems everything is stored as map so the keys are 0, 1, etc.)
  if (record['usersWhoRequested'] != null) {
    book.usersWhoRequested ??= [];
    dynamic usersWhoRequestedInDb = record['usersWhoRequested'];
    for (dynamic userId in usersWhoRequestedInDb) {
      book.usersWhoRequested!.add(userId);
    }
  }
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
