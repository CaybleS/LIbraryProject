import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/misc_util/misc_helper_functions.dart';
import 'package:library_project/core/friends_page.dart';

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

DatabaseReference addLentBookInfo(DatabaseReference bookDbRef, LentBookInfo lentBook, String borrowerId) {
  DatabaseReference id = dbReference.child('booksLent/$borrowerId/').push();
  id.set(lentBook.toJson(bookDbRef.key!));
  return id;
}

Future<void> removeLentBookInfo(String lentDbKey, String borrowerId) async {
  DatabaseEvent event = await dbReference.child('booksLent/$borrowerId/$lentDbKey').once();
  if (event.snapshot.value != null) {
    removeRef(event.snapshot.ref);
  }
}

// what is this function doing? It returns the checksum, which needs to be updated, to the homepage, and
// takes in the LentBookInfo list, by reference, to modify it as needed or do nothing to it.
Future<String> getLentToMeUserLibrary(List<LentBookInfo> lentBookInfoList, User user, String currentChecksum) async {
  DatabaseEvent event = await dbReference.child('booksLent/${user.uid}').once();
  List<dynamic> listOfRecords = [];

  if (event.snapshot.value != null) {
    for (DataSnapshot child in event.snapshot.children) {
      dynamic record = child.value;
      listOfRecords.add(record);
    }
  }
  String checksum = await calcLentBooksChecksum(listOfRecords);
  if (checksum != currentChecksum) {
    lentBookInfoList.clear();
    for (dynamic record in listOfRecords) {
      String lenderId = record['lenderId'];
      String bookDbKey = record['bookDbKey'];
      DatabaseEvent getBookEvent = await dbReference.child('books/$lenderId/$bookDbKey').once();
      if (getBookEvent.snapshot.value != null) {
        Book book = createBook(getBookEvent.snapshot.value);
        LentBookInfo lentBookInfo = createLentBookInfo(book, record);
        lentBookInfoList.add(lentBookInfo);
      }
    }
  }
  return checksum;
}

Future<bool> userExists(String id) async {
  DatabaseEvent event = await dbReference.child('users/$id').once();
  return (event.snapshot.value != null);
}

void addUser(User user) {
  var id = dbReference.child('users/${user.uid}');
  id.set({"test": true});
}

void sendFriendRequest(User user, String friendId) {
  var id = dbReference.child('requests/$friendId/').push();
  id.set({
    'sender': user.uid,
  });
}

Future<List<Request>> getFriendRequests(User user) async {
  DatabaseEvent event = await dbReference.child('requests/${user.uid}/').once();
  List<Request> requests = [];

  if (event.snapshot.value != null) {
    for (var child in event.snapshot.children) {
      Request request = createRequest(child.value, user.uid);
      request.setId(dbReference.child('requests/${user.uid}/${child.key}'));
      requests.add(request);
    }
  }

  return requests;
}

Future<void> removeRef(DatabaseReference id) async {
  await id.remove();
}

Future<void> addFriend(Request request) async {
  var id = dbReference.child('friends/${request.senderId}/${request.uid}');
  id.set({"test": true});
  id = dbReference.child('friends/${request.uid}/${request.senderId}');
  id.set({"test": true});

  await request.delete();
}

Future<List<Friend>> getFriends(User user) async {
  DatabaseEvent event = await dbReference.child('friends/${user.uid}/').once();
  List<Friend> friends = [];

  if (event.snapshot.value != null) {
    for (var child in event.snapshot.children) {
      Friend friend = Friend('${child.key}');
      friend.setId(dbReference.child('friends/${user.uid}/${child.key}'));
      friends.add(friend);
    }
  }

  return friends;
}