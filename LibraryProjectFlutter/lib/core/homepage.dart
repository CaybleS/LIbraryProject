import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/book_requests_page.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/book/book_page.dart';
import 'package:library_project/book/borrowed_book_page.dart';
import 'package:library_project/ui/colors.dart';
import 'appbar.dart';

enum _SortingOption { dateAdded, title, author }

enum _BooksShowing { all, fav, lent, lentToMe }

class HomePage extends StatefulWidget {
  final User user;

  const HomePage(this.user, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<int> _shownList =
      []; // this is the "driver" list which dictates what books in shownLibrary are visible, and in what order, by storing indicies of books in shownLibrary
  List<int> _unsortedShownList =
      []; // needed to always be able to sort by 'date added" even when shownList changes to sort by title
  List<Book> _shownLibrary = [];
  bool _usingBooksLentToMe = false;
  late final VoidCallback _homepageListener; // used to run some stuff everytime we go to this page from the bottombar
  final TextEditingController _searchBarTextController = TextEditingController();
  _SortingOption _sortSelection = _SortingOption.dateAdded;
  _BooksShowing _showing = _BooksShowing.all;
  bool _sortingAscending = true; // needed to sort from A-Z or Z-A (i need to get to my zucchini book ya know)
  bool _showEmptyLibraryMsg =
      false; // just a message to show if user has no books in their library. Arguably not needed but the page may be confusing without it IMO.

  @override
  void initState() {
    super.initState();
    _homepageListener = () {
      if (refreshNotifier.value == homepageIndex) {
        if (userLibrary.isEmpty) {
          _showEmptyLibraryMsg = true;
        } else {
          _showEmptyLibraryMsg = false;
        }
        _updateList();
      }
    };
    refreshNotifier.addListener(_homepageListener);
  }

  @override
  void dispose() {
    refreshNotifier.removeListener(_homepageListener);
    _searchBarTextController.dispose();
    super.dispose();
  }

  // note that these sorting and filtering functions are only changing the composition of shownList.
  void _sortByDateAdded() {
    _shownList = List.from(_unsortedShownList);
    if (!_sortingAscending) {
      _shownList = _shownList.reversed.toList();
    }
    setState(() {});
  }

  void _sortByTitle() {
    // since shownList stores indices of shownLibrary they are already mapped to each other making this sorting not too complex
    _shownList.sort(
        (a, b) => (_shownLibrary[a].title ?? "No title found").compareTo(_shownLibrary[b].title ?? "No title found"));
    if (!_sortingAscending) {
      _shownList = _shownList.reversed.toList();
    }
    setState(() {});
  }

  void _sortByAuthor() {
    _shownList.sort((a, b) =>
        (_shownLibrary[a].author ?? "No author found").compareTo(_shownLibrary[b].author ?? "No author found"));
    if (!_sortingAscending) {
      _shownList = _shownList.reversed.toList();
    }
    setState(() {});
  }

  bool _isFilterTextOneOfTheIndividualWords(List<String> individualWordsToFilter, String filterText) {
    if (individualWordsToFilter.length < 2) {
      // in this case there is only 0 or 1 words detected, which defeats the whole purpose of this function
      return false;
    }
    for (int i = 0; i < individualWordsToFilter.length; i++) {
      if (individualWordsToFilter[i] == filterText) {
        return true;
      }
    }
    return false;
  }

  // so if you filter search for exactly title and author in that order, it will show up
  bool _isFilterTextTitleAndAuthor(String filterText, Book book) {
    if ("${(book.title ?? "no title found").toLowerCase()} ${(book.author ?? "no author found").toLowerCase()}"
        .contains(filterText)) {
      return true;
    }
    return false;
  }

  // this doesn't change the shownLibrary list at all, it simply changes the shownList list (which only contains indicies of books to show inside of shownLibrary)
  void _filter(String filterText) {
    filterText = filterText.toLowerCase().trim();
    if (filterText.isEmpty) {
      _setShownListWithNoFilters();
    } else {
      List<int> newShownList = [];
      List<String> individualWordsToFilter = filterText.split(" ");
      for (int i = 0; i < _shownLibrary.length; i++) {
        if ((_shownLibrary[i].title?.toLowerCase() ?? "no title found").contains(filterText) ||
            (_shownLibrary[i].author?.toLowerCase() ?? "no author found").contains(filterText) ||
            _isFilterTextOneOfTheIndividualWords(individualWordsToFilter, filterText) ||
            _isFilterTextTitleAndAuthor(filterText, _shownLibrary[i])) {
          newShownList.add(i);
        }
      }
      if (listEquals(newShownList, _shownList)) {
        // optimization to prevent unnecessary rebuilds (if shownList doesn't change, no need to setState)
        return;
      } else {
        _shownList = List.from(newShownList);
        _unsortedShownList = List.from(newShownList);
      }
    }
    switch (_sortSelection) {
      // note that these sort by functions all perform setState
      case _SortingOption.dateAdded:
        _sortByDateAdded();
        break;
      case _SortingOption.title:
        _sortByTitle();
        break;
      case _SortingOption.author:
        _sortByAuthor();
        break;
    }
  }

  void _resetFilters() {
    _sortingAscending = true;
    _sortSelection = _SortingOption.dateAdded;
    _showing = _BooksShowing.all;
    _searchBarTextController.clear();
    _filter("");
  }

  void _bookClicked(int index) async {
    if (_usingBooksLentToMe) {
      await Navigator.push(
          context, MaterialPageRoute(builder: (context) => BorrowedBookPage(booksLentToMe[index], widget.user)));
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => BookPage(userLibrary[index], widget.user)));
    }
  }

  // this is needed to change the display button colors
  void _changeDisplay(_BooksShowing state) {
    _showing = state;
    _updateList();
  }

  void _setShownListWithNoFilters() {
    _shownList.clear();
    switch (_showing) {
      case _BooksShowing.all:
        _shownList = Iterable<int>.generate(userLibrary.length).toList();
        break;
      case _BooksShowing.fav:
        for (int i = 0; i < userLibrary.length; i++) {
          if (userLibrary[i].favorite) {
            _shownList.add(i);
          }
        }
        break;
      case _BooksShowing.lent:
        for (int i = 0; i < userLibrary.length; i++) {
          if (userLibrary[i].lentDbKey != null) {
            _shownList.add(i);
          }
        }
        break;
      case _BooksShowing.lentToMe:
        _usingBooksLentToMe = true;
        _shownList = Iterable<int>.generate(booksLentToMe.length).toList();
        break;
    }
    _unsortedShownList = List.from(_shownList);
  }

  void _updateList() {
    _usingBooksLentToMe = _showing == _BooksShowing.lentToMe;

    _setShownListWithNoFilters();
    _shownLibrary = _usingBooksLentToMe ? booksLentToMe.map((item) => item.book).toList() : userLibrary;
    if (_searchBarTextController.text.isNotEmpty) {
      // Idk why this works, basically this can be called anytime a book is added or when user goes to homepage so
      // in this case we want to both set the shown list and also apply any possible filters. A lot of this stuff seems
      // unnecessary to me but I guess with 2 filter systems (the _BooksShowing and filter bar) we need to consider both of them, which
      // is why prevShownList exists (we only show books with both filters applied to them).
      List<int> prevShownList = _shownList;
      _filter(_searchBarTextController.text);
      _shownList.removeWhere((item) => !prevShownList.contains(item));
      setState(() {});
    } else {
      // these sorting functions will call the setState
      switch (_sortSelection) {
        case _SortingOption.dateAdded:
          _sortByDateAdded();
          break;
        case _SortingOption.title:
          _sortByTitle();
          break;
        case _SortingOption.author:
          _sortByAuthor();
          break;
      }
    }
  }

  void _favoriteButtonClicked(int index) {
    userLibrary[index].favoriteButtonClicked();
    setState(() {});
  }

  IconData _getReadIcon(Book book) {
    switch (book.hasRead) {
      case ReadingState.notRead:
        return Icons.bookmark_remove;
      case ReadingState.currentlyReading:
        return Icons.auto_stories;
      case ReadingState.read:
        return Icons.book;
      case null:
        return Icons.question_mark;
    }
  }

  Widget _displayFilterDropdown() {
    return MenuAnchor(
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(
            Icons.tune,
            size: 30,
            color: Colors.black45,
          ),
        );
      },
      menuChildren: [
        Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  "Sort by",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Divider(),
            SizedBox(
              height: 40,
              width: 100,
              child: MenuItemButton(
                onPressed: () {
                  if (_sortSelection != _SortingOption.dateAdded) {
                    _sortingAscending = true;
                    _sortSelection = _SortingOption.dateAdded;
                  } else {
                    _sortingAscending = !_sortingAscending;
                  }
                  _sortByDateAdded();
                },
                child: Row(
                  children: [
                    const SizedBox(
                      width: 45,
                      child: Text("date added", style: TextStyle(fontSize: 12)),
                    ),
                    (_sortSelection == _SortingOption.dateAdded)
                        ? const Padding(
                            padding: EdgeInsets.only(left: 6), child: Icon(Icons.check, color: Colors.green, size: 25))
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            const Divider(),
            SizedBox(
              height: 40,
              width: 100,
              child: MenuItemButton(
                onPressed: () {
                  if (_sortSelection != _SortingOption.title) {
                    _sortingAscending = true;
                    _sortSelection = _SortingOption.title;
                  } else {
                    _sortingAscending = !_sortingAscending;
                  }
                  _sortByTitle();
                },
                child: Row(
                  children: [
                    const SizedBox(
                      width: 45,
                      child: Text("title", style: TextStyle(fontSize: 12)),
                    ),
                    (_sortSelection == _SortingOption.title)
                        ? const Padding(
                            padding: EdgeInsets.only(left: 6), child: Icon(Icons.check, color: Colors.green, size: 25))
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            const Divider(),
            SizedBox(
              height: 40,
              width: 100,
              child: MenuItemButton(
                onPressed: () {
                  if (_sortSelection != _SortingOption.author) {
                    _sortingAscending = true;
                    _sortSelection = _SortingOption.author;
                  } else {
                    _sortingAscending = !_sortingAscending;
                  }
                  _sortByAuthor();
                },
                child: Row(
                  children: [
                    const SizedBox(
                      width: 45,
                      child: Text("author", style: TextStyle(fontSize: 12)),
                    ),
                    (_sortSelection == _SortingOption.author)
                        ? const Padding(
                            padding: EdgeInsets.only(left: 6), child: Icon(Icons.check, color: Colors.green, size: 25))
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            const Divider(),
            SizedBox(
              height: 40,
              width: 100,
              child: MenuItemButton(
                onPressed: () {
                  _resetFilters();
                },
                child: const Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Text("reset filters", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _displayShowButtons() {
    List<Color> buttonColor = List.filled(4, AppColor.skyBlue);

    switch (_showing) {
      case _BooksShowing.all:
        buttonColor[0] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case _BooksShowing.fav:
        buttonColor[1] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case _BooksShowing.lent:
        buttonColor[2] = const Color.fromARGB(255, 117, 117, 117);
        break;
      case _BooksShowing.lentToMe:
        buttonColor[3] = const Color.fromARGB(255, 117, 117, 117);
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor[0],
            padding: const EdgeInsets.all(8),
          ),
          onPressed: () {
            if (_showing != _BooksShowing.all) {
              _changeDisplay(_BooksShowing.all);
            }
          },
          child: const Text("All", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor[1],
            padding: const EdgeInsets.all(8),
          ),
          onPressed: () {
            if (_showing != _BooksShowing.fav) {
              _changeDisplay(_BooksShowing.fav);
            }
          },
          child: const Text("Favorites", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor[2],
            padding: const EdgeInsets.all(8),
          ),
          onPressed: () {
            if (_showing != _BooksShowing.lent) {
              _changeDisplay(_BooksShowing.lent);
            }
          },
          child: const Text("Lent", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor[3],
            padding: const EdgeInsets.all(8),
          ),
          onPressed: () {
            if (_showing != _BooksShowing.lentToMe) {
              _changeDisplay(_BooksShowing.lentToMe);
            }
          },
          child: const Text("Lent to me", style: TextStyle(color: Colors.black, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _displayInfoOnRequests() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("You have ${receivedBookRequests.length} outstanding book requests."),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 5),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.skyBlue,
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => BookRequestsPage(widget.user)));
            },
            child: const Text(
              "View",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(curPage: "home"),
      backgroundColor: Colors.grey[400],
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 10, 8, 5), child: _displayShowButtons()),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 8, 19, 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchBarTextController,
                    onChanged: (text) {
                      _filter(text);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Filter by title or author",
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _filter(""); // needed to signal to the filtering that there is no more filter being applied
                          _searchBarTextController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ),
                _displayFilterDropdown(),
              ],
            ),
          ),
          (_showEmptyLibraryMsg && _showing == _BooksShowing.all)
              ? const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child:
                      Text("Add books to view your library here", style: TextStyle(fontSize: 14, color: Colors.black)))
              : const SizedBox.shrink(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 9, 7, 6),
              child: ListView.builder(
                itemCount: _shownList.length,
                itemBuilder: (BuildContext context, int index) {
                  Widget coverImage = _shownLibrary[_shownList[index]].getCoverImage();
                  String availableTxt;
                  Color availableTxtColor;

                  if (_shownLibrary[_shownList[index]].lentDbKey != null) {
                    availableTxt = "Lent";
                    availableTxtColor = Colors.red;
                  } else {
                    availableTxt = "Available";
                    availableTxtColor = const Color(0xFF43A047);
                  }

                  Icon favIcon;
                  if (_shownLibrary[_shownList[index]].favorite) {
                    favIcon = const Icon(Icons.favorite);
                  } else {
                    favIcon = const Icon(Icons.favorite_border);
                  }
                  return InkWell(
                    onTap: () {
                      _bookClicked(_shownList[index]);
                    },
                    child: SizedBox(
                      height: 110,
                      child: Card(
                        margin: const EdgeInsets.all(5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(_getReadIcon(_shownLibrary[_shownList[index]])),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 1, 10, 1),
                              child: AspectRatio(
                                aspectRatio: 0.7,
                                child: coverImage,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(
                                      height: 12), // change this if you change card size id say to center the row
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      _shownLibrary[_shownList[index]].title ?? "No title found",
                                      style: const TextStyle(color: Colors.black, fontSize: 18),
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      _shownLibrary[_shownList[index]].author ?? "No author found",
                                      style: const TextStyle(color: Colors.black, fontSize: 14),
                                      softWrap: true,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _usingBooksLentToMe
                                ? const SizedBox.shrink()
                                : SizedBox(
                                    width: 80,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Flexible(
                                          child: Text(
                                            "Status:",
                                            style: TextStyle(color: Colors.black, fontSize: 16),
                                            softWrap: true,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            availableTxt,
                                            style: TextStyle(color: availableTxtColor, fontSize: 16),
                                            softWrap: true,
                                          ),
                                        ),
                                        Flexible(
                                          child: IconButton(
                                            onPressed: () => {_favoriteButtonClicked(_shownList[index])},
                                            icon: favIcon,
                                            splashColor: Colors.white,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
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
          ),
          _displayInfoOnRequests(),
        ],
      ),
    );
  }
}
