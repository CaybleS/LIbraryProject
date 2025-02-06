import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart'; // literally only needed to convert exported goodreads csv to a list, but thats kinda helpful ya know
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'dart:convert';
import 'package:library_project/models/book.dart';
import 'package:library_project/ui/shared_widgets.dart';

Future<Stream<List<int>>?> _pickSingleFile(BuildContext context) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withReadStream: true,
      type: FileType.any,
      //allowedExtensions: ["csv"], seems to just not work :( its meant to ONLY allow users to pick csv files but it just doesnt let them pick anything at all
    );
    if (result == null || result.files.first.extension != "csv" || !context.mounted) {
      return null;
    }
    Stream<List<int>>? fileReadStream = result.files.single.readStream;
    return fileReadStream;
  } catch (e) {
    return null;
  }
}

Future<List<Book>> _getBooks(Stream<List<int>> fileReadStream) async{
  List<List<dynamic>> data = await fileReadStream.transform(utf8.decoder).transform(const CsvToListConverter(eol: "\n", fieldDelimiter: ",")).toList(); 
  List<Book> importedBooks = [];
  List<String> importedISBNs = [];
  for (int i = 1; i < data.length; i++) { // starting at i = 1 since first line of the csv is a "show the format" line
    // note the toString() conversions are essential since numbers are sometimes int datatype and sometimes string datatype it seems
    Book book = Book(title: data[i][1].toString(), author: data[i][2].toString());
    if (book.title == "") {
      book.title = null;
    }
    if (book.author == "") {
      book.author = null;
    }
    String currIsbn = data[i][4].toString();
    importedBooks.add(book);
    importedISBNs.add(currIsbn);
  }
  return importedBooks;
}

Future<void> tryGoodreadsImport(User user, BuildContext context) async {
  Stream<List<int>>? fileReadStream = await _pickSingleFile(context);
  if (fileReadStream == null) {
    return;
  }
  List<Book> importedBooks = await _getBooks(fileReadStream);
  if (context.mounted) {
    bool bookAlreadyOwned = false;
    bool anyBookAdded = false;
    int numBooksAlreadyOwned = 0;
    for (int i = 0; i < importedBooks.length; i++) {
      bookAlreadyOwned = false;
      for (int j = 0; j < userLibrary.length; j++) {
        if (importedBooks[i] == userLibrary[j]) {
          bookAlreadyOwned = true;
          numBooksAlreadyOwned++;
        }
      }
      if (!bookAlreadyOwned) {
        anyBookAdded = true;
        addBookToLibrary(importedBooks[i], user, context, showFeedback: false);
      }
    }
    if (anyBookAdded) {
      String feedbackMsg = "Books Imported";
      if (numBooksAlreadyOwned > 0) {
        feedbackMsg = "Imported! ($numBooksAlreadyOwned skipped)";
      }
      SharedWidgets.displayPositiveFeedbackDialog(context, feedbackMsg);
    }
    else if (importedBooks.isEmpty) {
      SharedWidgets.displayErrorDialog(context, "No books found in that file.");
    } else {
        SharedWidgets.displayErrorDialog(context, "No books imported, you already added all of those!");
    }
  }
}