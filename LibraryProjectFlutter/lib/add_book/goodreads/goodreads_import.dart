import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart'; // literally only needed to convert exported goodreads csv to a list, but thats kinda helpful ya know
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/core/global_variables.dart';
import 'dart:convert';
import 'package:library_project/models/book.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

ValueNotifier<String> _dynamicBottombarText = ValueNotifier<String>("");
bool _snackbarVisible = false;

Future<List<List<dynamic>>?> _pickCsvFile(BuildContext context) async {
  try {
    // this does some caching stuff, but it handles it all internally, I'd say don't mess with it
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withReadStream: true,
      type: FileType.any, // TODO letting people cache any file size is kind of concerning but no idea how to fix this problem .. 
      //allowedExtensions: ["csv"], seems to just not work :( its meant to ONLY allow users to pick csv files but it just doesnt let them pick anything at all
    );
    if (result == null || !context.mounted) {
      return null;
    }
    if (result.files.first.extension != "csv") {
      SharedWidgets.displayErrorDialog(context, "Please select a valid CSV goodreads export file (file extension .csv)");
    }
    Stream<List<int>>? fileReadStream = result.files.single.readStream;
    if (fileReadStream != null) {
      List<List<dynamic>> data = await fileReadStream.transform(utf8.decoder).transform(const CsvToListConverter(eol: "\n", fieldDelimiter: ",")).toList();
      return data;
    }
    return null;
  } catch (e) {
    return null;
  }
}

bool _isCsvValid(List<List<dynamic>> fileInListFormat) {
  try {
    if (fileInListFormat[0][1] == "Title"
    && fileInListFormat[0][2] == "Author"
    && fileInListFormat[0][6] == "ISBN13") {
      return true;
    }
  } catch (_) { // this shold deal with empty lists of some kind
    return false;
  }
  return false;
}

// http request to ensure that openlibrary actually has this book cover (its slow unfortunately but it must be done)
Future<bool> _doesOpenLibraryHaveThisCover(String coverUrl) async {
  try {
    final response = await http.get(Uri.parse(coverUrl)).timeout(
      const Duration(seconds: 8), // untested arbitrary number
      onTimeout: () {
        throw "Timeout";
      },
    );
    if (response.statusCode != 200) {
      return false;
    }
  } catch (e) {
    return false; // caused by timeout and maybe other stuff too idk
  }
  return true;
}

void _showImportingSnackbar(BuildContext context, int numBooksImportedSoFar) {
  _dynamicBottombarText.value = "Importing... You have added ${numBooksImportedSoFar.toString()} books so far!";
  if (!_snackbarVisible) {
    _snackbarVisible = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ImportSnackbarText(_dynamicBottombarText),
        duration: const Duration(days: 365), // arbitrary "infinite" time
      ),
    );
  }
}

void _dismissImportingSnackbar(BuildContext context) {
  _dynamicBottombarText.value = "";
  if (_snackbarVisible) {
    _snackbarVisible = false;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}

Future<void> _importBooks(List<List<dynamic>> fileInListFormat, User user, BuildContext context) async {
  bool bookAlreadyOwned = false;
  bool anyBookAdded = false;
  int numBooksAlreadyOwned = 0;
  int numImportedSoFar = 0;
  // its really not needed this try block but im just being safe, in case something goes wrong, it guarantees the snackbar will be dismissed
  try {
    for (int i = 1; i < fileInListFormat.length; i++) { // starting at i = 1 since first line of the csv is a "show the format" line
      String parsedIsbn = fileInListFormat[i][6].toString();
      String actualIsbn = "";
      // this just ensures the ISBN is only integers, needed since it was parsed with extra characters.
      for (int j = 0; j < parsedIsbn.length; j++) {
        switch (parsedIsbn[j]) {
          case "0":
          case "1":
          case "2":
          case "3":
          case "4":
          case "5":
          case "6":
          case "7":
          case "8":
          case "9":
            actualIsbn += parsedIsbn[j];
            break;
        }
      }
      // note the toString() conversions are essential since numbers are sometimes int datatype and sometimes string datatype it seems.
      // I would guess this is a thing with the dynamic data type, just keep it to be safe I'd say.
      Book book = Book(title: fileInListFormat[i][1].toString(), author: fileInListFormat[i][2].toString(), isbn13: int.tryParse(actualIsbn)); // can be "" so tryParse is needed
      if (book.title == "") {
        book.title = null;
      }
      if (book.author == "") {
        book.author = null;
      }
      if (actualIsbn.length != 13) { // idk if this is needed im just being safe
        book.isbn13 = null;
      }
      bookAlreadyOwned = false;
      for (int i = 0; i < userLibrary.length; i++) {
        if (book == userLibrary[i]) {
          bookAlreadyOwned = true;
          numBooksAlreadyOwned++;
        }
      }
      if (!bookAlreadyOwned) {
        anyBookAdded = true;
        // getting cover url here, after we confirm we dont already own the book
        // seems openlibrary just has a covers api where you can convert any ISBN to a cover image
        String? coverUrl = "https://covers.openlibrary.org/b/isbn/$actualIsbn-M.jpg?default=false";
        if (!await _doesOpenLibraryHaveThisCover(coverUrl)) {
          coverUrl = null;
        }
        // that part of the cover url was just to check if openlibrary actually stores that book cover, we dont need to store it in our db
        coverUrl = coverUrl?.replaceAll(RegExp(r'\?default=false'), "");
        book.coverUrl = coverUrl;
        if (context.mounted) {
          addBookToLibrary(book, user, context, showFeedback: false);
          numImportedSoFar++;
          _showImportingSnackbar(context, numImportedSoFar);
        }
      }
    }
    if (anyBookAdded) {
      String feedbackMsg = "Books Imported";
      if (numBooksAlreadyOwned > 0) {
        feedbackMsg = "$numImportedSoFar Imported! ($numBooksAlreadyOwned skipped)";
      }
      if (context.mounted) {
        SharedWidgets.displayPositiveFeedbackDialog(context, feedbackMsg);
      }
    } else {
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, "No books imported, you already added all of those!");
      }
    }
  } catch (_) {}
  finally {
    if (context.mounted) {
      // need to dismiss, or try to dismiss, this no matter what when this function finishes, even in the case where some freaky error happens
      _dismissImportingSnackbar(context);
    }
  }
}

Future<void> tryGoodreadsImport(User user, BuildContext context) async {
  List<List<dynamic>>? fileInListFormat = await _pickCsvFile(context);
  if (fileInListFormat == null) {
    return;
  }
  if (!_isCsvValid(fileInListFormat) && context.mounted) {
    SharedWidgets.displayErrorDialog(context, "Your file header is not an expected goodreads header. Please ensure you didn't modify it.");
    return;
  }
  // at this point all the errors have mostly been caught and we can safely use the file in list format to get the books
  if (context.mounted) {
    await _importBooks(fileInListFormat, user, context);
  }
}

class ImportSnackbarText extends StatelessWidget {
  final ValueNotifier<String> snackMsg;

  const ImportSnackbarText(this.snackMsg, {super.key});

  @override
  Widget build(BuildContext context) {
    // me when i copy paste code.. but it has good comments !! :D
    // ValueListenableBuilder rebuilds whenever snackMsg value changes.
    // i.e. this "listens" to changes of ValueNotifier "snackMsg".
    // "msg" in builder below is the value of "snackMsg" ValueNotifier.
    // We don't use the other builder args for this example so they are
    // set to _ & __ just for readability.
    return ValueListenableBuilder<String>(
        valueListenable: snackMsg,
        builder: (_, msg, __) => Text(msg));
  }
}
