import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/ui/shared_widgets.dart';

// TODO .env and use shared api key instead then cancel this one
const String apiKey = "AIzaSyAqHeGVVwSiWJLfVMjF8K5gBbQcNucKuQY";
const int maxApiResponseSize = 40; // currently 40 is the max for google books api. I wouldn't change this value unless google books api increases its max

Future<void> addBookToLibrary(Book bookToAdd, User user, List<Book> userLibrary, BuildContext context) async {
  bookToAdd.setId(addBook(bookToAdd, user));
  userLibrary.add(bookToAdd);
  SharedWidgets.displayPositiveFeedbackDialog(context, "Book added");
}

bool areBooksSame(Book? book1, Book? book2) {
  if (book1 == null || book2 == null) { // if any books are null then they definitely wouldnt be the same ya feel me?
    return false;
  }
  if (book1.googleBooksId != null && (book1.googleBooksId == book2.googleBooksId)) {
    return true;
  }
  // I want to compare titles and authors as lowercase but I need to make sure nothing is null first
  if (book1.title == null || book2.title == null || book1.author == null || book2.author == null) {
    return false;
  }
  if (book1.title!.toLowerCase() == book2.title!.toLowerCase() && book1.author!.toLowerCase() == book2.author!.toLowerCase()) {
    return true;
  }
  return false;
}
