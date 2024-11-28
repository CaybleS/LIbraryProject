import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:library_project/add_book/shared_helper_util.dart';

class SearchBook extends StatefulWidget {
  final User user;

  @override
  State<SearchBook> createState() => _SearchBookState();
  const SearchBook(this.user, {super.key});
}

class _SearchBookState extends State<SearchBook> {

  bool hasSearched = false; // so that if there is no results, something is done which signals this, only after user searches
  final searchQueryController = TextEditingController();
  bool isSearching = false; // used to display CircularProgressIndicator when searching
  bool usingGoogleAPI = true;
  bool searchError = false;
  List<dynamic> searchQueryBooks = [];

  Future<void> searchWithOpenLibrary() async {
    String title = searchQueryController.text;
    if (title != "") {
      final String endpoint = "https://openlibrary.org/search.json?q=$title&limit=5";
      try {
        final response = await http.get(Uri.parse(endpoint));
        if (response.statusCode == 200) {
          searchError = false;
          // ?? is if-null operator, so if there is no response, the query response will be an empty list
          searchQueryBooks = json.decode(response.body)['docs'] ?? [];
        } else {
          searchError = true;
        }
      } catch (e) {
        searchError = true; // todo improve error handling eventually, for this and scanner_driver
      }
    }
  }

  Future<void> searchWithGoogle() async {
    String title = searchQueryController.text;
    if (title != "") {
      final String endpoint = "https://www.googleapis.com/books/v1/volumes?q=$title&key=${SharedHelperUtil.apiKey}&startIndex=0&maxResults=5";
      try {
        final response = await http.get(Uri.parse(endpoint));
        if (response.statusCode == 200) {
          // ?? is if-null operator, so if there is no response, the query response will be an empty list
          searchQueryBooks = json.decode(response.body)['items'] ?? [];
        } else if (response.statusCode == 429) {
          usingGoogleAPI = false;
          await searchWithOpenLibrary();
        }
        else {
          searchError = true;
        }
      } catch(e) {
        searchError = true;
      }
    }
  }

  Future<void> searchForBooks() async {
    searchError = false;
    if (usingGoogleAPI) {
      await searchWithGoogle();
    }
    else {
      await searchWithOpenLibrary();
    }
    if (mounted) {
      setState(() {});
    }
  }

String getSearchFailMessage() {
  if (hasSearched) {
    return "No books found";
  } else if (searchError) {
    return "Error with book search, please try again in a few minutes!";
  } else {
    return "";
  }
}

Widget displaySearchResults() {
  if (searchQueryController.text.isNotEmpty) { // todo maybe add an error message if user doesn't enter text. Maybe a nice place where messages can go in general idk
    hasSearched = true;
    searchQueryController.clear();
  }
  if (searchQueryBooks.isEmpty) {
    return Text(getSearchFailMessage());
  } else {
    return Column(
      children: [
        SizedBox(
          height: 550, // todo this sucks do this better
          child: ListView.builder(
            itemCount: searchQueryBooks.length,
            itemBuilder: (BuildContext context, int index) {
              Widget image;
              // using ?[] to access array indicies safely even if they're null, and ?? is if-null operator which has placeholder values to the right
              // if any are null the placeholder is used.
              String title, author, coverUrl;
              if (usingGoogleAPI) {
                title = searchQueryBooks[index]?['volumeInfo']?['title'] ?? "No title found";
                author = searchQueryBooks[index]?['volumeInfo']?['authors']?[0] ?? "No author found";
                coverUrl = searchQueryBooks[index]?['volumeInfo']?['imageLinks']?['thumbnail'] ?? SharedHelperUtil.defaultBookCover;
              } else {
                title = searchQueryBooks[index]?['title'] ?? "No title found";
                author = searchQueryBooks[index]?['author_name']?[0] ?? "No author found";
                coverUrl = searchQueryBooks[index]?['cover_i'] != null
                  ? "https://covers.openlibrary.org/b/id/${searchQueryBooks[index]?['cover_i']}-M.jpg"
                  : SharedHelperUtil.defaultBookCover;
              }
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
                                    color: Colors.black, fontSize: 20),
                                softWrap: true,
                                maxLines: 2, // so title can only be 2 lines, no more. There is only 1 more line where text can fit, for author
                                overflow: TextOverflow.ellipsis, // adds ... to indicate overflow
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                author,
                                style: const TextStyle(color: Colors.black, fontSize: 16),
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
                      child: ElevatedButton(
                        onPressed: () {
                          SharedHelperUtil.addBookToLibrary(context, title, author, coverUrl, widget.user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
                        ),
                        child: const Text("Add Book",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchQueryController,
          decoration: const InputDecoration(
          fillColor: Colors.white, filled: true),
        ),
        const SizedBox(
          height: 5,
        ),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              isSearching = true;
            });
            await searchForBooks();
            setState(() {
              isSearching = false;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
          ),
          child: const Text("Search",
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        isSearching
        ? const CircularProgressIndicator(
          color: Colors.deepPurpleAccent,
          backgroundColor: Colors.grey,
          strokeWidth: 5.0,
          )
        : displaySearchResults(),
      ],
    );
  }
}
