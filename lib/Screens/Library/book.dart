

import 'package:firebase_database/firebase_database.dart';

import 'database.dart';

List<Book> exampleLibrary = [
  Book("Lord of the Rings", "J.R.R. Tolkien", true),
  Book(
      "Alice's Adventures in Wonderland",
      "Lewis Carroll",
      imagePath: "assets/AliceCover.jpg",
      false),
  Book("The Lion, the Witch and the Wardrobe", "C.S. Lewis", true,
      imagePath: "assets/LionWitchCover.jpg"),
];

class Book {
  String title;
  String author;
  bool available;
  bool favorite = false;
  String? imagePath;
  late DatabaseReference _id;

  Book(this.title, this.author, this.available, {this.imagePath});

  void favoriteButtonClicked() {
    favorite = !favorite;
    update();
  }

  void setId(DatabaseReference id) {
    _id = id;
  }

  void update() {
    updateBook(this, _id);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'available': available,
      'favorite': favorite,
      'image': imagePath
    };
  }
}

Book createBook(record) {
  Book book = Book(record['title'], record['author'], record['available'],
      imagePath: record['image']);
  book.favorite = record['favorite'];

  return book;
}
