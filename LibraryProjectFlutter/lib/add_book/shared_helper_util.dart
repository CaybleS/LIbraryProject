import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/ui/shared_widgets.dart';

// TODO .env and use shared api key instead then cancel this one
const String apiKey = "AIzaSyAqHeGVVwSiWJLfVMjF8K5gBbQcNucKuQY";
const int maxApiResponseSize = 40; // currently 40 is the max for google books api. I wouldn't change this value unless google books api increases its max

void addBookToLibrary(Book bookToAdd, User user, BuildContext context) {
  bookToAdd.setId(addBook(bookToAdd, user));
  SharedWidgets.displayPositiveFeedbackDialog(context, "Book added");
}
