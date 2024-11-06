// note that the API returns a JSON-formatted response body, with specific keywords to specify each value
// the results from the query is formatted in a way like this: https://developers.google.com/books/docs/v1/using#response_1
// TODO what should the app show when a user already has a book in their library, should it not be shown? Or show "already owned", or a remove button?
// TODO add a CircularProgressIndicator which shows between the time they hit add book and the time results are shown
// TODO should I add an option for users to click on the book to get more details? Similar to the book_page thing. I think no but not sure, seems like too much button pressing.
// TODO add a pagination system of some kind, for now it only shows 10 books and there is no page 2 or whatever. I think this will be a system where each 10 query results are
// shown on screen, and if user goes to next page it will make another api call to get the next 10 query results if they exist, and store previous query results in a list/map
// also if the user searches, should the query be cleared? Idk! That or there should be a clear button, not sure which
// also, should books in the DB also have info such as num pages, retail price, isbn, etc (this info would be added to book_page.dart if so)

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
  final controllerTitle = TextEditingController();

  List<dynamic> searchQueryBooks = [];
  // This is my private api key. Do NOT use this for the final project. I prob shouldnt even push this but idc
  // TODO change this to the libraryproject gmail google books api key
  static const String apiKey = "AIzaSyAqHeGVVwSiWJLfVMjF8K5gBbQcNucKuQY";
  bool hasSearched = false; // so that if there is no results, something is done which signals this, only after user searches

  void addBookToLibrary(BuildContext context, String title, String author, String coverUrl) async { // mby make async idk
      Book book = Book(title, author, true, coverUrl);
      book.setId(addBook(book, widget.user));
      exampleLibrary.add(book);
      Navigator.pop(context);
  }

  Widget displaySearchResults() {
    controllerTitle.clear(); // emptying the title user input field (done here so that its emptied the same time the results are displayed) (should I even be doing this?)
    if (searchQueryBooks.isNotEmpty) {
      return SizedBox(
        height: 560,
        child: ListView.builder(
          itemCount: searchQueryBooks.length, // does this even work?? I have no idea!
          itemBuilder: (BuildContext context, int index) {
            Widget image;
            // using ?[] to access array indicies safely even if they're null, and ?? is if-null operator which has placeholder values to the right
            // if any are null the placeholder is used. Freaky lines but I can't think of a better way to do it.
            String title = (searchQueryBooks[index]?['volumeInfo']?['title']) ?? "No title found";
            String author = (searchQueryBooks[index]?['volumeInfo']?['authors']?[0]) ?? "No author found";
            String coverUrl = (searchQueryBooks[index]?['volumeInfo']?['imageLinks']?['thumbnail']) ?? "https://lgimages.s3.amazonaws.com/nc-md.gif";
            image = Image.network(coverUrl.toString());
            return Card(
              margin: const EdgeInsets.all(5),
              child: Row(
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    height: 100,
                    width: 70,
                    child: image,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 190,
                    height: 100,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              title,
                              style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20),
                              softWrap: true,
                              maxLines: 2, // so title can only be 2 lines, no more. There is only 1 more line where text can fit, for author
                              overflow: TextOverflow.ellipsis, // adds ... to indicate overflow
                            ),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              author,
                              style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16),
                              softWrap: true,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                  height: 60,
                  width: 85,
                  // add book button and other buttons go here
                  child:
                    ElevatedButton(
                      onPressed: () {
                        addBookToLibrary(context, title, author, coverUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
                      child: const Text(
                        'Add Book',
                        style: TextStyle(fontSize: 16, color: Colors.black)
                      ),
                    ),
                  ),
                ],
              ), 
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

  void onSubmit() async {
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
                "Search for book here:",
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
                    onSubmit();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
                  child: const Text('Search',
                      style: TextStyle(fontSize: 16, color: Colors.black))
              ),
              const SizedBox(
                height: 20,
              ),
              displaySearchResults(),
            ],
          ),
        ));
    }
}