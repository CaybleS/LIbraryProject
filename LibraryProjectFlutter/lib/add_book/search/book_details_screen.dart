// this file is just basic prototype of a popup page so that users while searching can just click on a book and view more info about it.
// When book_page is finished this page will then be modified to look similar to it. Its just basic functionality for now.
// I can guarantee that this page needs a "remove book" button, to easily deal with add book misclicks and just for better user experience

import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/ui/colors.dart';

class BookDetailsScreen extends StatelessWidget {
  final Book _bookToView;
  final bool _isBookAlreadyAdded;
  const BookDetailsScreen(this._bookToView, this._isBookAlreadyAdded, {super.key});

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
              Row(
                children: [
                  SizedBox(
                    height: 200,
                    width: 140,
                    child: _bookToView.getCoverImage(),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(children: [
                    SizedBox(
                        width: 200,
                        child: Text(
                          _bookToView.title ?? "No title found",
                          style: const TextStyle(fontSize: 30),
                        )),
                    const SizedBox(height: 5),
                    SizedBox(
                        width: 200,
                        child: Text(_bookToView.author ?? "No author found",
                            style: const TextStyle(fontSize: 25))),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 200,
                      child: Text(
                        _bookToView.description ?? "No description found",
                        style: const TextStyle(fontSize: 12),
                        softWrap: true,
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ])
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              _isBookAlreadyAdded
              ? const Text("Book is already added!")
              : ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, "added"); // this text 'added' will signal to the page above it on the stack, that the user added this book
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.pink,
                ),
                child: const Text('Add Book',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ],
          ),
        ));
  }
}
