import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'dart:typed_data';
import 'dart:convert';

Future<void> tryGoodreadsExport(BuildContext context) async {
  List<Book> booksToExport = [];
  int numBooksUserCantExport = 0;
  for (int i = 0; i < userLibrary.length; i++) {
    // trusting userLibrary duplicate checking and isbn validation here
    if (userLibrary[i].isbn13 != null) {
      booksToExport.add(userLibrary[i]);
    }
    else {
      numBooksUserCantExport++;
    }
  }
  if (userLibrary.isEmpty) {
    SharedWidgets.displayErrorDialog(context, "You have no books to export");
    return;
  }
  if (booksToExport.isEmpty) {
    SharedWidgets.displayErrorDialog(context, "You have no valid books to export. Exporting a book requires an ISBN in our databases, your books do not have this.");
    return;
  }
  String warningText = "";
  if (numBooksUserCantExport == 0) {
    warningText = "Are you sure you want to export ${booksToExport.length} books? This is all of your books.";
  }
  else {
    // TODO should better handle the books which cant be exported? Specify? No clue how this would be but obviously it should exist
    warningText = "$numBooksUserCantExport could not be exported due to not having an ISBN in our databases. Are you sure you want to export ${booksToExport.length} books still?";
  }
  bool shouldExport = await SharedWidgets.displayConfirmActionDialog(context, warningText);
  if (!shouldExport) {
    return;
  }
  String fileContents = "ISBN13\n";
  for (Book book in booksToExport) {
    fileContents += "${book.isbn13}\n";
  }

  try {
    Uint8List fileContentsAsBytes = utf8.encode(fileContents);
    DateTime currTime = DateTime.now().toUtc();
    String time = DateFormat.yMd().format(currTime.toLocal());
    String? filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'save this shelfswap export file',
      fileName: 'shelfswap_export_$time.csv',
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv', 'xls'], // this just doesnt work :(
      bytes: fileContentsAsBytes,
    );

    if (filePath != null) {
      if (context.mounted) {
        SharedWidgets.displayPositiveFeedbackDialog(context, "File Saved Successfully");
      }
    }
  } catch (e) {
    if (context.mounted) {
      SharedWidgets.displayErrorDialog(context, "Error saving file");
    }
  }
}
