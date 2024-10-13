import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book.dart';
import 'package:library_project/database.dart';

class AddBookPage extends StatelessWidget {
  final controllerAuthor = TextEditingController();
  final controllerTitle = TextEditingController();
  final User user;

  AddBookPage(this.user, {super.key});

  void onSubmit(BuildContext context) {
    if (controllerAuthor.text != "" && controllerTitle.text != "") {
      Book book = Book(controllerTitle.text, controllerAuthor.text, true);
      book.setId(addBook(book, user));
      exampleLibrary.add(book);
      Navigator.pop(context);
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
              const Text(
                "Title:",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(
                height: 5,
              ),
              TextField(
                controller: controllerTitle,
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
                controller: controllerAuthor,
                decoration: const InputDecoration(
                    fillColor: Colors.white, filled: true),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  onPressed: () {onSubmit(context);},
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
                  child: const Text('Add Book', style: TextStyle(fontSize: 16, color: Colors.black)))
            ],
          ),
        ));
  }
}
