import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/database/database.dart';

// its my personal api key, if anyone wants me to use one from shared email i can, i probably should tbh and then just cancel it when we do .env stuff but whatever
const String apiKey = "AIzaSyAqHeGVVwSiWJLfVMjF8K5gBbQcNucKuQY";
const int maxApiResponseSize = 40; // currently 40 is the max for google books api. I wouldn't change this value unless google books api increases its max

void addBookToLibrary(Book bookToAdd, User user, List<Book> userLibrary, BuildContext context) {
  bookToAdd.setId(addBook(bookToAdd, user));
  userLibrary.add(bookToAdd);
  displayBookAddedDialog(context);
}

bool areBooksSame(Book? book1, Book? book2) {
  if (book1 == null || book2 == null) { // if any books are null then they definitely wouldnt be the same ya feel me?
    return false;
  }
  if (book1.googleBooksId != null && (book1.googleBooksId == book2.googleBooksId)) {
    return true;
  }
  // I want to compare titles and authors as lowercase but I need to make sure nothing is null first
  if (book1.title == null || book2.title == null || book1.author == null || book2.author == null) {
    return false;
  }
  if (book1.title!.toLowerCase() == book2.title!.toLowerCase() && book1.author!.toLowerCase() == book2.author!.toLowerCase()) {
    return true;
  }
  return false;
}

void displayBookAddedDialog(BuildContext context) {
  bool hasPopped = false;
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      Future.delayed(const Duration(milliseconds: 600), () { // feel free to change duration as you see fit
        if (context.mounted && !hasPopped) {
          hasPopped = true;
          Navigator.pop(context);
        }
      });
      return Dialog( // this may make this longer since it overrides the child's set width, but it styles text in a way I like so
        child: Container(
          height: 40,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 2,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Book added",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(width: 20),
              Icon(
                Icons.check,
                color: Colors.green,
                size: 35,
              ),
            ],
          ),
        ),
      );
    }
  // I had barrierDismissable = true before, and with that, this was needed to prevent double popping when user clicks elsewhere on the screen (which pops this
  // dialog), at a similar time to the future's popping. I don't think this is needed with barrierDismissible = false, but keeping it to be safe cuz idk
  ).then((_) {
    hasPopped = true;
  });
}
