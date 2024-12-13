import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:library_project/book/book.dart';
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/add_book/book_details_screen.dart';

class SearchBook extends StatefulWidget {
  final User user;

  @override
  State<SearchBook> createState() => _SearchBookState();
  const SearchBook(this.user, {super.key});
}

class _SearchBookState extends State<SearchBook> {

  final searchQueryController = TextEditingController();
  bool isSearching = false; // used to display CircularProgressIndicator when searching
  bool usingGoogleAPI = true;
  bool otherSearchError = false;
  bool pressedSearchOnEmptyError = false;
  bool noBooksFoundError = false;
  bool noResponseError = false; // this detects lack of internet connection (or api being down maybe)
  int resultsPageIndex = 0;
  List<dynamic> searchQueryBooks = [];
  static const int numBooksPerPage = 8; // TODO determine best value for this (or is it better to just show <= 40 books in a column? surely not right)

  Future<void> searchWithOpenLibrary(String searchQuery) async {
    final String endpoint = "https://openlibrary.org/search.json?q=$searchQuery&limit=40";
    http.Response? response;
    try {
      response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        searchQueryBooks = json.decode(response.body)['docs'] ?? [];
      }
      else {
        otherSearchError = true;
      }
    } catch (e) {
      if (response == null) {
        noResponseError = true;
      }
      otherSearchError = true;
    }
  }

  Future<void> searchWithGoogle(String searchQuery) async {
    final String endpoint = "https://www.googleapis.com/books/v1/volumes?q=$searchQuery&key=${SharedHelperUtil.apiKey}&startIndex=0&maxResults=40";
    http.Response? response;
    try {
      response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        searchQueryBooks = json.decode(response.body)['items'] ?? [];
      } // with a bad response we just fallback to openlibrary api
      else {
        usingGoogleAPI = false;
        await searchWithOpenLibrary(searchQuery);
      }
    } catch(e) {
      if (response == null) {
        noResponseError = true;
      }
      else {
        otherSearchError = true;
      }
    }
  }

  Future<void> searchForBooks() async {
    // these values are only relevant to most recent search
    searchQueryBooks.clear();
    otherSearchError = false;
    pressedSearchOnEmptyError = false;
    noBooksFoundError = false;
    noResponseError = false;
    resultsPageIndex = 0;
    String searchQuery = searchQueryController.text;
    if (searchQuery == "") {
      setState(() {
        pressedSearchOnEmptyError = true;
      });
    }
    else {
      usingGoogleAPI ? await searchWithGoogle(searchQuery) : await searchWithOpenLibrary(searchQuery);
    }
    if (searchQueryBooks.isEmpty) {
      noBooksFoundError = true;
    }
    // note that a setState is needed here to display whatever search result occurs, its done by the function which calls this one so
  }

  String getSearchFailMessage() {
    if (pressedSearchOnEmptyError) {
      return "Please enter some text";
    }
    else if (noResponseError) {
      return "No response. Either the service is down or you have no internet!";
    }
    else if (noBooksFoundError) {
      return "No books found";
    }
    else if (otherSearchError) { // in general otherSearchError should be the last explicit error (the lowest priority one to show to the user)
      return "Error with book search, please try again in a few minutes!";
    } 
    else {
      return "";
    }
  }

  void bookClicked(Book bookToView, User user) async {
    await Navigator.push(context, MaterialPageRoute(builder: (ctx) {
      return BookDetailsScreen(bookToView, widget.user);
    }));
    setState(() {});
  }

  Widget buildSearchBottomBar() {
    return Row(
      children: [
        SizedBox(
          height: 40,
          width: 150,
          child: (resultsPageIndex != 0)
            ? ElevatedButton(
              onPressed: () {
              resultsPageIndex--;
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
            ),
            child: const Text("Previous",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          )
          : const Text(""),
        ),
        const SizedBox(
          height: 10,
          width: 10,
        ),
        SizedBox(
          height: 40,
          width: 150,
          child: (searchQueryBooks.length > resultsPageIndex * numBooksPerPage + numBooksPerPage)
            ? ElevatedButton(
              onPressed: () {
              resultsPageIndex++;
              setState((){});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
            ),
            child: const Text("Next",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          )
          : const Text(""),
        ),
        const SizedBox(
          height: 10,
          width: 10,
        ),
        if (searchQueryBooks.length > numBooksPerPage)
          Text("Pg ${resultsPageIndex + 1}"), // TODO is this fine, to make it not appear if theres only 1 page of results? idk!
      ],
    );
  }

  Widget displayIndexedBooks() {
    int numBooksToDisplay;
    // if the current index doesnt have numBooksPerPage books we need to make sure we dont try to display that many
    if (searchQueryBooks.length - resultsPageIndex * numBooksPerPage < numBooksPerPage) {
      numBooksToDisplay = searchQueryBooks.length - resultsPageIndex * numBooksPerPage;
    }
    else {
      numBooksToDisplay = numBooksPerPage;
    }
    return SizedBox(
      height: 500,
      child: ListView.builder(
        itemCount: numBooksToDisplay,
        itemBuilder: (BuildContext context, int index) {
          index = index + resultsPageIndex * numBooksPerPage;
          Widget image;
          // using ?[] to access array indicies safely even if they're null, and ?? is if-null operator which has placeholder values to the right
          // if any are null the placeholder is used.
          String title, author, coverUrl, description, categories;
          if (usingGoogleAPI) {
            title = searchQueryBooks[index]?['volumeInfo']?['title'] ?? "No title found";
            author = searchQueryBooks[index]?['volumeInfo']?['authors']?[0] ?? "No author found";
            coverUrl = searchQueryBooks[index]?['volumeInfo']?['imageLinks']?['thumbnail'] ?? SharedHelperUtil.defaultBookCover;
            description = searchQueryBooks[index]?['volumeInfo']?['description'] ?? "No description found";
            categories = searchQueryBooks[index]?['volumeInfo']?['categories']?.join(", ") ?? "No categories found";
          } 
          else {
            title = searchQueryBooks[index]?['title'] ?? "No title found";
            author = searchQueryBooks[index]?['author_name']?[0] ?? "No author found";
              coverUrl = searchQueryBooks[index]?['cover_i'] != null
              ? "https://covers.openlibrary.org/b/id/${searchQueryBooks[index]?['cover_i']}-M.jpg"
              : SharedHelperUtil.defaultBookCover;
            description = "Description not available"; // TODO for openlibrary there is no description straight up, unfortunate, mby due to this add openlibrary msg when users fallback to it
            categories = "Categories not available";
          }
          Book currentBook = Book(title, author, coverUrl, description, categories);
          image = Image.network(coverUrl.toString());
          return InkWell(
            onTap: () {
              bookClicked(currentBook, widget.user);
            },
            child: Card(
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
                                color: Colors.black, fontSize: 20,
                              ),
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
                        SharedHelperUtil.addBookToLibrary(context, currentBook, widget.user);
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
            ),
          );
        },
      ),
    );
  }

  Widget displaySearchResults() {
    return Column(
      children: [
        searchQueryBooks.isEmpty ? Text(getSearchFailMessage()) : displayIndexedBooks(),
        buildSearchBottomBar(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchQueryController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search titles, authors, or keywords',
            hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
            ),
            suffixIcon: IconButton(
              onPressed: searchQueryController.clear,
              icon: const Icon(Icons.clear),
            ),
          ),
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
        :  displaySearchResults(), // can just display nothing in the case when user first goes to the page
      ],
    );
  }
}
