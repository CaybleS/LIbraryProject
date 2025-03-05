import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/models/book_requests_model.dart';
import 'package:library_project/models/profile_info.dart';
import 'package:library_project/models/user.dart';
import 'dart:async';

// instead of fetching userLibrary once, we use a reference to update it in-memory everytime its updated.
// The same is done with the lent to me books. It feteches them initially and updates the in-memory list as needed
// and refreshes the pages as needed in the parameter functions. It works like this since dart passes lists and other objects by reference.
StreamSubscription<DatabaseEvent> setupUserLibrarySubscription(
    List<Book> userLibrary, User user, Function ownedBooksUpdated) {
  DatabaseReference ownedBooksReference = FirebaseDatabase.instance.ref('books/${user.uid}/');
  bool incrementedRequestsAndBooksLoaded = false;
  StreamSubscription<DatabaseEvent> ownedSubscription = ownedBooksReference.onValue.listen((DatabaseEvent event) {
    int numBooksReadyToReturn = 0;
    List<Book> tempUserLibrary = [];
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        Book book = createBookFromJson(child.value);
        book.setId(dbReference.child('books/${user.uid}/${child.key}'));
        if (book.readyToReturn == true) {
          numBooksReadyToReturn++;
        }
        tempUserLibrary.add(book);
      }
      numBooksReadyToReturnNotifier.value = numBooksReadyToReturn;
    }
    if (!userLibraryLoaded.isCompleted) {
      userLibraryLoaded.complete();
    }
    // did it this way rather than userLibrary.clear() before the event.snapshot.value null check and then updating it directly in the
    // loop because this is safer, updating userLibrary directly like was done previously should cause a race condition if books
    // are added or removed at the same time since we'd clear userLibrary and add more while some are still being added in the
    // previous event.snapshot.children iterations. This way is just better anyway.
    userLibrary.clear();
    userLibrary.addAll(tempUserLibrary);
    ownedBooksUpdated();
    if (!incrementedRequestsAndBooksLoaded) {
      requestsAndBooksLoaded.value++;
      incrementedRequestsAndBooksLoaded = true;
    }
  });
  return ownedSubscription; // returning this only to be able to properly dispose of it
}

StreamSubscription<DatabaseEvent> setupLentToMeSubscription(
  Map<String, LentBookInfo> booksLentToMe, User user, Function lentToMeBooksUpdated) {
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
    // using temp books lent to me since this logic is what detects if books are no longer lent to the user
    // and thus it removes things from the maps which store the data as needed
    Map<String, LentBookInfo> tempBooksLentToMe = Map<String, LentBookInfo>.from(booksLentToMe);
    tempBooksLentToMe.forEach((k, v) {
      bool bookIsStillLentToUser = false;
      for (int i = 0; i < listOfRecords.length; i++) {
        dynamic record = listOfRecords[i];
        String lenderId = record['lenderId'];
        String bookDbKey = record['bookDbKey'];
        if (v.lenderId == lenderId && v.bookDbKey == bookDbKey) {
          bookIsStillLentToUser = true;
          break;
        }
      }
      if (!bookIsStillLentToUser) {
        booksLentToMe.remove(k);
        lentBookDbKeyToSubscriptionForIt[k]!.cancel();
        lentBookDbKeyToSubscriptionForIt.remove(k);
      }
    });
    for (int i = 0; i < listOfRecords.length; i++) {
      dynamic record = listOfRecords[i];
      String lenderId = record['lenderId'];
      String bookDbKey = record['bookDbKey'];
      if (lentBookDbKeyToSubscriptionForIt[bookDbKey] == null) {
        // setup a subscription for this book if one does not already exist
        DatabaseReference bookReference = dbReference.child('books/$lenderId/$bookDbKey');
        Completer<void> completer = Completer<void>();
        lentBookDbKeyToSubscriptionForIt[bookDbKey] = bookReference.onValue.listen((DatabaseEvent event) {
          if (event.snapshot.value != null) {
            Book book = createBookFromJson(event.snapshot.value);
            book.setId(dbReference.child('books/$lenderId/${event.snapshot.key}'));
            LentBookInfo lentBookInfo = createLentBookInfo(book, record);
            booksLentToMe[bookDbKey] = lentBookInfo;
            // since the onValue takes about a second to work, and we can't await it, this achieves the same logic,
            // it kind of just acts as an await for the onValue (and also allows for logic to refresh lent to me
            // book info on every onValue event except the first). It's just waiting for the book to be fetched
            // before signaling whatever refresh logic.
            if (!completer.isCompleted) {
              completer.complete();
            }
            else {
              lentToMeBooksUpdated();
            }
          }
        });
        await completer.future;
      }
    }
    // when this is called we can guarantee that all database lent to me books have been iterated through and are added to the
    // booksLentToMe map (since there will be a delay due to the onValue to fetch the book, it needs to signal when its done)
    lentToMeBooksUpdated();
  });
  return lentToMeSubscription;
}

StreamSubscription<DatabaseEvent> setupFriendsBooksSubscription(
    Map<String, List<Book>> friendIdToBooks, String friendId, Function friendsBooksUpdated, {Completer<void>? signalFriendsBooksLoaded}) {
  DatabaseReference friendsBooksReference = FirebaseDatabase.instance.ref('books/$friendId/');
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
    // if we remove book requests for friends (like if they unfriend you), we need that friends books, so the function which removes the requests
    // needs that friend's books and this is the signaling mechanism which blocks that function until the friends books are fetched.
    if (signalFriendsBooksLoaded != null && !signalFriendsBooksLoaded.isCompleted) {
      signalFriendsBooksLoaded.complete();
    }
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

// another way to do this is to fetch the friend's library who has this book and just use its bookDbKey to map it to this book
// but that method has problems, I think this way is fine. It's complicated but it works.
StreamSubscription<DatabaseEvent> setupSentBookRequestsSubscription(
  Map<String, SentBookRequest> sentBookRequests, User user, Function sentBookRequestsUpdated) {
  DatabaseReference sentBookRequestsReference = FirebaseDatabase.instance.ref('sentBookRequests/${user.uid}/');
  StreamSubscription<DatabaseEvent> sentBookRequestsSubscription = sentBookRequestsReference.onValue.listen((DatabaseEvent event) async {
    if (event.snapshot.value == null) {
      // in this case there are no more sent book requests for this user in the database so we just cancel everything without
      // this logic, the last sent book request would not be removed since we always need to clear() if event.snapshot.value is null
      sentBookRequestBookDbKeyToSubscriptionForIt.forEach((k, v) => v.cancel());
      sentBookRequestBookDbKeyToSubscriptionForIt.clear();
      sentBookRequests.clear();
      sentBookRequestsUpdated();
      return;
    }
    // since this map stores each book we have requested, we check each database record's key to make sure that book
    // is still in the sent book requests part of the database. If not we remove it from the sent book requests and
    // cancel its subscription. So this entire logic is just to deal with unsent requests.
    Map<String, SentBookRequest> tempSentBookRequests = Map<String, SentBookRequest>.from(sentBookRequests);
    tempSentBookRequests.forEach((k, v) {
      bool requestIsStillSent = false;
      for (DataSnapshot child in event.snapshot.children) {
        dynamic record = child.value;
        String receiverId = record['receiverId'];
        String bookDbKey = child.key!;
        if (k == bookDbKey && v.receiverId == receiverId) {
          requestIsStillSent = true;
          break;
        }
      }
      if (!requestIsStillSent) {
        sentBookRequests.remove(k);
        sentBookRequestBookDbKeyToSubscriptionForIt[k]!.cancel();
        sentBookRequestBookDbKeyToSubscriptionForIt.remove(k);
      }
    });
    // now fetching all sent requests and tying the book to them
    for (DataSnapshot child in event.snapshot.children) {
      dynamic record = child.value;
      String receiverId = record['receiverId'];
      String bookDbKey = child.key!;
      if (sentBookRequestBookDbKeyToSubscriptionForIt[bookDbKey] == null) {
        // setup a subscription for this book if one does not already exist
        DatabaseReference bookReference = dbReference.child('books/$receiverId/$bookDbKey');
        Completer<void> completer = Completer<void>();
        sentBookRequestBookDbKeyToSubscriptionForIt[bookDbKey] = bookReference.onValue.listen((DatabaseEvent event) {
          if (event.snapshot.value != null) {
            Book book = createBookFromJson(event.snapshot.value);
            book.setId(dbReference.child('books/$receiverId/${event.snapshot.key}'));
            SentBookRequest sentBookRequest = createSentBookRequest(record, book);
            sentBookRequests[bookDbKey] = sentBookRequest;
            // since the onValue takes about a second to work, and we can't await it, this achieves the same logic, it kind of
            // just acts as an await for the onValue (and also allows for logic to refresh lent to me book info on every
            // onValue event except the first). It's just waiting for the book to be fetched before signaling whatever refresh logic.
            if (!completer.isCompleted) {
              completer.complete();
            }
            else {
              sentBookRequestsUpdated();
            }
          }
        });
        await completer.future;
      }
    }
    sentBookRequestsUpdated();
  });
  return sentBookRequestsSubscription;
}

StreamSubscription<DatabaseEvent> setupReceivedBookRequestsSubscription(
  List<ReceivedBookRequest> receivedBookRequests, User user, Function receivedBookRequestsUpdated) {
  DatabaseReference receivedBookRequestsReference = FirebaseDatabase.instance.ref('receivedBookRequests/${user.uid}/');
  bool incrementedRequestsAndBooksLoaded = false;
  StreamSubscription<DatabaseEvent> receivedBookRequestsSubscription =
   receivedBookRequestsReference.onValue.listen((DatabaseEvent event) async {
    // This is in the onValue to not stop the execution of the main thread (since onValue is its own thread).
    // It's purpose is to fetch received book requests only after the user library is first fetched since the
    // list of requests has the user's book in it.
    await userLibraryLoaded.future;
    // I didn't know this before/forgot but yeah you need this outside the event.snapshot.value check to clear
    // the list in the case where there is nothing at receivedBookRequests/userId but there was before, or else
    // the list wouldn't get cleared in that situation.
    List<ReceivedBookRequest> tempRequestsList = [];
    if (event.snapshot.value != null) {
      for (DataSnapshot child in event.snapshot.children) {
        dynamic record = child.value;
        String bookDbKey = child.key!;
        Map<String, String> senders = (record['senders'] as Map).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
        Book? book;
        for (int i = 0; i < userLibrary.length; i++) {
          if (userLibrary[i].id.key == bookDbKey) {
            book = userLibrary[i];
            break;
          }
        }
        if (book == null) {
          // this really should never happen btw, just being safe
          continue;
        }
        senders.forEach((senderId, dbDateSent) {
          DateTime dateSent = DateTime.parse(dbDateSent);
          ReceivedBookRequest receivedBookRequest = createReceivedBookRequest(senderId, dateSent, book!);
          tempRequestsList.add(receivedBookRequest);
        });
      }
    }
    receivedBookRequests.clear();
    receivedBookRequests.addAll(tempRequestsList);
    receivedBookRequestsUpdated();
    if (!incrementedRequestsAndBooksLoaded) {
      requestsAndBooksLoaded.value++;
      incrementedRequestsAndBooksLoaded = true;
    }
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
