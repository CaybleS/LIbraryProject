import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'book.dart';

final dbReference = FirebaseDatabase.instance.ref();

DatabaseReference addBook(Book book, User user) {
  var id = dbReference.child('books/${user.uid}/').push();
  id.set(book.toJson());
  return id;
}

void updateBook(Book book, DatabaseReference id) {
  id.update(book.toJson());
}

Future<List<Book>> getUserLibrary(User user) async {
  DatabaseEvent event = await dbReference.child('books/${user.uid}/').once();
  List<Book> books = [];

  if (event.snapshot.value != null) {
    for (var child in event.snapshot.children) {
      Book book = createBook(child.value);
      book.setId(dbReference.child('books/${user.uid}/${child.key}'));
      books.add(book);
    }
  }

  return books;
}