import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:library_project/core/book.dart';
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/add_book/scanner_screen.dart';
  
class ScannerDriver extends StatefulWidget {
  final User user;

  @override
  State<ScannerDriver> createState() => _ScannerDriverState();
  const ScannerDriver(this.user, {super.key});
}

class _ScannerDriverState extends State<ScannerDriver> {
  bool hasScanned = false;
  bool searchError = false;
  bool noResults = false; // this only occurs if no results occur from the search query, implying that the scanned ISBN is wrong (likely due to bad barcode)
  Book? bookFromISBNScan;
  String? scannedISBN;

  Future<void> openScannerAndParseISBN() async {
    bookFromISBNScan = null;
    scannedISBN = null;
    noResults = false; // need to reset this here if we scan again, since its only relevant to the last isbn search result
    scannedISBN = await openBarcodeScanner(context);
    bookFromISBNScan = await isbnSearchWithGoogle(scannedISBN);
    setState(() {});
  }

  Future<String> openBarcodeScanner(BuildContext context) async {
    // isbn can be null if user goes back from camera viewfinder without scanning
    final String isbn = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen())) ?? "no barcode found";
    setState(() {
      hasScanned = true;
    });
    return isbn;
  }

  Future<Book> isbnSearchWithOpenLibrary(String? isbn) async {
    // this should never be shown, since searchError will be true if this gets returned
    Book bookFromISBNScan = Book("No title found", "No author found", true, SharedHelperUtil.defaultBookCover);
    if (isbn == null) {
      return bookFromISBNScan;
    }
    final String endpoint = "https://openlibrary.org/search.json?q=$isbn&limit=1";
    try {
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        var bookResponse = json.decode(response.body)['docs'][0] ?? [];
        String title, author, coverUrl;
        title = bookResponse?['title'] ?? "No title found";
        author = bookResponse?['author_name']?[0] ?? "No author found";
        coverUrl = bookResponse?['cover_i'] != null
          ? "https://covers.openlibrary.org/b/id/${bookResponse?['cover_i']}-M.jpg"
          : SharedHelperUtil.defaultBookCover;
        bookFromISBNScan = Book(title, author, true, coverUrl);
      } else if (response.statusCode == 429) {
        searchError = true;
        // mby should do something here idk
      }
      else {
        searchError = true;
      }
    } catch(e) {
      noResults = true;
    }
    return bookFromISBNScan;
  }

  Future<Book> isbnSearchWithGoogle(String? isbn) async {
    // this should never be shown, since searchError will be true if this gets returned
    Book bookFromISBNScan = Book("No title found", "No author found", true, SharedHelperUtil.defaultBookCover);
    if (isbn == null) {
      return bookFromISBNScan;
    }
    searchError = false;
    final String endpoint = "https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn&key=${SharedHelperUtil.apiKey}&maxResults=1";
    try {
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        var bookResponse = json.decode(response.body)['items'][0] ?? [];
        String title, author, coverUrl;
        title = (bookResponse?['volumeInfo']?['title']) ?? "No title found";
        author = (bookResponse?['volumeInfo']?['authors']?[0]) ?? "No author found";
        coverUrl = (bookResponse?['volumeInfo']?['imageLinks']?['thumbnail']) ?? SharedHelperUtil.defaultBookCover;
        bookFromISBNScan = Book(title, author, true, coverUrl);
      } else if (response.statusCode == 429) {
        bookFromISBNScan = await isbnSearchWithOpenLibrary(isbn);
      }
      else {
        searchError = true;
      }
    } catch(e) {
      noResults = true;
    }
    return bookFromISBNScan;
  }

  Widget addScannedBook(Book? scannedBook, BuildContext context, User user) {
    if (scannedBook == null) {
      return const Text("");
    }
    if (searchError) {
      return const Text("Error with barcode scan. Please try again later!");
    }
    if (noResults) {
      return Column(
        children: [
          SizedBox(
            height: 60,
            width: 300,
            child: ElevatedButton(
              onPressed: () async {
                await openScannerAndParseISBN();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
              ),
              child: const Text("Scan Again",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          const Text( // TODO maybe add a message like this for all users to see before getting here, that some lower quality paperback barcodes can be impossible to accurately scan
            "The scanner was unable to determine the book. Likely due to poor lighting, camera position, or degraded barcode (some barcodes can be deformed, making scanning impossible).",
            style: TextStyle(fontSize: 20),
          ),
        ],
      );
    }
    String title = scannedBook.title;
    String author = scannedBook.author;
    String coverUrl = scannedBook.coverUrl;
    Widget image = Image.network(coverUrl.toString());
    return Card(
      margin: const EdgeInsets.all(5),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 200,
                width: 140,
                child: image,
              ),
              const SizedBox(
                width: 10,
              ),
              Column(
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 200,
                    child: Text(author,
                      style: const TextStyle(fontSize: 25)
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            width: 300,
            child: ElevatedButton(
              onPressed: () {
                SharedHelperUtil.addBookToLibraryFromScan(context, title, author, coverUrl, user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
              ),
              child: const Text("Add Book",
                  style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            width: 300,
            child: ElevatedButton(
              onPressed: () async {
                await openScannerAndParseISBN();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 196, 24, 24),
              ),
              child: const Text("Scan Again",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // yes this is a nested ternary operator, and yes its weird to read
        !hasScanned
          ? SizedBox(
              height: 50,
              width: 160,
              child: ElevatedButton(
                onPressed: () async {
                  await openScannerAndParseISBN();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
                ),
                child: const Text("Open scanner",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            )
          : (bookFromISBNScan == null)
              ? const CircularProgressIndicator(
                  color: Colors.deepPurpleAccent,
                  backgroundColor: Colors.grey,
                  strokeWidth: 5.0,
                )
              : addScannedBook(bookFromISBNScan, context, widget.user)
      ],
    );
  }
}
