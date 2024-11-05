// note that in my implementation of trying to add a search bar with google books API, I went to
// \android\app\src\main\AndroidManifest.xml and added above the <application>: <uses-permission android:name="android.permission.INTERNET"/>
// I also added "http: any" to pubspec.yaml dependencies.
// those 3 files are the only files I edited so far
// inspiration: https://www.youtube.com/watch?v=H13CIwr3nIY
// note that the API returns a JSON-formatted response body, with specific keywords to specify each value.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book.dart';
import 'package:library_project/database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddBookPage extends StatefulWidget {
  final User user;

  @override
  State<AddBookPage> createState() => _AddBookPageState();
  const AddBookPage(this.user, {super.key});
}

class _AddBookPageState extends State<AddBookPage> {
  final controllerAuthor = TextEditingController();
  final controllerTitle = TextEditingController();

  List<dynamic> searchQueryBooks = [];
  // This is my private api key. Do NOT use this for the final project. I prob shouldnt even push this but idc
  // TODO change this to the libraryproject gmail google books api key
  static const String apiKey = "AIzaSyAqHeGVVwSiWJLfVMjF8K5gBbQcNucKuQY";
  bool hasSearched = false; // so that if there is no results, something is done which signals this, only after user searches

  Widget displaySearchResults(List<dynamic> searchQueryBooks) {
    if (searchQueryBooks.isNotEmpty) {
      return SizedBox(
        height: 560,
        child: ListView.builder(
          itemCount: searchQueryBooks.length, // does this even work?? I have no idea!
          itemBuilder: (BuildContext context, int index) {
            Widget image;
            // using ?[] to access array indicies safely even if they're null, and ?? is if-null operator which sets the cover to the placeholder img if index access is null
            // kind of freaky line but I can't think of a better way to do it
            String coverUrl = (searchQueryBooks[index]?['volumeInfo']['imageLinks']?['thumbnail']) ?? "https://lgimages.s3.amazonaws.com/nc-md.]if";
            image = Image.network(coverUrl.toString());
            return SizedBox(
              height: 100,
              width: 70,
              child: image,
            );
          },
        ),
      );
    }
    if (hasSearched) {
      return const Text("No books found");
    }
    else {
      return const Text("");
    }
  }
  
  Future<void> searchBooks(String query, String endpoint) async {
    final response = await http.get(Uri.parse(endpoint));
    if (response.statusCode == 200) {
       // ?? is if-null operator, so if there is no response, the query response will be an empty list
      searchQueryBooks = json.decode(response.body)['items'] ?? [];
    }
    // TODO also add some system to deal with rate limiting or other status codes, maybe a message "try again later" or something
  }

// note that the url is not used as a paramter there, but it will be required now
  // old onSubmit function, kept as a guideline for how to do this
  // void onSubmit(BuildContext context) {
  //   if (controllerAuthor.text != "" && controllerTitle.text != "") {
  //     Book book = Book(controllerTitle.text, controllerAuthor.text, true);
  //     book.setId(addBook(book, user));
  //     exampleLibrary.add(book);
  //     Navigator.pop(context);
  //   }
  // }

  void onSubmit(BuildContext context) async {
    if (controllerTitle.text != "") {
      hasSearched = true;
      // stuff with google books api
      String title = controllerTitle.text;
      final String endpoint = "https://www.googleapis.com/books/v1/volumes?q=$title&key=$apiKey";
      await searchBooks(title, endpoint);
      setState(() {});
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
        ),
        backgroundColor: Colors.grey[400],
        body: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const Text(
                "Title:",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: controllerTitle,
                decoration: const InputDecoration(
                    fillColor: Colors.white, filled: true),
              ),
              const SizedBox(
                height: 5,
              ),
              ElevatedButton(
                  onPressed: () {
                    onSubmit(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
                  child: const Text('Add Book',
                      style: TextStyle(fontSize: 16, color: Colors.black))
              ),
              const SizedBox(
                height: 20,
              ),
              displaySearchResults(searchQueryBooks),
            ],
          ),
        ));
    }
}