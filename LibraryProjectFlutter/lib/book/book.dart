import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/database/database.dart';

// more can be added here based on what users want
class Book {
  String? title;
  String? author;
  String? lentDbPath; // stored so that 1.) books are flagged as lent and 2.) books can be mapped to lent books in that part of the database
  bool favorite = false;
  String? coverUrl;
  // if custom book add will have custom images (as it should) needs to be stored somewhere, with link to it, but can also be stored in temp for optimization
  // in this case, would it require 2 things? Ahhhh...
  //String? coverPath;
  String? description;
  String? googleBooksId;
  int? bookCondition;
  String? publicBookNotes;
  int? rating;
  bool? hasRead;
  bool isManualAdded; // needed because manually added books should be changable by users
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

  void remove(String uid) {
    if (lentDbPath != null) {
      removeLentBookInfo(lentDbPath!);
    }
    removeRef(_id);
  }

  // note that this function assumes the borrowerId is valid, so this value should be protected before function call
  void lendBook(DateTime dateLent, DateTime dateToReturn, String borrowerId, String lenderId) {
    LentBookInfo lentBookInfo = LentBookInfo(dateLent, dateToReturn, borrowerId, lenderId);
    DatabaseReference lentToMeId = addLentBookInfo(_id, lentBookInfo, borrowerId);
    lentDbPath = lentToMeId.path;
    update();
  }

  void returnBook() {
    // I dont know if this can ever be null, dont think so, but just to be safe I check
    if (lentDbPath != null) {
      removeLentBookInfo(lentDbPath!);
      lentDbPath = null;
      update();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'lentDbPath': lentDbPath,
      'favorite': favorite,
      'coverUrl': coverUrl,
      'description': description,
      'googleBooksId': googleBooksId,
      'isManualAdded': isManualAdded,
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
  book.lentDbPath = record['lentDbPath'];
  book.favorite = record['favorite'];

  return book;
}

class LentBookInfo {
  String? bookDbPath;
  DateTime? dateLent;
  DateTime? dateToReturn;
  String? borrowerId;
  String? lenderId;
  late Book book;
  // not storing id because to my knowledge (which may be wrong) its not needed since I delete this object's db records through the book object

  LentBookInfo(this.dateLent, this.dateToReturn, this.borrowerId, this.lenderId);

  Map<String, dynamic> toJson(String bookDbPath) {
    return {
      'bookDbPath': bookDbPath,
      'dateLent': dateLent?.toIso8601String(),
      'dateToReturn': dateToReturn?.toIso8601String(),
      'borrowerId': borrowerId,
      'lenderId' : lenderId,
    };
  }
}

LentBookInfo createLentBookInfo(Book book, dynamic record) {
  DateTime? dateLent = record['dateLent'] != null ? DateTime.parse(record['dateLent']) : null;
  DateTime? dateToReturn = record['dateToReturn'] != null ? DateTime.parse(record['dateToReturn']) : null;
  String? borrowerId = record['borrowerId'];
  String? lenderId = record['lenderId'];
  LentBookInfo lentBook = LentBookInfo(dateLent, dateToReturn, borrowerId, lenderId);
  lentBook.book = book;
  lentBook.bookDbPath = record['bookDbPath'];
  return lentBook;
}
