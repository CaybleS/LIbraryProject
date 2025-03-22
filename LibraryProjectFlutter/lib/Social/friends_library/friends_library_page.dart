import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/Social/friends_library/friend_book_page.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/database/subscriptions.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/models/user.dart';
import 'package:shelfswap/ui/colors.dart';

enum _SortingOption {dateAdded, title, author}

class FriendsLibraryPage extends StatefulWidget {
  final UserModel friend;
  final User user;

  const FriendsLibraryPage(this.user, this.friend, {super.key});

  @override
  State<FriendsLibraryPage> createState() => _FriendsLibraryPageState();
}

class _FriendsLibraryPageState extends State<FriendsLibraryPage> {
  List<Book> _friendsLibrary = [];
  List<int> _shownList = []; // this is the "driver" list which dictates what books in friendsLibrary are visible, and in what order, by storing indicies of books in friendsLibrary
  List<int> _unsortedShownList = []; // needed to always be able to sort by "date added" even when shownList changes to sort by title
  final TextEditingController _filterBooksTextController = TextEditingController();
  _SortingOption _sortSelection = _SortingOption.dateAdded;
  bool _sortingAscending = true;
  bool _showEmptyLibraryMsg = false; // just a message to show if user has no books in their library. Arguably not needed but the page may be confusing without it IMO.
  late final VoidCallback _friendsBooksUpdatedListener;

  @override
  void initState() {
    super.initState();
    if (friendIdToLibrarySubscription[widget.friend.uid] == null) {
      friendIdToLibrarySubscription[widget.friend.uid] = setupFriendsBooksSubscription(friendIdToBooks, widget.friend.uid, friendsBooksUpdated);
    }
    _friendsBooksUpdatedListener = () {
      _friendsLibrary = List.from(friendIdToBooks[widget.friend.uid] ?? []);
      if (friendIdToBooks[widget.friend.uid]!.isEmpty) {
        _showEmptyLibraryMsg = true;
      }
      else {
        _showEmptyLibraryMsg = false;
      }
      _updateList();
    };
    pageDataUpdatedNotifier.addListener(_friendsBooksUpdatedListener);
    _friendsLibrary = List.from(friendIdToBooks[widget.friend.uid] ?? []);
    _updateList();
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_friendsBooksUpdatedListener);
    _filterBooksTextController.dispose();
    super.dispose();
  }

  // note that these sorting functions are only changing the composition of shownList.
  void _sortByDateAdded() {
  _shownList = List.from(_unsortedShownList);
    if (!_sortingAscending) {
      _shownList = _shownList.reversed.toList();
    }
    setState(() {});
  }

  void _sortByTitle() {
    // since shownList stores indices of shownLibrary they are already mapped to each other making this sorting not too complex
    _shownList.sort((a, b) => (_friendsLibrary[a].title?.trim().toLowerCase() ?? "No title found").compareTo
    (_friendsLibrary[b].title?.trim().toLowerCase() ?? "No title found"));
    if (!_sortingAscending) {
      _shownList = _shownList.reversed.toList();
    }
    setState(() {});
  }

  void _sortByAuthor() {
    _shownList.sort((a, b) => (_friendsLibrary[a].author?.trim().toLowerCase() ?? "No author found").compareTo
    (_friendsLibrary[b].author?.trim().toLowerCase() ?? "No author found"));
    if (!_sortingAscending) {
      _shownList = _shownList.reversed.toList();
    }
    setState(() {});
  }

  bool _isFilterTextOneOfTheIndividualWords(List<String> individualWordsToFilter, String filterText) {
    if (individualWordsToFilter.length < 2) { // in this case there is only 0 or 1 words detected, which defeats the whole purpose of this function
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
  if ("${(book.title ?? "no title found").toLowerCase()} ${(book.author ?? "no author found").toLowerCase()}".contains(filterText)) {
      return true;
    }
    return false;
  }

  // this doesn't change the shownLibrary list at all, it simply changes the shownList list (which only contains indicies of books to show inside of shownLibrary)
  void _filter(String filterText) {
    filterText = filterText.toLowerCase().trim();
    if (filterText.isEmpty) {
      _setShownListWithNoFilters();
    }
    else {
      List<int> newShownList = [];
      List<String> individualWordsToFilter = filterText.split(" ");
      for (int i = 0; i < _friendsLibrary.length; i++) {
        if ((_friendsLibrary[i].title?.toLowerCase() ?? "no title found").contains(filterText) 
        || (_friendsLibrary[i].author?.toLowerCase() ?? "no author found").contains(filterText)
        || _isFilterTextOneOfTheIndividualWords(individualWordsToFilter, filterText)
        || _isFilterTextTitleAndAuthor(filterText, _friendsLibrary[i])) {
          newShownList.add(i);
        }
      }
      if (listEquals(newShownList, _shownList)) { // optimization to prevent unnecessary rebuilds (if shownList doesn't change, no need to setState)
        return;
      }
      else {
        _shownList = List.from(newShownList);
        _unsortedShownList = List.from(newShownList);
      }
    }
    switch (_sortSelection) { // note that these sort by functions all perform setState
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
    _filterBooksTextController.clear();
    _filter("");
  }

  void _bookClicked(int index) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => FriendBookPage(widget.user, _friendsLibrary[index], widget.friend.uid)));
  }

  void _setShownListWithNoFilters() {
    _shownList.clear();
    _shownList = Iterable<int>.generate(_friendsLibrary.length).toList();
    _unsortedShownList = List.from(_shownList);
  }

  void _updateList() {
    _setShownListWithNoFilters();
    if (_filterBooksTextController.text.isNotEmpty) {
      _filter(_filterBooksTextController.text);
    }
    else {
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

  Widget _displayFilterDropdown() {
    return MenuAnchor(
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            }
            else {
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
                child: Text("Sort by", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  }
                  else {
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
                      ? const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.check, color: Colors.green, size: 25))
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
                  }
                  else {
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
                      ? const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.check, color: Colors.green, size: 25))
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
                  }
                  else {
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
                      ? const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.check, color: Colors.green, size: 25))
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          // the point of this row is to make a title "user's" books but make it not overflow while still showing "'s books" guaranteed
          mainAxisSize: MainAxisSize.min, // for some reason this is needed for centerTitle to work, dont ask me why I have no idea
          children: [
            Flexible(
              flex: 2,
              child: Text(
                widget.friend.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Flexible(
              child: Text("'s books"),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColor.appbarColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 12, 19, 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filterBooksTextController,
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
                          _filterBooksTextController.clear();
                        } ,
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
          (_showEmptyLibraryMsg) 
            ? const Padding(padding: EdgeInsets.only(top: 10), child: Text("They have no books added", style: TextStyle(fontSize: 14, color: Colors.black)))
            : const SizedBox.shrink(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 9, 7, 10),
              child: ListView.builder(
                itemCount: _shownList.length,
                itemBuilder: (BuildContext context, int index) {
                  Widget coverImage = _friendsLibrary[_shownList[index]].getCoverImage();
                  String availableTxt;
                  Color availableTxtColor;

                  if (_friendsLibrary[_shownList[index]].lentDbKey != null) {
                    availableTxt = "Lent";
                    availableTxtColor = Colors.red;
                  } else {
                    availableTxt = "Available";
                    availableTxtColor = const Color(0xFF43A047);
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
                              padding: const EdgeInsets.fromLTRB(10, 1, 10, 1),
                              child: AspectRatio(
                                aspectRatio: 0.7,
                                child: coverImage,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(height: 12), // change this if you change card size id say to center the row
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      _friendsLibrary[_shownList[index]].title ?? "No title found",
                                      style: const TextStyle(color: Colors.black, fontSize: 18),
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      _friendsLibrary[_shownList[index]].author ?? "No author found",
                                      style: const TextStyle(color: Colors.black, fontSize: 14),
                                      softWrap: true,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                            width: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Flexible(
                                  child:
                                    Text(
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
        ],
      ),
    );
  }
}
