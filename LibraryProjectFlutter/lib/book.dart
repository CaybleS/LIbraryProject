import 'package:firebase_database/firebase_database.dart';
import 'package:library_project/database.dart';

List<Book> exampleLibrary = [
  Book("Lord of the Rings", "J.R.R. Tolkien", true, "https://lgimages.s3.amazonaws.com/nc-md.gif"),
  Book("Alice's Adventures in Wonderland", "Lewis Carroll", true, "https://lgimages.s3.amazonaws.com/nc-md.gif"),
  Book("The Lion, the Witch and the Wardrobe", "C.S. Lewis", true, "https://lgimages.s3.amazonaws.com/nc-md.gif"),
];

class Book {
  String title;
  String author;
  bool available;
  bool favorite = false;
  String coverUrl; // note that this isnt a named optional parameter anymore, could always change it back tho, I don't see the need but I could be wrong
  late DatabaseReference _id;
  // add dateCheckedOut at some point too, which should probably be an optional parameter, no idea what datatype it would be

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