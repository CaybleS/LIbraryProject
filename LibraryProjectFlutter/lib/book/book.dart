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
  // if custom book add will have custom images (as it should) needs to be stored somewhere, with link to it. This is what coverPath is intended to be, whenever thats implemented.
  //String? coverPath;
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
      this.isManualAdded = false});

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

  // maybe this should be in a more UI-related file, I think its fine tho
  Image getCoverImage() {
    // if (coverPath != null) {
    //   return Image.asset(
    //     coverPath!,
    //     fit: BoxFit.fill,
    //   );
    // }
    if (coverUrl != null) {
      // it was else if before but I don't see how I can use coverPath, idk how i'll do it honestly
      return Image.network(
        coverUrl!,
        fit: BoxFit.fill,
      );
    } else {
      return Image.asset(
        "assets/no_cover.jpg".toString(),
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
