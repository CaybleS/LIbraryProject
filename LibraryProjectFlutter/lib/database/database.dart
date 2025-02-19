import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/models/book_requests.dart';
import 'package:library_project/models/profile_info.dart';
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
  // if there are already senders we need to fetch them before adding our new sender to them
  if (event.snapshot.value != null) {
    // need to create the map like this, safely, rather than just raw type casting
    senders = (event.snapshot.value as Map).map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
  DatabaseReference id = dbReference.child('receivedBookRequests/$receiverId/$bookDbKey/');
  senders[senderId] = sendDate.toIso8601String();
  id.set({'senders': senders});
}

Future<void> removeBookRequestData(String requesterId, String userId, String bookDbKey,
    {bool removeAllReceivedRequests = false}) async {
  dbReference.child('sentBookRequests/$requesterId/$bookDbKey').remove();
  // slight optimization to prevent removing receivers in the case where user just removes the book (the function still needs to be called N times
  // for the number of request senders in this case to remove all the sender requests separately though).
  if (removeAllReceivedRequests) {
    dbReference.child('receivedBookRequests/$userId/$bookDbKey').remove();
  } else {
    // need to see current senders and update as needed
    DatabaseEvent event = await dbReference.child('receivedBookRequests/$userId/$bookDbKey/senders/').once();
    if (event.snapshot.value != null) {
      Map<String, String> senders = (event.snapshot.value as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      senders.remove(requesterId);
      DatabaseReference id = dbReference.child('receivedBookRequests/$userId/$bookDbKey/');
      id.set({'senders': senders});
    } else {
      // there are no senders so we just remove everything
      dbReference.child('receivedBookRequests/$userId/$bookDbKey').remove();
    }
  }
}


Future<bool> userExists(String id) async {
  if (id.contains(RegExp('[.#\$\\[\\]]'))) {
    return false;
  }
  DatabaseEvent event = await dbReference.child('users/$id').once();
  return (event.snapshot.value != null);
}

// TODO this should only find users based off input name or username I'd say, which should change this a bit and make userExists only relevant for auth I think
// if anyone disagrees with this speak up!
Future<String> findUser(String txt) async {
  bool isEmail = txt.contains('@');
  if (!isEmail && await userExists(txt)) {
    return txt;
  }

  DatabaseEvent event = await dbReference.child('users/').once();
  if (event.snapshot.value != null) {
    Map<dynamic, dynamic> allUsers = event.snapshot.value as Map<dynamic, dynamic>;
    for (var entry in allUsers.entries) {
      dynamic child = entry.value;
      if (child['email'] == txt) {
        return entry.key; // this is the 28 character uid
      }
    }
  }
  return '';
}

void addUser(User user) {
  final id = dbReference.child('users/${user.uid}');
  UserModel currentUser = UserModel(
    uid: user.uid,
    name: user.displayName!,
    email: user.email!,
    photoUrl: user.photoURL,
    avatarColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
    isActive: true,
    isTyping: false,
    lastSignedIn: DateTime.now().toUtc(),
  );
  id.set(currentUser.toJson());
  userModel.value = currentUser;
}

void sendFriendRequest(User user, String friendId) {
  var id = dbReference.child('requests/$friendId/').push();
  id.set({'sender': user.uid, 'sendDate': DateTime.now().toUtc().toIso8601String()});
}

Future<void> removeRef(DatabaseReference id) async {
  await id.remove();
}

Future<void> addFriend(Request request) async {
  var id = dbReference.child('friends/${request.senderId}/${request.uid}');
  String time = DateTime.now().toUtc().toIso8601String();
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

Future<void> updateProfile(String uid, ProfileInfo profile) async {
  var id = dbReference.child('profileInfo/$uid');
  id.set(profile.toJson());
}
