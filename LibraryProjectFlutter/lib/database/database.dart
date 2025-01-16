import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/Social/chat.dart';
import '../Social/friends_page.dart';
import 'dart:async';

final dbReference = FirebaseDatabase.instance.ref();

DatabaseReference addBook(Book book, User user) {
  var id = dbReference.child('books/${user.uid}/').push();
  id.set(book.toJson());
  return id;
}

void updateBook(Book book, DatabaseReference id) {
  id.update(book.toJson());
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

// instead of fetching userLibrary once, we use a reference to update it in-memory everytime its updated.
// The same is done with the lent to me books. It feteches them initially and updates the in-memory list as needed
// and refreshes the pages as needed in the parameter functions. It works like this since dart passes lists and other objects by reference.
StreamSubscription<DatabaseEvent> setupUserLibrarySubscription(List<Book> userLibrary, User user, Function ownedBooksUpdated) {
  DatabaseReference ownedBooksReference = FirebaseDatabase.instance.ref('books/${user.uid}/');
  StreamSubscription<DatabaseEvent> ownedSubscription = ownedBooksReference.onValue.listen((DatabaseEvent event) {
    userLibrary.clear();
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        Book book = createBook(child.value);
        book.setId(dbReference.child('books/${user.uid}/${child.key}'));
        userLibrary.add(book);
      }
    }
    ownedBooksUpdated();
  });
  return ownedSubscription; // returning this only to be able to properly dispose of it
}

StreamSubscription<DatabaseEvent> setupLentToMeSubscription(List<LentBookInfo> booksLentToMe, User user, Function lentToMeBooksUpdated) {
  DatabaseReference lentToMeBooksReference = FirebaseDatabase.instance.ref('booksLent/${user.uid}/');
  // so only the books lent data changes are tracked, so even if lent books themselves are updated, this doesnt get fired
  StreamSubscription<DatabaseEvent> lentToMeSubscription = lentToMeBooksReference.onValue.listen((DatabaseEvent event) async {
    List<dynamic> listOfRecords = [];
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        dynamic record = child.value;
        listOfRecords.add(record);
      }
    }
    booksLentToMe.clear();
    for (dynamic record in listOfRecords) {
      String lenderId = record['lenderId'];
      String bookDbKey = record['bookDbKey'];
      DatabaseEvent getBookEvent = await dbReference.child('books/$lenderId/$bookDbKey').once();
      if (getBookEvent.snapshot.value != null) {
        Book book = createBook(getBookEvent.snapshot.value);
        LentBookInfo lentBookInfo = createLentBookInfo(book, record);
        booksLentToMe.add(lentBookInfo);
      }
    }
    lentToMeBooksUpdated();
  });
  return lentToMeSubscription;
}

StreamSubscription<DatabaseEvent> setupFriendsSubscription(List<Friend> friends, User user, Function friendsUpdated) {
  DatabaseReference ownedBooksReference = FirebaseDatabase.instance.ref('friends/${user.uid}/');
  StreamSubscription<DatabaseEvent> friendsSubscription = ownedBooksReference.onValue.listen((DatabaseEvent event) {
    friends.clear();
    if (event.snapshot.value != null) {
      for (var child in event.snapshot.children) {
        Friend friend = Friend('${child.key}');
        friend.setId(dbReference.child('friends/${user.uid}/${child.key}'));
        friends.add(friend);
      }
    }
    friendsUpdated();
  });
  return friendsSubscription;
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

Future<List<ChatShort>> getChatList(User user) async {
  DatabaseEvent event = await dbReference
      .child('chatsByUser/${user.uid}/')
      .once();
  List<ChatShort> chats = [];

  if (event.snapshot.value != null) {
    for (var child in event.snapshot.children) {
      ChatShort chat = await createChatDisplay(child.value);
      chat.roomID = child.key!;
      chats.add(chat);
    }
  }

  return chats;
}

Future<Map<String, dynamic>> getChatInfo(String roomID) async {
  DatabaseEvent event = await dbReference.child('chatInfo/$roomID').once();
  Map<String, dynamic> map = {};

  if (event.snapshot.value != null) {
    Map<String, dynamic> tempMap = Map<String, dynamic>.from(event.snapshot.value as Map);

    map['type'] = tempMap['type'];

    Map<String, String> memberMap = {};
    Map<String, String> memberIDs = Map<String, String>.from(tempMap['members'] as Map);

    for (var child in memberIDs.values) {
      memberMap[child] = await getUserDisplayName(child);
    }

    if (map['type'] == "group") {
      map['name'] = tempMap['name'];
    }

    map['members'] = memberMap;
  }

  return map;
}

Future<String> getUserDisplayName(String id) async {
  String name = "";
  DatabaseEvent userInfo = await dbReference.child('users/$id').once();
  if (userInfo.snapshot.value != null) {
    Map data = userInfo.snapshot.value as Map;
    if (data.containsKey('name')) {
      name = data['name'];
    } else {
      name = id;
    }
  }

  return name;
}