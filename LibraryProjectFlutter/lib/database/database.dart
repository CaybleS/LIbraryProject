import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/models/book_requests.dart';
import 'package:library_project/models/user.dart';
import '../Social/friends/friends_page.dart';
import 'dart:async';

final dbReference = FirebaseDatabase.instance.ref();

void addBook(Book book, User user) {
  var id = dbReference.child('books/${user.uid}/').push();
  id.set(book.toJson());
}

void updateBook(Book book, DatabaseReference id) {
  id.update(book.toJson());
}

// for many of these, the onvalue subscriptions are what use the id, so we dont need to return id,
// but in this case the id is needed for the book to know about this
DatabaseReference addLentBookInfo(DatabaseReference bookDbRef, LentBookInfo lentBook, String borrowerId) {
  DatabaseReference id = dbReference.child('booksLent/$borrowerId/').push();
  id.set(lentBook.toJson(bookDbRef.key!));
  return id;
}

void removeLentBookInfo(String lentDbKey, String borrowerId) {
  dbReference.child('booksLent/$borrowerId/$lentDbKey').remove();
}

void addSentBookRequest(SentBookRequest sentBookRequest, String senderId, String bookDbKey) {
  DatabaseReference id = dbReference.child('sentBookRequests/$senderId/$bookDbKey/');
  id.set(sentBookRequest.toJson());
}

Future<void> addReceivedBookRequest(String senderId, DateTime sendDate, String receiverId, String bookDbKey) async {
  DatabaseEvent event = await dbReference.child('receivedBookRequests/$receiverId/$bookDbKey/senders/').once();
  Map<String, String> senders = {};
  if (event.snapshot.value != null) {
    // need to create the map like this, safely, rather than just raw type casting
    Map<String, String> senders = (event.snapshot.value as Map).map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
    senders[senderId] = sendDate.toIso8601String();
    DatabaseReference id = dbReference.child('receivedBookRequests/$receiverId/$bookDbKey/');
    id.set({'senders': senders});
  }
  else {
    DatabaseReference id = dbReference.child('receivedBookRequests/$receiverId/$bookDbKey/');
    senders[senderId] = sendDate.toIso8601String();
    id.set({'senders': senders});
  }
}

Future<void> removeBookRequestData(String requesterId, String userId, String bookDbKey, {bool removeAllReceivedRequests = false}) async {
  dbReference.child('sentBookRequests/$requesterId/$bookDbKey').remove();
  if (removeAllReceivedRequests) {
    dbReference.child('receivedBookRequests/$userId/$bookDbKey').remove();
  }
  else {
    // need to see current senders and update as needed
    DatabaseEvent event = await dbReference.child('receivedBookRequests/$userId/$bookDbKey/senders/').once();
    if (event.snapshot.value != null) {
      Map<String, String> senders = (event.snapshot.value as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      senders.remove(requesterId);
      DatabaseReference id = dbReference.child('receivedBookRequests/$userId/$bookDbKey/');
      id.set({'senders': senders});
    }
    else {
      // there are no senders so we just remove everything
      dbReference.child('receivedBookRequests/$userId/$bookDbKey').remove();
    }
  }
}

// instead of fetching userLibrary once, we use a reference to update it in-memory everytime its updated.
// The same is done with the lent to me books. It feteches them initially and updates the in-memory list as needed
// and refreshes the pages as needed in the parameter functions. It works like this since dart passes lists and other objects by reference.
StreamSubscription<DatabaseEvent> setupUserLibrarySubscription(
    List<Book> userLibrary, User user, Function ownedBooksUpdated) {
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

StreamSubscription<DatabaseEvent> setupUserSubscription(ValueNotifier<UserModel?> user, String userId) {
  DatabaseReference ownedBooksReference = FirebaseDatabase.instance.ref('users/$userId/');
  StreamSubscription<DatabaseEvent> ownedSubscription = ownedBooksReference.onValue.listen((DatabaseEvent event) {
    if (event.snapshot.value != null) {
      user.value = UserModel.fromJson(event.snapshot.value as Map<dynamic, dynamic>);
    }
  });
  return ownedSubscription;
}

StreamSubscription<DatabaseEvent> setupLentToMeSubscription(
    List<LentBookInfo> booksLentToMe, User user, Function lentToMeBooksUpdated) {
  DatabaseReference lentToMeBooksReference = FirebaseDatabase.instance.ref('booksLent/${user.uid}/');
  // so only the books lent data changes are tracked, so even if lent books themselves are updated, this doesnt get fired
  StreamSubscription<DatabaseEvent> lentToMeSubscription =
      lentToMeBooksReference.onValue.listen((DatabaseEvent event) async {
    List<dynamic> listOfRecords = [];
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        dynamic record = child.value;
        listOfRecords.add(record);
      }
    }
    List<LentBookInfo> tempBooksLentToMe = [];
    bool bookFound = false;
    for (int i = 0; i < listOfRecords.length; i++) {
      dynamic record = listOfRecords[i];
      String lenderId = record['lenderId'];
      String bookDbKey = record['bookDbKey'];
      bookFound = false;
      // so if the book lent to the user is already in memory we don't read it from the database again. This technically causes "un-lending"
      // to not use any database reads, as it should.
      for (int j = 0; j < booksLentToMe.length; j++) {
        if (booksLentToMe[j].lenderId == lenderId && booksLentToMe[j].bookDbKey == bookDbKey) {
          tempBooksLentToMe.add(booksLentToMe[j]);
          bookFound = true;
          break;
        }
      }
      if (!bookFound) {
        // currently I've noticed this fails to work sometimes, nondeterministically. I'd love to know why. I believe its due to database
        // stress or something since I've had phases where it works perfectly and others where multiple ppl are using the app and it fails.
        // This occured even with the previous un-optimized version of this function, although that one could gracefully handle this failing
        // better since it just tries to read all books from the database everytime. This is my untested solution (currently nobody is
        // using the database so its working everytime) but this should in theory mitigate the problem. Still needs testing tho.
        for (int i = 0; i < 5; i++) {
          DatabaseEvent getBookEvent = await dbReference.child('books/$lenderId/$bookDbKey').once();
          if (getBookEvent.snapshot.value != null) {
            Book book = createBook(getBookEvent.snapshot.value);
            LentBookInfo lentBookInfo = createLentBookInfo(book, record);
            tempBooksLentToMe.add(lentBookInfo);
            break;
          }
        }
      }
    }
    booksLentToMe.clear();
    booksLentToMe.addAll(tempBooksLentToMe);
    lentToMeBooksUpdated();
  });
  return lentToMeSubscription;
}

StreamSubscription<DatabaseEvent> setupFriendsBooksSubscription(
    Map<String, List<Book>> friendIdToBooks, String friendId, Function friendsBooksUpdated) {
  DatabaseReference friendsBooksReference = FirebaseDatabase.instance.ref('books/$friendId/');
  StreamSubscription<DatabaseEvent> friendsBooksSubscription =
      friendsBooksReference.onValue.listen((DatabaseEvent event) {
    List<Book> listOfFriendsBooks = [];
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        Book book = createBook(child.value);
        book.setId(dbReference.child('books/$friendId/${child.key}'));
        listOfFriendsBooks.add(book);
      }
    }
    friendIdToBooks[friendId] = List.from(listOfFriendsBooks);
    friendsBooksUpdated();
  });
  return friendsBooksSubscription;
}

StreamSubscription<DatabaseEvent> setupSentBookRequestsSubscription(List<SentBookRequest> sentBookRequests, User user, Function sentBookRequestsUpdated) {
  DatabaseReference sentBookRequestsReference = FirebaseDatabase.instance.ref('sentBookRequests/${user.uid}/');
  StreamSubscription<DatabaseEvent> sentBookRequestsSubscription = sentBookRequestsReference.onValue.listen((DatabaseEvent event) async {
    sentBookRequests.clear();
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        dynamic record = child.value;
        String receiverId = record['receiverId'];
        String bookDbKey = child.key!;
        DatabaseEvent getBookEvent = await dbReference.child('books/$receiverId/$bookDbKey').once();
        if (getBookEvent.snapshot.value != null) {
          Book book = createBook(getBookEvent.snapshot.value);
          book.setId(dbReference.child('books/$receiverId/${child.key}'));
          SentBookRequest sentBookRequest = createSentBookRequest(child.value, book);
          sentBookRequests.add(sentBookRequest);
        }
      }
    }
    sentBookRequestsUpdated();
  });
  return sentBookRequestsSubscription;
}

// it needs to listen for both new books being requested, and current requests being updated (as in another user requesting this book)
// this is why the map stuff is happening
StreamSubscription<DatabaseEvent> setupReceivedBookRequestsSubscription(List<ReceivedBookRequest> receivedBookRequests, User user, Function receivedBookRequestsUpdated) {
  DatabaseReference receivedBookRequestsReference = FirebaseDatabase.instance.ref('receivedBookRequests/${user.uid}/');
  StreamSubscription<DatabaseEvent> receivedBookRequestsSubscription = receivedBookRequestsReference.onValue.listen((DatabaseEvent event) async {
    receivedBookRequests.clear();
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        String bookDbKey = child.key!;
        DatabaseEvent getBookEvent = await dbReference.child('books/${user.uid}/$bookDbKey').once();
        if (getBookEvent.snapshot.value != null) {
          Book book = createBook(getBookEvent.snapshot.value);
          book.setId(dbReference.child('books/${user.uid}/${child.key}'));
          dynamic record = child.value;
          Map<String, String> senders = (record['senders'] as Map).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
          senders.forEach((k, v) {
            DateTime sendDate = DateTime.parse(v);
            ReceivedBookRequest receivedBookRequest = createReceivedBookRequest(k, sendDate, book);
            receivedBookRequests.add(receivedBookRequest);
          });
        }
      }
    }
    receivedBookRequestsUpdated();
  });
  return receivedBookRequestsSubscription;
}

StreamSubscription<DatabaseEvent> setupFriendsSubscription(
    List<UserModel> friends, User user, Function friendsUpdated) {
  DatabaseReference friendsReference = FirebaseDatabase.instance.ref('friends/${user.uid}/');
  StreamSubscription<DatabaseEvent> friendsSubscription = friendsReference.onValue.listen((DatabaseEvent event) async {
    friends.clear();
    if (event.snapshot.value != null) {
      for (var child in event.snapshot.children) {
        // Friend friend = Friend('${child.key}');
        // friend.setId(dbReference.child('friends/${user.uid}/${child.key}'));

        DatabaseEvent userEvent = await dbReference.child('users/${child.key}').once();
        if (userEvent.snapshot.value != null) {
          Map data = userEvent.snapshot.value as Map;
          // if (data.containsKey('name')) {
          //   friend.name = data['name'];
          // }
          // if (data.containsKey('email')) {
          //   friend.email = data['email'];
          // }
          // if (data.containsKey('photoUrl')) {
          //   friend.photo = data['photoUrl'];
          // }
          friends.add(UserModel.fromJson(data));
        }
      }
    }
    friendsUpdated();
  });
  return friendsSubscription;
}

StreamSubscription<DatabaseEvent> setupRequestsSubscription(
    List<Request> requests, User user, Function requestsUpdated) {
  DatabaseReference requestsReference = FirebaseDatabase.instance.ref('requests/${user.uid}/');
  StreamSubscription<DatabaseEvent> requestsSubscription =
      requestsReference.onValue.listen((DatabaseEvent event) async {
    requests.clear();
    if (event.snapshot.value != null) {
      for (var child in event.snapshot.children) {
        Request request = createRequest(child.value, user.uid);
        request.setId(dbReference.child('requests/${user.uid}/${child.key}'));

        DatabaseEvent userEvent = await dbReference.child('users/${request.senderId}').once();
        if (userEvent.snapshot.value != null) {
          Map data = userEvent.snapshot.value as Map;
          if (data.containsKey('name')) {
            request.name = data['name'];
          }
          if (data.containsKey('email')) {
            request.email = data['email'];
          }
          if (data.containsKey('photoUrl')) {
            request.photo = data['photoUrl'];
          }
        }

        requests.add(request);
      }
    }
    requestsUpdated();
  });
  return requestsSubscription;
}

Future<bool> userExists(String id) async {
  if (id.contains(RegExp('[.#\$\\[\\]]'))) {
    return false;
  }
  DatabaseEvent event = await dbReference.child('users/$id').once();
  return (event.snapshot.value != null);
}

Future<String> findUser(String txt) async {
  bool isEmail = txt.contains('@');
  if (!isEmail && await userExists(txt)) {
    return txt;
  }

  DatabaseEvent event = await dbReference.child('users/').once();
  if (event.snapshot.value != null) {
    for (Map child in (event.snapshot.value as Map).values) {
      if (child['email'] == txt) {
        return child['uid'];
      }
    }
  }
  return '';
}

void addUser(User user) {
  final id = dbReference.child('users/${user.uid}');
  UserModel userModel = UserModel(
    uid: user.uid,
    name: user.displayName!,
    email: user.email!,
    photoUrl: user.photoURL,
    isActive: true,
    isTyping: false,
    lastSignedIn: DateTime.now(),
  );
  id.set(userModel.toJson());
}

void sendFriendRequest(User user, String friendId) {
  var id = dbReference.child('requests/$friendId/').push();
  id.set({'sender': user.uid, 'sendDate': DateTime.now().toIso8601String()});
}

// TODO: I'm not going to get rid of this since idk if it's used somewhere, but with the subscription thing, we shouldn't need it
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
  String time = DateTime.now().toIso8601String();
  id.set({"friendsSince": time});
  id = dbReference.child('friends/${request.uid}/${request.senderId}');
  id.set({"friendsSince": time});

  await request.delete();
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
