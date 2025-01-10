import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:library_project/add_book/search/book_details_screen.dart';
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';

class SearchDriver {
  // used when displaying search results for optimization reasons (duplicate checks iterate through a users entire library so I cache the results, since ListView re-renders often)
  final Map<int, bool> _alreadyAddedBooks = {};
  List<dynamic> _searchQueryBooks = [];
  String? _mostRecentSearch; // detects if user clicks search without changing the query, to prevent unnecessary api calls
  bool _otherSearchError = false;
  bool _noBooksFoundError = false;
  bool _noResponseError = false; // this detects lack of internet connection (or api being down maybe)
  bool _usingGoogleAPI = true;
  late final User _user;
  late final List<Book> _userLibrary;

  SearchDriver(this._user, this._userLibrary);

  void resetLastSearchValues() {
    _alreadyAddedBooks.clear();
    _searchQueryBooks.clear();
    _otherSearchError = false;
    _noBooksFoundError = false;
    _noResponseError = false;
  }

  Future<void> runSearch(String searchQuery, BuildContext context) async {
    if (searchQuery != _mostRecentSearch) {
      _mostRecentSearch = searchQuery;
      // resetting values of most recent search ONLY when search query changes (so if search query doesnt change we just show last search results)
      resetLastSearchValues();
    } else {
      _handleSearchErrors(context);
      return; // in this case, search button was pressed but the query was not changed, so we just use the most recent search results
    }
    await _searchForBooks(searchQuery);
    if (context.mounted) {
      _handleSearchErrors(context);
    }
  }

  Future<void> _searchWithOpenLibrary(String searchQuery) async {
    final String endpoint = "https://openlibrary.org/search.json?q=$searchQuery&limit=$maxApiResponseSize";
    http.Response? response;
    try {
      response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        _searchQueryBooks = json.decode(response.body)['docs'] ?? [];
      } else {
        _otherSearchError = true;
      }
    } catch (e) {
      if (response == null) {
        _noResponseError = true;
      }
     _otherSearchError = true;
    }
  }

  Future<void> _searchWithGoogle(String searchQuery) async {
    final String endpoint = "https://www.googleapis.com/books/v1/volumes?q=$searchQuery&key=$apiKey&startIndex=0&maxResults=$maxApiResponseSize";
    http.Response? response;
    try {
      response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        _searchQueryBooks = json.decode(response.body)['items'] ?? [];
      } // with a bad response we just fallback to openlibrary api
      else {
        _usingGoogleAPI = false;
        await _searchWithOpenLibrary(searchQuery);
      }
    } catch (e) {
      if (response == null) {
        _noResponseError = true;
      } else {
        _otherSearchError = true;
      }
    }
  }

  Future<void> _searchForBooks(String searchQuery) async {
    _usingGoogleAPI
      ? await _searchWithGoogle(searchQuery)
      : await _searchWithOpenLibrary(searchQuery);
    if (_searchQueryBooks.isEmpty) {
      _noBooksFoundError = true;
    }
    // note that a setState is needed here to display whatever search result occurs, its done by the function which calls this one so
  }

  String _getSearchFailMessage() {
    if (_noResponseError) {
      return "No response. Either the service is down or you have no internet!";
    }
    if (_noBooksFoundError) {
      return "No books found";
    }
    if (_otherSearchError) { // IMPORTANT: in general otherSearchError should be the last explicit error (the lowest priority one to show to the user)
      return "Error with book search, please try again in a few minutes!";
    }
    return "";
  }

  void _bookAddButtonClicked(Book bookToAdd, BuildContext context, Function setState) {
    addBookToLibrary(bookToAdd, _user, _userLibrary, context);
    _alreadyAddedBooks.clear(); // need to clear it since 2 of this same book can be in the search results (rather than just setting listview index to true)
    setState(() {});
  }

  void _bookClicked(Book bookToView, User user, bool isBookAlreadyAdded, BuildContext context, Function setState) async {
    String? retVal = await Navigator.push(context, MaterialPageRoute(builder: (ctx) {
      return BookDetailsScreen(bookToView, isBookAlreadyAdded);
    }));
    if (retVal != null && context.mounted) {
      _bookAddButtonClicked(bookToView, context, setState);
    }
  }

  void _handleSearchErrors(BuildContext context) {
    if (_searchQueryBooks.isEmpty) {
      String errorText = _getSearchFailMessage();
      SharedWidgets.displayErrorDialog(context, errorText);
    }
  }

  // this should display a general info - NOT AN ERROR, just general input regarding whatever user is doing, helper text basically
  Widget getSearchInfoWidget() {
    String? feedbackMsg;
    if (!_usingGoogleAPI) {
      feedbackMsg = "Google Books API unavailable, fallback results are limited.";
    }
    if (feedbackMsg == null) {
      return const SizedBox.shrink();
    } else {
      return Column(
        children: [
          const SizedBox(height: 5),
          Text(
            feedbackMsg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
          const SizedBox(height: 5),
        ],
      );
    }
  }

  // pretty sure its optimal to declare this as its own stateful widget with a build method but i dont feel like it
  Widget displaySearchResults(Function setState) {
    if (_searchQueryBooks.isEmpty) {
      return const SizedBox.shrink();
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 1, 15, 25),
        child: ListView.builder(
        itemCount: _searchQueryBooks.length,
        itemBuilder: (BuildContext context, int index) {
          Widget image;
          String? title, author, coverUrl, description, googleBooksId;
          bool isBookAlreadyAdded = false;
          if (_usingGoogleAPI) {
            title = _searchQueryBooks[index]?['volumeInfo']?['title'];
            author = _searchQueryBooks[index]?['volumeInfo']?['authors']?[0];
            coverUrl = _searchQueryBooks[index]?['volumeInfo']?['imageLinks']?['thumbnail'];
            description = _searchQueryBooks[index]?['volumeInfo']?['description'];
            googleBooksId = _searchQueryBooks[index]?['id'];
          }
          else {
            title = _searchQueryBooks[index]?['title'];
            author = _searchQueryBooks[index]?['author_name']?[0];
            coverUrl = _searchQueryBooks[index]?['cover_i'] != null
              ? "https://covers.openlibrary.org/b/id/${_searchQueryBooks[index]?['cover_i']}-M.jpg"
              : null;
          }
          Book currentBook = Book(title: title, author: author, coverUrl: coverUrl, description: description, googleBooksId: googleBooksId);
          if (_alreadyAddedBooks[index] == null) { // going through all books in user's library for this index in ListView (only done once due to this check)
            _alreadyAddedBooks[index] = false;
            for (int i = 0; i < _userLibrary.length; i++) {
              if (areBooksSame(currentBook, _userLibrary[i])) {
                _alreadyAddedBooks[index] = true;
              }
            }
          }
          if (_alreadyAddedBooks[index] == true) {
            isBookAlreadyAdded = true;
          }
          image = currentBook.getCoverImage();
          return InkWell(
            onTap: () {
              _bookClicked(currentBook, _user, isBookAlreadyAdded, context, setState);
            },
            child: SizedBox(
              height: 100,
              child: Card(
              margin: const EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
                      child: AspectRatio(
                      aspectRatio: 0.7,
                      child: image,
                    ),
                  ),
                  Expanded(
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
                              title ?? "No title found",
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              author ?? "No author found",
                              style: const TextStyle(fontSize: 14, color: Colors.black),
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
                    width: 100,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: isBookAlreadyAdded
                      ? const Text(
                          "Book already added",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        )
                      : ElevatedButton(
                        onPressed: () {
                          _bookAddButtonClicked(currentBook, context, setState);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.pink,
                          padding: const EdgeInsets.all(8),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Add book",
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          );
        },
      ),
      ),
    );
  }
}
