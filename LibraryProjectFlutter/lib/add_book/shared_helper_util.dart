import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/core/book.dart';
import 'package:library_project/core/database.dart';

class SharedHelperUtil {
  static const String defaultBookCover = "https://lgimages.s3.amazonaws.com/nc-md.gif"; // just some random placeholder img I found
  // its my personal api key, if anyone wants me to use one from shared email i can, i probably should tbh and then just cancel it when we do .env stuff but whatever
  static const String apiKey = "AIzaSyAqHeGVVwSiWJLfVMjF8K5gBbQcNucKuQY";

  static void addBookToLibrary(BuildContext context, Book searchedBook, User user) {

    searchedBook.setId(addBook(searchedBook, user));
    Navigator.pop(context);
  }

  static void addBookToLibraryFromScan(BuildContext context, Book scannedBook, User user) {
    scannedBook.setId(addBook(scannedBook, user));
    Navigator.pop(context);
    // TODO probably for this AND the search maybe consider adding a mechanism to allow for quick scan/search again instead of popping to homepage...
    // idk which would be better though, literally no clue
  }
}
