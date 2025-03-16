import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/database/database.dart';
import 'package:shelfswap/ui/shared_widgets.dart';

const int maxApiResponseSize = 40; // currently 40 is the max for google books api. I wouldn't change this value unless google books api increases its max
const int maxLengthForCustomAddedTitleOrAuthor = 80; // arbitrary chosen number, its the max characters for this input
String apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? "";

void addBookToLibrary(Book bookToAdd, User user, BuildContext context, {bool showFeedback = true}) {
  addBook(bookToAdd, user);
  if (showFeedback) {
    SharedWidgets.displayPositiveFeedbackDialog(context, "Book Added");
  }
}
