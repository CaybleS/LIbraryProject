import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/models/book_requests_model.dart';
import 'package:shelfswap/models/notification.dart';
import 'package:shelfswap/models/user.dart';
import 'dart:async';

import 'package:shelfswap/notifications/notification_channel_manager.dart';
import 'package:shelfswap/notifications/send_notifications.dart';

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
DatabaseReference addLentBookInfo(
    DatabaseReference bookDbRef, LentBookInfo lentBook, String borrowerId) {
  DatabaseReference id = dbReference.child('booksLent/$borrowerId/').push();
  id.set(lentBook.toJson(bookDbRef.key!));
  return id;
}

void removeLentBookInfo(String lentDbKey, String borrowerId) {
  dbReference.child('booksLent/$borrowerId/$lentDbKey').remove();
}

void addSentBookRequest(
    SentBookRequest sentBookRequest, String senderId, String bookDbKey) {
  DatabaseReference id =
      dbReference.child('sentBookRequests/$senderId/$bookDbKey/');
  id.set(sentBookRequest.toJson());
}

Future<void> addReceivedBookRequest(String senderId, DateTime sendDate,
    String receiverId, String bookDbKey) async {
  DataSnapshot snapshot = await dbReference
      .child('receivedBookRequests/$receiverId/$bookDbKey/senders/')
      .get();
  Map<String, String> senders = {};
  // if there are already senders we need to fetch them before adding our new sender to them
  if (snapshot.value != null) {
    // need to create the map like this, safely, rather than just raw type casting
    senders = (snapshot.value as Map).map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
  DatabaseReference id =
      dbReference.child('receivedBookRequests/$receiverId/$bookDbKey/');
  senders[senderId] = sendDate.toIso8601String();
  id.set({'senders': senders});
}

Future<void> removeBookRequestData(
    String requesterId, String userId, String bookDbKey,
    {bool removeAllReceivedRequests = false}) async {
  dbReference.child('sentBookRequests/$requesterId/$bookDbKey').remove();
  // slight optimization to prevent removing receivers in the case where user just removes the book (the function still needs to be called N times
  // for the number of request senders in this case to remove all the sender requests separately though).
  if (removeAllReceivedRequests) {
    dbReference.child('receivedBookRequests/$userId/$bookDbKey').remove();
  } else {
    // need to see current senders and update as needed
    DataSnapshot snapshot = await dbReference
        .child('receivedBookRequests/$userId/$bookDbKey/senders/')
        .get();
    if (snapshot.value != null) {
      Map<String, String> senders = (snapshot.value as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      senders.remove(requesterId);
      DatabaseReference id =
          dbReference.child('receivedBookRequests/$userId/$bookDbKey/');
      id.set({'senders': senders});
    } else {
      // there are no senders so we just remove everything (assuming the get() call doesn't return null when there is in fact data there...)
      dbReference.child('receivedBookRequests/$userId/$bookDbKey').remove();
    }
  }
}

Future<bool> userExists(String id) async {
  if (id.contains(RegExp('[.#\$\\[\\]]'))) {
    return false;
  }
  DataSnapshot snapshot = await dbReference.child('users/$id/username').get();
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
      if (child['username'] == txt) {
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
  DataSnapshot snapshot = await dbReference.child('usernames/$username').get();
  return (snapshot.value != null);
}

// call this only from the add user function
void addUsername(String username) async {
  DatabaseReference id = dbReference.child('usernames/');
  id.update({username: true});
}

Future<void> sendFriendRequest(User user, String friendId) async {
  var id = dbReference.child('requests/$friendId/${user.uid}');
  id.set({'sendDate': DateTime.now().toUtc().toIso8601String()});
  id = dbReference.child('sentFriendRequests/${user.uid}');
  Map<String, dynamic> map = {friendId: true};
  id.update(map);

  NotificationData notifData = NotificationData(
      "New friend request",
      "You have recieved a friend request from ${userIdToUserModel[user.uid]?.name}",
      NotificationChannel.incoming_friend_request,
      friendId);
  await sendNotification(notifData);
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
  // removing friends silently also removes all book requests involving the 2 users
  await removeAllBookRequestsInvolvingThisUser(uid, friendId);
  await removeAllBookRequestsInvolvingThisUser(friendId, uid);
}

Future<Map<String, dynamic>> getChatInfo(String roomID) async {
  DatabaseEvent event = await dbReference.child('chatInfo/$roomID').once();
  Map<String, dynamic> map = {};

  if (event.snapshot.value != null) {
    Map<String, dynamic> tempMap =
        Map<String, dynamic>.from(event.snapshot.value as Map);

    map['type'] = tempMap['type'];

    Map<String, String> memberMap = {};
    Map<String, String> memberIDs =
        Map<String, String>.from(tempMap['members'] as Map);

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

// I'm storing lastModified here since firebase cloud messaging documentation recommends it, I guess for scalability/future modifications
// in case the database wants to be cleaned up. The notification sender logic detects invalid tokens and deletes them, and tokens can be
// invalidated if an app gets uninstalled, or it reaches 270 days of "inactivity", or something like this. Basically, timestamps are just stored
// if you want to create some independent job, like an eventbridge scheduler cron job which runs once a month and goes through all tokens and
// deletes super old ones. Old tokens which aren't being sent to will just persist for years otherwise. Its good design but I'm not gonna
// do it right now, but its an option for the future.
// I would say, as a side note, that I wouldn't check timestamps in the lambda's send notification logic, since firebase cloud messaging
// has its own logic for invalidating tokens. You could, but in many cases it will handle them without that. If a token is being
// sent to enough, it will either be ok, or deleted, the main reason for the lastModified timestamps is to allow for handling of tokens
// which don't get sent to ever, to cleanup the database one day.
void writeUserTokenData(String userToken, String userId) {
  // storing the token as the db key to make it easy to access it
  DatabaseReference id =
      dbReference.child('notifications/userTokens/$userId/$userToken/');
  Map<String, dynamic> dataToWrite = {
    'lastModified': DateTime.now().toUtc().toIso8601String(),
  };
  id.update(dataToWrite);
}

void removeUserTokenData(String userToken, String userId) {
  DatabaseReference id =
      dbReference.child('notifications/userTokens/$userId/$userToken/');
  removeRef(id);
}
