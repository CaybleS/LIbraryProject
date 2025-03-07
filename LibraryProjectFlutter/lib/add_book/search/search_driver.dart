import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shelfswap/add_book/search/book_details_screen.dart';
import 'package:shelfswap/add_book/shared_helper_util.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';

enum SearchQueryOption { normal, title, author }

class SearchDriver {
  // used when displaying search results for optimization reasons (duplicate checks iterate through a users entire library so I cache the results, since ListView re-renders often)
  final Map<int, bool> alreadyAddedBooks = {};
  List<dynamic> _searchQueryBooks = [];
  String? _mostRecentSearch; // detects if user clicks search without changing the query, to prevent unnecessary api calls
  bool _otherSearchError = false;
  bool _noBooksFoundError = false;
  bool _noResponseError = false; // this detects lack of internet connection (or api being down maybe)
  bool _usingGoogleApi = true; // if you modify this modify googleApiFailTime also
  // basically if google api fails this stores the timestamp of when this occurs and so subsequent api calls dont try calling it again
  // but I store this timestamp so that if 30 mins pass we try again. It's that, or just try google books api every time, but storing the timestamp
  // is obviously better so I just did that
  DateTime? _googleApiFailTime;
  SearchQueryOption _searchQueryOption = SearchQueryOption.normal;
  SearchQueryOption _prevSearchQueryOption = SearchQueryOption.normal; // used to allow for a search where all you change is search query option (w/same query)
  late final User _user;
  late final List<Book> userLibrary;

  SearchDriver(this._user, this.userLibrary);

  void clearAlreadyAddedBooks() {
    alreadyAddedBooks.clear();
  }

  void resetLastSearchValues() {
    clearAlreadyAddedBooks();
    _searchQueryBooks.clear();
    _otherSearchError = false;
    _noBooksFoundError = false;
    _noResponseError = false;
  }

  SearchQueryOption getSearchQueryOption() {
    return _searchQueryOption;
  }

  void setSearchQueryOption(SearchQueryOption optionToSetTo) {
    _prevSearchQueryOption = _searchQueryOption;
    _searchQueryOption = optionToSetTo;
  }

  Future<void> runSearch(String searchQuery, BuildContext context) async {
    // we let users search again if 1.) the query is different or 2.) they got no response with their previous search
    // or 3.) they change the search query option for their search
    if (searchQuery != _mostRecentSearch || _noResponseError || _searchQueryOption != _prevSearchQueryOption) {
      _prevSearchQueryOption = _searchQueryOption; // letting changing search query option with same query only allow for a search once
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

  String _getApiSearchOption({required bool usingGoogleSearch}) {
    switch (_searchQueryOption) {
      case SearchQueryOption.normal:
        return usingGoogleSearch ? "" : "q=";
      case SearchQueryOption.title:
        return usingGoogleSearch ? "intitle:" : "title=";
      case SearchQueryOption.author:
        return usingGoogleSearch ? "inauthor:" : "author=";
    }
  }

  // 
  String _getSearchQueryWithFilters(String searchQuery, {required bool usingGoogleSearch}) {
    String searchQueryOption = _getApiSearchOption(usingGoogleSearch: usingGoogleSearch);
    String searchQueryWithFilters = "$searchQueryOption$searchQuery";
    if (!usingGoogleSearch) {
      return searchQueryWithFilters;
    }
    if (_searchQueryOption != SearchQueryOption.normal && searchQuery.contains(RegExp(r'[ ]'))) {
      searchQueryWithFilters = "";
      String currWord = "";
      for (int i = 0; i < searchQuery.length; i++) {
        if (searchQuery[i] != " ") {
          currWord += searchQuery[i];
        }
        // so if we're on a space in the search query and the currWord isnt just a bunch of spaces
        // (this will cause unnecessary spaces to just be removed for this filtering stuff)
        else if (currWord.isNotEmpty) {
          if (searchQueryWithFilters.isNotEmpty) {
            searchQueryWithFilters += " ";
          }
          searchQueryWithFilters += searchQueryOption + currWord;
          currWord = "";
        }
      }
      // in this case we're done indexing through the search query (this can handle the case of no spaces also but whatever, I think its fine)
      if (currWord.isNotEmpty) {
        searchQueryWithFilters += " $searchQueryOption$currWord";
      }
    }
    return searchQueryWithFilters;
  }

  Future<void> _searchWithOpenLibrary(String searchQuery) async {
    String searchQueryWithPossibleFilters = _getSearchQueryWithFilters(searchQuery, usingGoogleSearch: false);
    final String endpoint = "https://openlibrary.org/search.json?$searchQueryWithPossibleFilters&limit=$maxApiResponseSize";
    http.Response? response;
    try {
      response = await http.get(Uri.parse(endpoint)).timeout(
        const Duration(seconds: 25), // longer timeout than google books api due to this api being slower
        onTimeout: () {
          throw "Timeout";
        },
      );
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
    String searchQueryWithPossibleFilters = _getSearchQueryWithFilters(searchQuery, usingGoogleSearch: true);
    final String endpoint = "https://www.googleapis.com/books/v1/volumes?q=$searchQueryWithPossibleFilters&key=$apiKey&startIndex=0&maxResults=$maxApiResponseSize";
    http.Response? response;
    try {
      response = await http.get(Uri.parse(endpoint)).timeout(
        const Duration(seconds: 13), // arbitrarily chosen number, if you change, change in search and scanner driver both pls
        onTimeout: () {
          throw "Timeout";
        },
      );
      if (response.statusCode == 200) {
        _searchQueryBooks = json.decode(response.body)['items'] ?? [];
      } // with a bad response we just fallback to openlibrary api
      else {
        _usingGoogleApi = false;
        _googleApiFailTime = DateTime.now().toUtc();
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
    if (_usingGoogleApi) {
      await _searchWithGoogle(searchQuery);
    }
    else {
      // if its been 30 minutes since google books api fails we just try again
      if (_googleApiFailTime!.isBefore(DateTime.now().toUtc().subtract(const Duration(minutes: 30)))) {
        _usingGoogleApi = true;
        _googleApiFailTime = null;
        await _searchWithGoogle(searchQuery);
      }
      else {
        await _searchWithOpenLibrary(searchQuery);
      }
    }
    if (_searchQueryBooks.isEmpty) {
      _noBooksFoundError = true;
    }
    // note that a setState is needed here to display whatever search result occurs, its done by the function which calls this one so
  }

  String _getSearchFailMessage() {
    if (_noResponseError) {
      return "Search timed out. This may be due to internet connection issues or the service being temporarily unavailable.";
    }
    if (_noBooksFoundError) {
      return "No books found";
    }
    if (_otherSearchError) { // IMPORTANT: in general otherSearchError should be the last explicit error (the lowest priority one to show to the user)
      return "Error with book search, please try again in a few minutes!";
    }
    return "";
  }

  void bookAddButtonClicked(Book bookToAdd, BuildContext context, Function setState) {
    addBookToLibrary(bookToAdd, _user, context);
    alreadyAddedBooks.clear(); // need to clear it since 2 of this same book can be in the search results (rather than just setting listview index to true)
    setState(() {});
  }

  void _bookClicked(Book bookToView, User user, bool isBookAlreadyAdded, BuildContext context, Function setState) async {
    String? retVal = await Navigator.push(context, MaterialPageRoute(builder: (ctx) {
      return BookDetailsScreen(bookToView, isBookAlreadyAdded);
    }));
    if (retVal != null && context.mounted) {
      bookAddButtonClicked(bookToView, context, setState);
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
    if (!_usingGoogleApi) {
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
          int? isbn13; // note that openlibrary stores isbn13 sometimes, but their response body is a mess, its really not easy or good to extract
          bool isBookAlreadyAdded = false;
          if (_usingGoogleApi) {
            title = _searchQueryBooks[index]?['volumeInfo']?['title'];
            author = _searchQueryBooks[index]?['volumeInfo']?['authors']?[0];
            coverUrl = _searchQueryBooks[index]?['volumeInfo']?['imageLinks']?['thumbnail'];
            description = _searchQueryBooks[index]?['volumeInfo']?['description'];
            googleBooksId = _searchQueryBooks[index]?['id'];
            List<dynamic> industryIdentifiers = _searchQueryBooks[index]?['volumeInfo']?['industryIdentifiers'] ?? [];
            for (int i = 0; i < industryIdentifiers.length; i++) {
              if (industryIdentifiers[i]?['type'] == 'ISBN_13') {
                isbn13 = int.tryParse(_searchQueryBooks[index]?['volumeInfo']?['industryIdentifiers']?[i]?['identifier']);
              }
            }
          }
          else {
            title = _searchQueryBooks[index]?['title'];
            author = _searchQueryBooks[index]?['author_name']?[0];
            coverUrl = _searchQueryBooks[index]?['cover_i'] != null
              ? "https://covers.openlibrary.org/b/id/${_searchQueryBooks[index]?['cover_i']}-M.jpg"
              : null;
          }
          Book currentBook = Book(title: title, author: author, coverUrl: coverUrl, description: description, googleBooksId: googleBooksId, isbn13: isbn13);
          if (alreadyAddedBooks[index] == null) { // going through all books in user's library for this index in ListView (only done once due to this check)
            alreadyAddedBooks[index] = false;
            for (int i = 0; i < userLibrary.length; i++) {
              if (currentBook == userLibrary[i]) {
                alreadyAddedBooks[index] = true;
              }
            }
          }
          if (alreadyAddedBooks[index] == true) {
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
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
                          bookAddButtonClicked(currentBook, context, setState);
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
