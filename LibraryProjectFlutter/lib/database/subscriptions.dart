import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/models/book_requests.dart';
import 'package:library_project/models/profile_info.dart';
import 'package:library_project/models/user.dart';
import 'dart:async';

// instead of fetching userLibrary once, we use a reference to update it in-memory everytime its updated.
// The same is done with the lent to me books. It feteches them initially and updates the in-memory list as needed
// and refreshes the pages as needed in the parameter functions. It works like this since dart passes lists and other objects by reference.
StreamSubscription<DatabaseEvent> setupUserLibrarySubscription(
    List<Book> userLibrary, User user, Function ownedBooksUpdated) {
  DatabaseReference ownedBooksReference =
      FirebaseDatabase.instance.ref('books/${user.uid}/');
  StreamSubscription<DatabaseEvent> ownedSubscription =
      ownedBooksReference.onValue.listen((DatabaseEvent event) {
    userLibrary.clear();
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        Book book = createBookFromJson(child.value);
        book.setId(dbReference.child('books/${user.uid}/${child.key}'));
        userLibrary.add(book);
      }
    }
    ownedBooksUpdated();
  });
  return ownedSubscription; // returning this only to be able to properly dispose of it
}

StreamSubscription<DatabaseEvent> setupLentToMeSubscription(
    List<LentBookInfo> booksLentToMe,
    User user,
    Function lentToMeBooksUpdated) {
  DatabaseReference lentToMeBooksReference =
      FirebaseDatabase.instance.ref('booksLent/${user.uid}/');
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
        if (booksLentToMe[j].lenderId == lenderId &&
            booksLentToMe[j].bookDbKey == bookDbKey) {
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
          DatabaseEvent getBookEvent =
              await dbReference.child('books/$lenderId/$bookDbKey').once();
          if (getBookEvent.snapshot.value != null) {
            Book book = createBookFromJson(getBookEvent.snapshot.value);
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
    Map<String, List<Book>> friendIdToBooks,
    String friendId,
    Function friendsBooksUpdated) {
  DatabaseReference friendsBooksReference =
      FirebaseDatabase.instance.ref('books/$friendId/');
  StreamSubscription<DatabaseEvent> friendsBooksSubscription =
      friendsBooksReference.onValue.listen((DatabaseEvent event) {
    List<Book> listOfFriendsBooks = [];
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        Book book = createBookFromJson(child.value);
        book.setId(dbReference.child('books/$friendId/${child.key}'));
        listOfFriendsBooks.add(book);
      }
    }
    friendIdToBooks[friendId] = List.from(listOfFriendsBooks);
    friendsBooksUpdated();
  });
  return friendsBooksSubscription;
}

StreamSubscription<DatabaseEvent> setupUserSubscription(
    Map<String, UserModel> userIdToUserModel,
    String userId,
    Function userUpdated) {
  DatabaseReference userReference =
      FirebaseDatabase.instance.ref('users/$userId/');
  StreamSubscription<DatabaseEvent> userSubscription =
      userReference.onValue.listen((DatabaseEvent event) {
    if (event.snapshot.value != null) {
      UserModel user =
          UserModel.fromJson(event.snapshot.value as Map, event.snapshot.key!);
      userIdToUserModel[userId] = user;
      if (userId == FirebaseAuth.instance.currentUser!.uid) {
        userModel.value = user;
      }
    }
    userUpdated();
  });
  return userSubscription;
}

StreamSubscription<DatabaseEvent> setupProfileSubscription(
    Map<String, ProfileInfo> userIdToProfile,
    String userId,
    Function profileUpdated) {
  DatabaseReference profileReference =
      FirebaseDatabase.instance.ref('profileInfo/$userId/');
  StreamSubscription<DatabaseEvent> profileSubscription =
      profileReference.onValue.listen((DatabaseEvent event) {
    if (event.snapshot.value != null) {
      ProfileInfo profile = ProfileInfo.fromJson(event.snapshot.value as Map);
      userIdToProfile[userId] = profile;
    } else {
      ProfileInfo profile = ProfileInfo();
      userIdToProfile[userId] = profile;
    }
    profileUpdated();
  });
  return profileSubscription;
}

StreamSubscription<DatabaseEvent> setupSentBookRequestsSubscription(
    List<SentBookRequest> sentBookRequests,
    User user,
    Function sentBookRequestsUpdated) {
  DatabaseReference sentBookRequestsReference =
      FirebaseDatabase.instance.ref('sentBookRequests/${user.uid}/');
  StreamSubscription<DatabaseEvent> sentBookRequestsSubscription =
      sentBookRequestsReference.onValue.listen((DatabaseEvent event) async {
    sentBookRequests.clear();
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        dynamic record = child.value;
        String receiverId = record['receiverId'];
        String bookDbKey = child.key!;
        DatabaseEvent getBookEvent =
            await dbReference.child('books/$receiverId/$bookDbKey').once();
        if (getBookEvent.snapshot.value != null) {
          Book book = createBookFromJson(getBookEvent.snapshot.value);
          book.setId(dbReference.child('books/$receiverId/${child.key}'));
          SentBookRequest sentBookRequest =
              createSentBookRequest(child.value, book);
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
StreamSubscription<DatabaseEvent> setupReceivedBookRequestsSubscription(
    List<ReceivedBookRequest> receivedBookRequests,
    User user,
    Function receivedBookRequestsUpdated) {
  DatabaseReference receivedBookRequestsReference =
      FirebaseDatabase.instance.ref('receivedBookRequests/${user.uid}/');
  StreamSubscription<DatabaseEvent> receivedBookRequestsSubscription =
      receivedBookRequestsReference.onValue.listen((DatabaseEvent event) async {
    receivedBookRequests.clear();
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        String bookDbKey = child.key!;
        DatabaseEvent getBookEvent =
            await dbReference.child('books/${user.uid}/$bookDbKey').once();
        if (getBookEvent.snapshot.value != null) {
          Book book = createBookFromJson(getBookEvent.snapshot.value);
          book.setId(dbReference.child('books/${user.uid}/${child.key}'));
          dynamic record = child.value;
          Map<String, String> senders = (record['senders'] as Map).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
          senders.forEach((k, v) {
            DateTime sendDate = DateTime.parse(v);
            ReceivedBookRequest receivedBookRequest =
                createReceivedBookRequest(k, sendDate, book);
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
    List<String> friends, User user, Function friendsUpdated) {
  DatabaseReference friendsReference =
      FirebaseDatabase.instance.ref('friends/${user.uid}/');
  StreamSubscription<DatabaseEvent> friendsSubscription =
      friendsReference.onValue.listen((DatabaseEvent event) async {
    friends.clear();
    if (event.snapshot.value != null) {
      for (var child in event.snapshot.children) {
        // Friend friend = Friend('${child.key}');
        // friend.setId(dbReference.child('friends/${user.uid}/${child.key}'));

        // DatabaseEvent userEvent = await dbReference.child('users/${child.key}').once();
        // if (userEvent.snapshot.value != null) {
        //   Map data = userEvent.snapshot.value as Map;
        // if (data.containsKey('name')) {
        //   friend.name = data['name'];
        // }
        // if (data.containsKey('email')) {
        //   friend.email = data['email'];
        // }
        // if (data.containsKey('photoUrl')) {
        //   friend.photo = data['photoUrl'];
        // }
        // friends.add(UserModel.fromJson(data, userEvent.snapshot.key!));

        String id = '${child.key}';
        if (userIdToSubscription[id] == null) {
          userIdToSubscription[id] =
              setupUserSubscription(userIdToUserModel, id, userUpdated);
        }
        friends.add(id);
        // }
      }
    }
    friendsUpdated();
  });
  return friendsSubscription;
}

StreamSubscription<DatabaseEvent> setupFriendsOfFriendsSubscription(Map<String, List<String>> idsToFriendList, String id, Function friendOfFriendUpdated) {
  DatabaseReference friendsReference =
      FirebaseDatabase.instance.ref('friends/$id/');
  StreamSubscription<DatabaseEvent> friendSubscription =
      friendsReference.onValue.listen((DatabaseEvent event) {
    List<String> friends = [];
    if (event.snapshot.value != null) {
      for (var child in event.snapshot.children) {
        String id = '${child.key}';
        if (userIdToSubscription[id] == null) {
          userIdToSubscription[id] =
              setupUserSubscription(userIdToUserModel, id, userUpdated);
        }
        friends.add(id);
      }
    }
    idsToFriendList[id] = friends;
    friendOfFriendUpdated();
  });
  return friendSubscription;
}

StreamSubscription<DatabaseEvent> setupRequestsSubscription(
    ValueNotifier<List<String>> requests, User user, Function requestsUpdated) {
  DatabaseReference requestsReference =
      FirebaseDatabase.instance.ref('requests/${user.uid}/');
  StreamSubscription<DatabaseEvent> requestsSubscription =
      requestsReference.onValue.listen((DatabaseEvent event) async {
    requests.value.clear();
    if (event.snapshot.value != null) {
      for (var child in event.snapshot.children) {
        // Request request = createRequest(child.value, user.uid);
        // request.setId(dbReference.child('requests/${user.uid}/${child.key}'));

        // DatabaseEvent userEvent = await dbReference.child('users/${request.senderId}').once();
        // if (userEvent.snapshot.value != null) {
        //   Map data = userEvent.snapshot.value as Map;
        //   if (data.containsKey('name')) {
        //     request.name = data['name'];
        //   }
        //   if (data.containsKey('email')) {
        //     request.email = data['email'];
        //   }
        //   if (data.containsKey('photoUrl')) {
        //     request.photo = data['photoUrl'];
        //   }
        // }

        // var map = child.value as Map<dynamic, dynamic>;
        String id = '${child.key}';
        if (userIdToSubscription[id] == null) {
          userIdToSubscription[id] =
              setupUserSubscription(userIdToUserModel, id, userUpdated);
        }
        requests.value.add(id);
      }
    }
    requestsUpdated();
    requests.notifyListeners();
  });
  return requestsSubscription;
}

StreamSubscription<DatabaseEvent> setupSentFriendRequestSubscription(
    List<String> usersSentTo, String uid, Function sentFriendRequestUpdated) {
  DatabaseReference requestReference =
      FirebaseDatabase.instance.ref('sentFriendRequests/$uid');
  StreamSubscription<DatabaseEvent> requestSubscription =
      requestReference.onValue.listen((DatabaseEvent event) async {
    usersSentTo.clear();
    if (event.snapshot.value != null) {
      for (var child in event.snapshot.children) {
        if (userIdToSubscription[child.key] == null) {
          userIdToSubscription['${child.key}'] = setupUserSubscription(userIdToUserModel, '${child.key}', userUpdated);
        }
        usersSentTo.add('${child.key}');
      }
    }
  });
  return requestSubscription;
}
