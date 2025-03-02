import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/models/book_requests.dart';
import 'package:library_project/models/user.dart';
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
  DataSnapshot snapshot = await dbReference.child('users/$id').get();
  return (snapshot.value != null);
}

// TODO this should only find users based off input name or username I'd say, which should change this a bit and make userExists only relevant for auth I think
// if anyone disagrees with this speak up!
Future<String> findUser(String txt) async {
  bool isEmail = txt.contains('@');
  if (!isEmail && await userExists(txt)) {
    return txt;
  }

  DataSnapshot snapshot = await dbReference.child('users/').get();
  if (snapshot.value != null) {
    Map<dynamic, dynamic> allUsers = snapshot.value as Map<dynamic, dynamic>;
    for (var entry in allUsers.entries) {
      dynamic child = entry.value;
      if (child['email'] == txt) {
        return entry.key; // this is the 28 character uid
      }
    }
  }
  return '';
}

void addUser(User user, String username) {
  final id = dbReference.child('users/${user.uid}');
  UserModel currentUser = UserModel(
    uid: user.uid,
    name: user.displayName!,
    username: username,
    email: user.email!,
    photoUrl: user.photoURL,
    avatarColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
    isActive: true,
    isTyping: false,
    lastSignedIn: DateTime.now().toUtc(),
  );
  addUsername(username);
  id.set(currentUser.toJson());
  userModel.value = currentUser;
}


Future<bool> usernameExists(String username) async {
  if (username.contains(RegExp('[.#\$\\[\\]]'))) {
    return false;
  }
  DatabaseEvent event = await dbReference.child('usernames/$username').once();
  return (event.snapshot.value != null);
}

// call this only from the add user function
void addUsername(String username) async {
  DatabaseReference  id = dbReference.child('usernames/');
  id.update({username: true});
}

// call this everytime username gets updated
// TODO this function isnt tested. Also there really should be some update user interface function, its just bad design not to have it really.
// I shouldnt have to go thru code to update the user model I should just call a nice abstraction ya feel me
Future<void> updateUsername(String oldUsername, String newUsername, User user) async {
  removeUsername(oldUsername);
  DatabaseReference  id = dbReference.child('usernames/');
  id.update({newUsername: true});
  Map<String, dynamic> userJson = {'username': newUsername};
  DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
  await userRef.update(userJson);
}

void removeUsername(String oldUsername) {
  dbReference.child('usernames/$oldUsername').remove();
}

void sendFriendRequest(User user, String friendId) {
  var id = dbReference.child('requests/$friendId/${user.uid}');
  id.set({'sendDate': DateTime.now().toUtc().toIso8601String()});
  id = dbReference.child('sentFriendRequests/${user.uid}');
  Map<String, dynamic> map = {friendId : true};
  id.update(map);
}

Future<void> removeFriendRequest(String senderID, String receiverID) async {
  var ref = dbReference.child('sentFriendRequests/$senderID/$receiverID');
  await ref.remove();
  ref = dbReference.child('requests/$receiverID/$senderID');
  ref.remove();
}

Future<void> removeRef(DatabaseReference id) async {
  await id.remove();
}

Future<void> addFriend(String requestID, String uid) async {
  var id = dbReference.child('friends/$requestID/$uid');
  String time = DateTime.now().toUtc().toIso8601String();
  id.set({"friendsSince": time});
  id = dbReference.child('friends/$uid/$requestID');
  id.set({"friendsSince": time});

  await removeFriendRequest(requestID, uid);
}

Future<void> removeFriend(String uid, String friendId) async {
  DatabaseReference friend = dbReference.child('friends/$uid/$friendId');
  await friend.remove();
  friend = dbReference.child('friends/$friendId/$uid');
  await friend.remove();
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

// TODO this is one of the things which should be removed in favor of the userIdToUserModel right?
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
