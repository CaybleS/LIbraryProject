import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book/custom_add/custom_add.dart';
import 'package:library_project/add_book/scan/scanner_driver.dart';
import 'package:library_project/add_book/search/search_driver.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'package:library_project/ui/colors.dart';

class AddBookHomepage extends StatefulWidget {
  final User user;
  final List<Book> userLibrary;

  @override
  State<AddBookHomepage> createState() => _AddBookHomepageState();
  const AddBookHomepage(this.user, this.userLibrary, {super.key});
}

class _AddBookHomepageState extends State<AddBookHomepage> {
  final _searchQueryController = TextEditingController();
  late SearchDriver _bookSearchInstance;
  late ScannerDriver _bookScanInstance;
  bool _displayProgressIndicator = false; // used to display CircularProgressIndicator whenever necessary
  bool _noInput = false;

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
    _bookSearchInstance = SearchDriver(widget.user, widget.userLibrary);
    _bookScanInstance = ScannerDriver(widget.user, widget.userLibrary);
  }

  @override
  void dispose() {
    _searchQueryController.dispose();
    super.dispose();
  }

  void _resetNoInput() {
    if (_noInput) {
      _noInput = false;
      setState(() {});
    }
  }

  Future<void> _searchButtonClicked() async {
    String searchQuery = _searchQueryController.text;
    if (searchQuery.isEmpty) {
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
    if (scannedISBN != null) {
      // putting the scanned ISBN into the search query, for better user experience, done after the search rather than before
      _searchQueryController.text = scannedISBN;
    }
    setState(() {
      _displayProgressIndicator = false;
    });
  }

  Future<void> _customAddButtonClicked() async {
    _resetNoInput();
    // I clear the search results when user comes back to this page ONLY if a book was added (there is only a return value if it pops when adding a book)
    String? retVal = await Navigator.push(context, MaterialPageRoute(builder: (context) => CustomAdd(widget.user, widget.userLibrary)));
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
        minimumSize: const Size(0, 0),
        padding: const EdgeInsets.all(8),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[400],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text(
                  "Add Books",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
                const SizedBox(height: 4),
                SharedWidgets.displayTextField("Search titles, authors, or keywords", _searchQueryController, _noInput, "Please enter some text"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 1), // these basically only do things cuz of the row's mainAxisAlignment
                    _otherOptionButton("Scan Barcode", _scanButtonClicked),
                    _otherOptionButton("Add Manually", _customAddButtonClicked),
                    const SizedBox(width: 1),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _searchButtonClicked();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.skyBlue,
                      minimumSize: const Size(0, 0),
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
