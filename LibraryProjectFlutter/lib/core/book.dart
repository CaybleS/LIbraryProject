import 'package:firebase_database/firebase_database.dart';
import 'database.dart';

class Book {
  String title;
  String author;
  bool available;
  bool favorite = false;
  String coverUrl;
  late DatabaseReference _id;
  // maybe dateCheckedOut at some point too, which should probably be an optional parameter, no idea what datatype it would be

  Book(this.title, this.author, this.available, this.coverUrl);

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
      'coverUrl': coverUrl,
    };
  }
}

Book createBook(record) {
  Book book = Book(record['title'], record['author'], record['available'], record['coverUrl']);
  book.favorite = record['favorite'];

  return book;
}