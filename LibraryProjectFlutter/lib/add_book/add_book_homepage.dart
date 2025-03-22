import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/add_book/custom_add/custom_add.dart';
import 'package:shelfswap/add_book/goodreads/goodreads_dialog.dart';
import 'package:shelfswap/add_book/scan/scanner_driver.dart';
import 'package:shelfswap/add_book/search/search_driver.dart';
import 'package:shelfswap/core/appbar.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'package:shelfswap/ui/colors.dart';

class AddBookHomepage extends StatefulWidget {
  final User user;

  @override
  State<AddBookHomepage> createState() => _AddBookHomepageState();
  const AddBookHomepage(this.user, {super.key});
}

class _AddBookHomepageState extends State<AddBookHomepage> {
  final _searchQueryController = TextEditingController();
  late SearchDriver _bookSearchInstance;
  late ScannerDriver _bookScanInstance;
  bool _displayProgressIndicator = false; // used to display CircularProgressIndicator whenever necessary
  bool _noInput = false;
  late final VoidCallback _addBookListener; // used to run some stuff everytime we go to this page from the bottombar

  @override
  void initState() {
    super.initState();
    _searchQueryController.addListener(() {
      if (_noInput && _searchQueryController.text.isNotEmpty) {
        setState(() {
          _noInput = false;
        });
    }});
    // done because I cant access widget.<anything> before initState, hence the late object initialization
    _bookSearchInstance = SearchDriver(widget.user, userLibrary);
    _bookScanInstance = ScannerDriver(widget.user, userLibrary);
    _addBookListener = () {
      // since offstage loads this page into memory at all times via the bottombar we just run the refresh logic if its the selectedIndex
      if (selectedIndex == addBookPageIndex) {
        _bookSearchInstance.clearAlreadyAddedBooks();
        setState(() {});
      }
    };
    pageDataUpdatedNotifier.addListener(_addBookListener);
  }

  @override
  void dispose() {
    _searchQueryController.dispose();
    pageDataUpdatedNotifier.removeListener(_addBookListener);
    super.dispose();
  }

  void _resetNoInput() {
    if (_noInput) {
      _noInput = false;
      setState(() {});
    }
  }

  Future<void> _searchButtonClicked() async {
     // I forgot to trim the text input :/ kind of important. I also convert to lowercase since as of now I think google books and openlibrary api
     // both search case-insensitively so now if user searches f and then F for example it won't try to search again unnecessarily, it knows they are same
    String searchQuery = _searchQueryController.text.trim().toLowerCase();
    if (searchQuery.isEmpty) {
      // since I trim the searchQuery, I just clear the controller in the case where user enters only
      // spaces. I don't know if this is optimal but I think its fine.
      _searchQueryController.clear();
      if (!_noInput) {
        _noInput = true;
        setState(() {});
      }
      return;
    }
    if (_displayProgressIndicator) { // preventing search button from doing anything while a search is already occuring
      return;
    }
    setState(() {
      _displayProgressIndicator = true;
    });
    await _bookSearchInstance.runSearch(searchQuery, context);
    setState(() {
      _displayProgressIndicator = false;
    });
  }

  Future<void> _scanButtonClicked() async {
    if (_displayProgressIndicator) {
      return;
    }
    _searchQueryController.clear();
    _resetNoInput();
    setState(() {
      _displayProgressIndicator = true;
    });
    String? scannedISBN = await _bookScanInstance.runScanner(context);
    // after scanning, the scanner pops here and a search by isbn occurs. However I want to clear the last search values before this search
    // occurs, so that for example the search info helper text gets cleared. It's convoluted logic but it works.
    if (scannedISBN != null) {
      _bookSearchInstance.resetLastSearchValues();
      setState(() {});
    }
    if (mounted && scannedISBN != null) {
      await _bookScanInstance.scannerSearchByIsbn(context, scannedISBN);
    }
    setState(() {
      _displayProgressIndicator = false;
    });
  }

  Future<void> _customAddButtonClicked() async {
    _resetNoInput();
    // I clear the search results when user comes back to this page ONLY if a book was added (there is only a return value if it pops when adding a book)
    String? retVal = await Navigator.push(context, MaterialPageRoute(builder: (context) => CustomAdd(widget.user, userLibrary)));
    if (retVal != null) {
      _bookSearchInstance.resetLastSearchValues();
      _searchQueryController.clear();
      setState(() {});
    }
  }

  Widget _otherOptionButton(String buttonText, Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: () async {
        await onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.skyBlue,
        padding: const EdgeInsets.all(8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }

  Widget _displayFilterDropdown() {
    return MenuAnchor(
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
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
                  "Search by",
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
                  _bookSearchInstance.setSearchQueryOption(SearchQueryOption.normal);
                  setState(() {});
                },
                child: Row(
                  children: [
                    const SizedBox(
                      width: 45,
                      child: Text("normal", style: TextStyle(fontSize: 12)),
                    ),
                     (_bookSearchInstance.getSearchQueryOption() == SearchQueryOption.normal)
                        ? const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.check,
                                color: Colors.green, size: 25))
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
                  _bookSearchInstance.setSearchQueryOption(SearchQueryOption.title);
                  setState(() {});
                },
                child: Row(
                  children: [
                    const SizedBox(
                      width: 45,
                      child: Text("title", style: TextStyle(fontSize: 12)),
                    ),
                     (_bookSearchInstance.getSearchQueryOption() == SearchQueryOption.title)
                        ? const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.check,
                                color: Colors.green, size: 25))
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
                  _bookSearchInstance.setSearchQueryOption(SearchQueryOption.author);
                  setState(() {});
                },
                child: Row(
                  children: [
                    const SizedBox(
                      width: 45,
                      child: Text("author", style: TextStyle(fontSize: 12)),
                    ),
                    (_bookSearchInstance.getSearchQueryOption() == SearchQueryOption.author)
                        ? const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.check,
                                color: Colors.green, size: 25))
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getTextFieldHelperText() {
    switch (_bookSearchInstance.getSearchQueryOption()) {
      case SearchQueryOption.normal:
        return "Search titles, authors, or keywords";
      case SearchQueryOption.title:
        return "Search titles";
      case SearchQueryOption.author:
        return "Search authors";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        widget.user, title: "Add Books",
        actions: [
          InkWell(
            onTap: () async {
              await displayGoodreadsDialog(context, widget.user);
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: Image.asset(
                  "assets/goodreads_logo.jpg",
                fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(height: 6),
                Row (
                  children: [
                    _displayFilterDropdown(),
                    Expanded(
                      child: TextField(
                        controller: _searchQueryController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) { // this parameter for onSubmitted is just the controller.text
                          _searchButtonClicked();
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: _getTextFieldHelperText(),
                          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25.0)),
                          ),
                          errorText: _noInput ? "Please enter some text" : null,
                          suffixIcon: IconButton(
                            onPressed: () {
                              _searchQueryController.clear();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                        onTapOutside: (event) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible( child: _otherOptionButton("Scan Barcode", _scanButtonClicked)),
                    Flexible( child: _otherOptionButton("Add Manually", _customAddButtonClicked)),
                  ],
                ),
                const SizedBox(height: 8),
                // This search button technically isn't needed since the textInputAction part of the text field can search
                // plus there could be a search prefixIcon for the text field. But I'm keeping it because I think it makes
                // the page look better.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _searchButtonClicked();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.skyBlue,
                      padding: const EdgeInsets.all(8),
                    ),
                    child: const Text(
                      "Search",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
                _bookSearchInstance.getSearchInfoWidget(),
              ],
            ),
          ),
          _displayProgressIndicator
            ? SharedWidgets.displayCircularProgressIndicator()
            : _bookSearchInstance.displaySearchResults(setState) // can also just display literally nothing if no results (like if page first loads)
        ],
      ),
    );
  }
}
