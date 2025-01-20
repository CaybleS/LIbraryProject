import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/ui/shared_widgets.dart';

const int maxApiResponseSize = 40; // currently 40 is the max for google books api. I wouldn't change this value unless google books api increases its max
const String apiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

void addBookToLibrary(Book bookToAdd, User user, BuildContext context) {
  bookToAdd.setId(addBook(bookToAdd, user));
  SharedWidgets.displayPositiveFeedbackDialog(context, "Book added");
}
