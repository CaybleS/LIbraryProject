// this file is just basic prototype of a popup page so that users while searching can just click on a book and view more info about it
// ideally when book_page is finished this page will then be modified to look similar to it. Its just basic functionality for now.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/core/book.dart';

class BookDetailsScreen extends StatelessWidget {
  final Book bookToView;
  final User user;
  const BookDetailsScreen(this.bookToView, this.user, {super.key});

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
                    child: Image.network(
                      bookToView.coverUrl.toString(),
                      fit: BoxFit.fill,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(children: [
                    SizedBox(
                        width: 200,
                        child: Text(
                          bookToView.title,
                          style: const TextStyle(fontSize: 30),
                        )),
                    const SizedBox(height: 5),
                    SizedBox(
                        width: 200,
                        child: Text(bookToView.author,
                            style: const TextStyle(fontSize: 25))),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 200,
                      child: Text(
                        bookToView.description,
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
              ElevatedButton(
                onPressed: () {
                  SharedHelperUtil.addBookToLibrary(context, bookToView, user);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
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
