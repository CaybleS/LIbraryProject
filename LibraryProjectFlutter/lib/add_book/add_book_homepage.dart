// note that the API returns a JSON-formatted response body, with specific keywords to specify each value. The Google api
// returns the results in a 'items' list, and openlibrary api returns the results in a 'docs' list.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/core/book.dart';
import 'package:library_project/add_book/search_book.dart';
import 'package:library_project/add_book/scanner_driver.dart';
import 'package:library_project/add_book/custom_book_add.dart';

enum _AddBookOptions {search, scan, custom}

class AddBookHomepage extends StatefulWidget {
  final User user;

  @override
  State<AddBookHomepage> createState() => _AddBookHomepageState();
  const AddBookHomepage(this.user, {super.key});
}

class _AddBookHomepageState extends State<AddBookHomepage> {
  Set<_AddBookOptions> selection = <_AddBookOptions>{_AddBookOptions.search};
  Book? bookFromISBNScan;

  Widget printSelectionOption(_AddBookOptions selection) {
    switch (selection) {
      case _AddBookOptions.search:
        return SearchBook(widget.user);
      case _AddBookOptions.scan:
        return ScannerDriver(widget.user);
      case _AddBookOptions.custom:
        return CustomBookAdd(widget.user);
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
                  selection = newSelection; // guaranteed the selection set will only have 1 element
                });
              },
              segments: const <ButtonSegment<_AddBookOptions>> [
                ButtonSegment(
                  icon: Icon(Icons.search),
                  value: _AddBookOptions.search,
                  label: Text("search"),
                ),
                ButtonSegment(
                  icon: Icon(Icons.camera_alt_sharp),
                  value: _AddBookOptions.scan,
                  label: Text("scan"),
                ),
                ButtonSegment(
                  icon: Icon(Icons.draw_sharp),
                  value: _AddBookOptions.custom,
                  label: Text("manual entry"),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            printSelectionOption(selection.single),
          ],
        ),
      ),
    );
  }
}
