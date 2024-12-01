import 'package:firebase_database/firebase_database.dart';
import 'database.dart';

// more can be added here based on what users want
class Book {
  String title;
  String author;
  bool isLent = false;
  bool favorite = false;
  String coverUrl;
  String description;
  String categories;
  DateTime? dateLent;
  DateTime? dateToReturn;
  String? borrowerId;
  bool isManualAdded; // needed because manually added books should be changable by users
  late DatabaseReference _id;

  Book(this.title, this.author, this.coverUrl, this.description, this.categories, {this.isManualAdded = false});

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

  void remove() {
    removeRef(_id);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'isLent': isLent,
      'favorite': favorite,
      'coverUrl': coverUrl,
      'description': description,
      'categories': categories,
      'dateLent': dateLent?.toIso8601String(),
      'dateToReturn': dateToReturn?.toIso8601String(),
      'borrowerId': borrowerId,
      'isManualAdded': isManualAdded,
    };
  }
}

Book createBook(record) {
  Book book = Book(
    record['title'], record['author'], record['coverUrl'], record['description'], record['categories'], isManualAdded: record['isManualAdded'],
  );
  book.isLent = record['isLent'];
  book.favorite = record['favorite'];
  book.dateLent = record['dateLent'] != null ? DateTime.parse(record['dateLent']) : null;
  book.dateToReturn = record['dateToReturn'] != null ? DateTime.parse(record['dateToReturn']) : null;
  book.borrowerId = record['borrowerId'];

  return book;
}
