import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/database/database.dart';

// more can be added here based on what users want
class Book {
  String? title;
  String? author;
  String? lentDbKey; // stored so that 1.) books are flagged as lent and 2.) books can be mapped to lent books in that part of the database
  bool favorite = false;
  String? coverUrl;
  String? borrowerId;
  String? description;
  String? googleBooksId; // needed for add book duplicate checking only in cases where google books api books dont have title/author (else we can just use those)
  int? bookCondition;
  String? publicBookNotes;
  int? rating;
  bool? hasRead;
  bool isManualAdded; // needed because manually added books should be changable by users
  DateTime? dateLent;
  DateTime? dateToReturn;
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

  void remove() {
    if (lentDbKey != null && borrowerId != null) {
      removeLentBookInfo(lentDbKey!, borrowerId!);
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
      'borrowerId' : borrowerId,
      'bookCondition' : bookCondition,
      'publicBookNotes' : publicBookNotes,
      'rating' : rating,
      'hasRead' : hasRead,
      'dateLent': dateLent?.toIso8601String(),
      'dateToReturn': dateToReturn?.toIso8601String(),
    };
  }

  Image getCoverImage() {
    if (coverUrl != null) {
      return Image(image: CachedNetworkImageProvider(coverUrl!));
      // return Image.network(
      //   coverUrl!,
      //   fit: BoxFit.fill,
      // );
    } else {
      return Image.asset(
        "assets/no_cover.jpg",
        fit: BoxFit.fill,
      );
    }
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
  book.borrowerId = record['borrowerId'];
  book.bookCondition = record['bookCondition'];
  book.publicBookNotes = record['publicBookNotes'];
  book.rating = record['rating'];
  book.hasRead = record['hasRead'];
  book.dateLent = record['dateLent'] != null ? DateTime.parse(record['dateLent']) : null;
  book.dateToReturn = record['dateToReturn'] != null ? DateTime.parse(record['dateToReturn']) : null;
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
  lentBook.book = book;
  lentBook.bookDbKey = record['bookDbKey'];
  return lentBook;
}
