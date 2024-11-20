// note that the API returns a JSON-formatted response body, with specific keywords to specify each value
// the results from the query is formatted in a way like this: https://developers.google.com/books/docs/v1/using#response_1

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'book.dart';
import 'database.dart';

enum _AddBookOptions {search, scan, custom}

class AddBookPage extends StatefulWidget {
  final User user;

  @override
  State<AddBookPage> createState() => _AddBookPageState();
  const AddBookPage(this.user, {super.key});
}

class _AddBookPageState extends State<AddBookPage> {
  final _controllerTitle = TextEditingController();

  List<dynamic> _searchQueryBooks = [];
  // This is my private api key. Do NOT use this for the final project. I prob shouldnt even push this but idc
  // TODO change this to the libraryproject gmail google books api key
  // the reason iv not changed it yet, is because we need some system to not have the api key on git and idk how we should do it
  static const String _apiKey = "AIzaSyAqHeGVVwSiWJLfVMjF8K5gBbQcNucKuQY";
  bool _hasSearched = false; // so that if there is no results, something is done which signals this, only after user searches
  bool _isSearching = false;
  bool _searchError = false;
  bool _usingGoogleAPI = true;
  Set<_AddBookOptions> selection = <_AddBookOptions>{_AddBookOptions.search}; // I think this will only ever be set to 1 selection value but idk!

  void _addBookToLibrary(BuildContext context, String title, String author, String coverUrl) {
    Book book = Book(title, author, true, coverUrl);
    book.setId(addBook(book, widget.user));
    Navigator.pop(context);
  }

  Future<void> _searchWithOpenLibrary() async {
    String title = _controllerTitle.text;
    if (title != "") {
      final String endpoint = "https://openlibrary.org/search.json?q=$title";
      try { 
        final response = await http.get(Uri.parse(endpoint));
        if (response.statusCode == 200) {
          _searchError = false;
          // ?? is if-null operator, so if there is no response, the query response will be an empty list
          _searchQueryBooks = json.decode(response.body)['docs'] ?? [];
        } else {
          _searchError = true;
        }
      } catch (e) {
        _searchError = true; // amazing error handling over here
      }
    }
  }

  Future<void> _searchWithGoogle() async {
    String title = _controllerTitle.text;
    if (title != "") {
      final String endpoint = "https://www.googleapis.com/books/v1/volumes?q=$title&key=$_apiKey";
      try {
        final response = await http.get(Uri.parse(endpoint));
        if (response.statusCode == 200) {
          // ?? is if-null operator, so if there is no response, the query response will be an empty list
          _searchQueryBooks = json.decode(response.body)['items'] ?? [];
        } else if (response.statusCode == 429) {
          _usingGoogleAPI = false;
          _searchWithOpenLibrary();
        }
        else {
          _searchError = true;
        }
      } catch(e) {
        _searchError = true;
      }
    }
  }

  // in general I'm not happy with this system, but for now I'll have it this way.
  Future<void> _searchForBooks() async {
  if (_usingGoogleAPI) {
    await _searchWithGoogle();
  }
  else {
    await _searchWithOpenLibrary();
  }
    setState(() {});
  }

  String _getSearchFailMessage() {
    if (_hasSearched) {
      return "No books found";
    }
    else if (_searchError) {
      return "Error with book search, please try again in a few minutes!";
    }
    else {
      return "";
    }
  }

  Widget _displaySearchResults() {
    if (_controllerTitle.text.isNotEmpty) {
      _hasSearched = true;
      _controllerTitle.clear();
    }
    if (_searchQueryBooks.isEmpty) {
      return Text(_getSearchFailMessage());
    }
    else {
      return SizedBox(
        height: 560,
        child: ListView.builder(
          itemCount: _searchQueryBooks.length,
          itemBuilder: (BuildContext context, int index) {
            Widget image;
            // using ?[] to access array indicies safely even if they're null, and ?? is if-null operator which has placeholder values to the right
            // if any are null the placeholder is used. Freaky lines but I can't think of a better way to do it.
            String title, author, coverUrl;
            if (_usingGoogleAPI) {
              title = (_searchQueryBooks[index]?['volumeInfo']?['title']) ?? "No title found";
              author = (_searchQueryBooks[index]?['volumeInfo']?['authors']?[0]) ?? "No author found";
              coverUrl = (_searchQueryBooks[index]?['volumeInfo']?['imageLinks']?['thumbnail']) ?? "https://lgimages.s3.amazonaws.com/nc-md.gif";
            }
            else {
              title = (_searchQueryBooks[index]?['title']) ?? "No title found";
              author = (_searchQueryBooks[index]?['author_name']?[0] ?? "No author found");
              coverUrl = (_searchQueryBooks[index]?['cover_i'] != null)
              ? "https://covers.openlibrary.org/b/id/${_searchQueryBooks[index]?['cover_i']}-M.jpg"
              : "https://lgimages.s3.amazonaws.com/nc-md.gif";
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
                        _addBookToLibrary(context, title, author, coverUrl);
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
  }


  Widget _searchBook() {
    return Column(
      children: [
        TextField(
              controller: _controllerTitle,
              decoration: const InputDecoration(
              fillColor: Colors.white, filled: true),
            ),
            const SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
                _searchForBooks().then((_) { // triggers this setState when it finishes
                  setState(() {
                    _isSearching = false;
                  });
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(129, 199, 132, 1)
              ),
              child: const Text("Search",
                style: TextStyle(fontSize: 16, color: Colors.black))
              ),
              const SizedBox(
                height: 20,
              ),
              _isSearching 
              ? const CircularProgressIndicator(
                color: Colors.deepPurpleAccent,
                backgroundColor: Colors.grey,
                strokeWidth: 5.0,
                )
              : _displaySearchResults(),
      ],
    );
  }

  Widget _scanBook() {
    return const Text("Scan here! Except its not implemtned yet!");
  }

  Widget _addCustomBook() {
    return const Text("add book entry here! Except its not implemented yet!");
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
            const Text("Add a book:",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(
              height: 10,
            ),
            SegmentedButton<_AddBookOptions>(
              selected: selection,
              onSelectionChanged: (Set<_AddBookOptions> newSelection) {
                setState(() {
                  selection = newSelection;
                });
              },
              segments: const <ButtonSegment<_AddBookOptions>> [
                ButtonSegment(
                  icon: Icon(Icons.fiber_dvr),
                  value: _AddBookOptions.search,
                  label: Text("search"),
                ),
              ButtonSegment(
                icon: Icon(Icons.bookmark_add),
                value: _AddBookOptions.scan,
                label: Text("scan"),
              ),
              ButtonSegment(
                icon: Icon(Icons.back_hand),
                value: _AddBookOptions.custom,
                label: Text("manual entry"),
              ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            switch (selection.single) {
              _AddBookOptions.search =>
             _searchBook(),
             _AddBookOptions.scan =>
             _scanBook(),
             _AddBookOptions.custom =>
             _addCustomBook(), 
            },
            ],
          ),
        ),
      );
    }
}
