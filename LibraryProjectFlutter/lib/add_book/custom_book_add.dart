import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/core/book.dart';
import 'package:library_project/add_book/shared_helper_util.dart';

class CustomBookAdd extends StatelessWidget {
  final User user;
  final _inputTitleController = TextEditingController();
  final _inputAuthorController = TextEditingController();

  CustomBookAdd(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Text(
            "Title:",
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(
            height: 5,
          ),
          TextField(
            controller: _inputTitleController,
            decoration: const InputDecoration(
              fillColor: Colors.white, filled: true),
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            "Author:",
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(
            height: 5,
          ),
          TextField(
            controller: _inputAuthorController,
            decoration: const InputDecoration(
              fillColor: Colors.white, filled: true),
          ),
          const SizedBox(
          height: 10,
          ),
          ElevatedButton(
            onPressed: () {
              Book customAddedBook = Book(_inputTitleController.text, _inputAuthorController.text, SharedHelperUtil.defaultBookCover, "No description found", "No categories found", isManualAdded: true);
              SharedHelperUtil.addBookToLibrary(context, customAddedBook, user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
            ),
            child: const Text("Add Book", style: TextStyle(fontSize: 16, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}