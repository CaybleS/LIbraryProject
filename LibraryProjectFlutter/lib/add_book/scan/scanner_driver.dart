import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:library_project/core/global_variables.dart';
import 'dart:convert';
import 'package:library_project/models/book.dart';
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/add_book/scan/scanner_screen.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';

class ScannerDriver {
  bool _otherSearchError = false;
  bool _noBooksFoundError = false; // this only occurs if no results occur from the successful (200) search query, implying that the scanned ISBN is wrong (likely due to bad barcode)
  bool _cameraSetupError = false;
  bool _noResponseError = false; // this detects lack of internet connection (or api being down maybe)
  bool _invalidISBNError = false;
  bool _invalidBarcodePhotoError = false;
  bool _unknownScannerScreenError = false; // no idea what would trigger this, its a mystery to me (unknown)
  Book? bookFromISBNScan;
  late final User _user;
  late final List<Book> userLibrary;

  ScannerDriver(this._user, this.userLibrary);

  Future<String?> runScanner(BuildContext context) async {
    _resetLastScanValues();
    String? scannedISBN = await _openBarcodeScanner(context);
    if (scannedISBN == "Camera access denied. Please enable it in your device settings.") {
      scannedISBN = null;
      _cameraSetupError = true;
    }
    if (scannedISBN == "No barcode found on image.") {
      scannedISBN = null;
      _invalidBarcodePhotoError = true;
    }
    if (scannedISBN == "An unexpected error occurred. Please try again later.") {
      scannedISBN = null;
      _unknownScannerScreenError = true;
    }
    // All ISBNs are expected to be length 13 (isbn10 barcodes don't exist as far as I know; if old books have a barcode on them its a UPC), so I just check for that length
    if (scannedISBN != null && (scannedISBN.length != 13 || !_isValidCheckDigit(scannedISBN))) {
      _invalidISBNError = true;
    }
    if (_cameraSetupError || _invalidISBNError || _invalidBarcodePhotoError || _unknownScannerScreenError) {
      String errorMessage = _getScanFailMessage();
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, errorMessage);
      }
      return null;
    }
    if (scannedISBN == null) {
      return null;
    }
    return scannedISBN;
  }

  Future<void> scannerSearchByIsbn(BuildContext context, String scannedISBN) async {
    await _isbnSearchWithGoogle(scannedISBN);
    if (bookFromISBNScan == null) {
      _noBooksFoundError = true;
    }
    String errorMessage = _getScanFailMessage();
    if (context.mounted) {
      if (errorMessage.isNotEmpty) {
        SharedWidgets.displayErrorDialog(context, errorMessage);
      }
      else if (bookFromISBNScan != null) {
        displayScannerSuccessDialog(context);
      }
    }
  }

  // the last digit of an ISBN is a check digit. It basically just lets computer systems know that the barcode is correct. If
  // a degraded barcode is scanned (causing 1 number to be off) I don't think the check digit will remain the same, but it depends.
  // Basically the last digit in an isbn is computed from all the other digits from some checksum algorithm.
  // this is pretty extra tbh but it should cause better user experience since they will usually get error instead of "no search results"
  // when barcode is degraded. I implemented this for an isbn10 to isbn13 converter which wasn't needed but its still useful here so whatever.
  bool _isValidCheckDigit(String isbn) {
    if (isbn.length != 13) { // keeping this check just to be safe
      return false;
    }
    if (int.tryParse(isbn) == null) { // in case there are letters for some freaky reason this just returns in that case
      return false;
    }
    int inputCheckDigit = int.parse(isbn[12]);
    isbn = isbn.replaceRange(isbn.length - 1, null, "");
    // now isbn should be length 12
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      if (i % 2 == 0) {
        sum += int.parse(isbn[i]);
      }
      else {
        sum += int.parse(isbn[i]) * 3;
      }
    }
    int checkDigit = 10 - (sum % 10);
    if (checkDigit == 10) { // handling the case where if checkDigit is 10 its represented as 0
      checkDigit = 0;
    }
    return checkDigit == inputCheckDigit;
  }

  void _resetLastScanValues() {
    bookFromISBNScan = null;
    _otherSearchError = false;
    _noBooksFoundError = false;
    _cameraSetupError = false;
    _noResponseError = false;
    _invalidISBNError = false;
    _invalidBarcodePhotoError = false;
    _unknownScannerScreenError = false;
  }

  Future<String?> _openBarcodeScanner(BuildContext context) async {
    // isbn can be null if user goes back from camera viewfinder without scanning
    showBottombar = false;
    refreshBottombar.value = true;
    final String? isbn = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
    showBottombar = true;
    refreshBottombar.value = true;
    return isbn;
  }

  // ensure that bookFromISBNScan is not null before calling this
  void displayScannerSuccessDialog(BuildContext context) {
    String title = bookFromISBNScan!.title ?? "No title found";
    String author = bookFromISBNScan!.author ?? "No author found";
    Widget image = bookFromISBNScan!.getCoverImage();
    showDialog(
      context: context,
      builder: (context) =>
        Dialog(
          child: Material(
          borderRadius: const BorderRadius.all(Radius.circular(25)), // dialog has a border, Material widget doesnt
            child: Container(
            height: 300,
            width: 300,
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Padding(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    "Book found!",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 3, 3, 3),
                          child: AspectRatio(
                            aspectRatio: 0.7,
                            child: image,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 175, maxWidth: 200),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, color: Colors.black),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                author,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14, color: Colors.black),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.cancelRed,
                          padding: const EdgeInsets.all(8),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          addBookToLibrary(bookFromISBNScan!, _user, context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.acceptGreen,
                          padding: const EdgeInsets.all(8),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Add",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _isbnSearchWithOpenLibrary(String isbn) async {
    final String endpoint = "https://openlibrary.org/search.json?isbn=$isbn&limit=1";
    http.Response? response;
    try {
      response = await http.get(Uri.parse(endpoint)).timeout(
        const Duration(seconds: 25), // longer timeout than google books api due to this api being slower
        onTimeout: () {
          throw "Timeout";
        },
      );
      if (response.statusCode == 200) {
        var bookResponse = json.decode(response.body)['docs'][0] ?? [];
        String? title, author, coverUrl; // note description isnt stored by openlibrary
        title = bookResponse?['title'];
        author = bookResponse?['author_name']?[0];
        coverUrl = bookResponse?['cover_i'] != null
          ? "https://covers.openlibrary.org/b/id/${bookResponse?['cover_i']}-M.jpg"
          : null;
        bookFromISBNScan = Book(title: title, author: author, coverUrl: coverUrl);
      }
      else {
        _otherSearchError = true;
      }
    } catch(e) {
      if (response == null) {
        _noResponseError = true;
      }
      else {
        _otherSearchError = true;
      }
    }
  }

  Future<void> _isbnSearchWithGoogle(String isbn) async {
    http.Response? response;
    final String endpoint = "https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn&key=$apiKey&maxResults=1";
    try {
      response = await http.get(Uri.parse(endpoint)).timeout(
        const Duration(seconds: 13), // arbitrarily chosen number, if you change, change in search and scanner driver both pls
        onTimeout: () {
          throw "Timeout";
        },
      );
      if (response.statusCode == 200) {
        var bookResponse = json.decode(response.body)['items'][0] ?? [];
        String? title, author, coverUrl, description, googleBooksId;
        int? isbn13;
        title = bookResponse?['volumeInfo']?['title'];
        author = bookResponse?['volumeInfo']?['authors']?[0];
        coverUrl = bookResponse?['volumeInfo']?['imageLinks']?['thumbnail'];
        description = bookResponse?['volumeInfo']?['description'];
        googleBooksId = bookResponse?['id']; // id should always be set in google books but in case its ever not, I want it to just be null in the DB (no placeholder values)
        List<dynamic> industryIdentifiers = bookResponse?['volumeInfo']?['industryIdentifiers'] ?? [];
        for (int i = 0; i < industryIdentifiers.length; i++) {
          if (industryIdentifiers[i]?['type'] == 'ISBN_13') {
            isbn13 = int.tryParse(bookResponse?['volumeInfo']?['industryIdentifiers']?[i]?['identifier']);
          }
        }
        bookFromISBNScan = Book(title: title, author: author, coverUrl: coverUrl, description: description, googleBooksId: googleBooksId, isbn13: isbn13);
      }
      else {
        await _isbnSearchWithOpenLibrary(isbn);
      }
    } catch(e) {
      if (response == null) {
        _noResponseError = true;
      }
      else {
        // this gets executed if there are no [items] in the response body AKA no results. It can happen sometimes even with correct isbn.
        await _isbnSearchWithOpenLibrary(isbn);
      }
    }
  }

  String _getScanFailMessage() {
    if (_cameraSetupError) {
      return "Camera access denied. Please enable it in your device settings.";
    }
    if (_noBooksFoundError) {
      return "The scanner couldn't identify the book. Likely due to poor lighting, an unclear camera angle, or a damaged barcode.";
    }
    if (_invalidISBNError) {
      return "The ISBN is invalid. You may be scanning an incorrect type of barcode.";
    }
    if (_noResponseError) {
      return "Search timed out. This may be due to internet connection issues or the service being temporarily unavailable.";
    }
    if (_invalidBarcodePhotoError) {
      return "There was no barcode found on this image. It may be too small for the scanner to detect.";
    }
    if (_unknownScannerScreenError) {
      return "An unexpected error occurred. Please try again later.";
    }
    if (_otherSearchError) { // IMPORTANT: in general otherSearchError should be the last explicit error (the lowest priority scan-fail to show to the user)
      return "An unexpected error occurred while scanning the barcode. Please try again later.";
    }
    // checking if book is already in user's library
    for (int i = 0; i < userLibrary.length; i++) {
      if (bookFromISBNScan == userLibrary[i]) {
        return "You already have this book added.";
      }
    }
    return "";
  }
}
