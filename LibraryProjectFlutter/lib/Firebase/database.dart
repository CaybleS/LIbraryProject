import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:library_project/Social/chat.dart';
import 'package:library_project/Social/friends_page.dart';
import '../Books/book.dart';
import 'user_info.dart';

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

Future<bool> userExists(String id) async {
  DatabaseEvent event = await dbReference.child('users/$id').once();
  return (event.snapshot.value != null);
}

void addUser(User user) {
  String? name = user.displayName;
  String? email = user.email;

  AppUserInfo info = AppUserInfo(user.uid, name!, email! /*, "Unavailable"*/);
  var id = dbReference.child('users/${user.uid}');
  id.set(info.toJson());
}

void sendFriendRequest(User user, String friendId) {
  var id = dbReference.child('requests/$friendId/').push();
  id.set({
    'sender': user.uid,
    'receiver': friendId,
    'sendDate': DateTime.now().millisecondsSinceEpoch
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
  int time = DateTime.now().millisecondsSinceEpoch;
  var id = dbReference.child('friends/${request.senderId}/${request.uid}');
  id.set({"friendsSince": time});
  id = dbReference.child('friends/${request.uid}/${request.senderId}');
  id.set({"friendsSince": time});

  await request.delete();
}

Future<List<Friend>> getFriends(User user) async {
  DatabaseEvent event = await dbReference.child('friends/${user.uid}/').once();
  List<Friend> friends = [];

  if (event.snapshot.value != null) {
    for (var child in event.snapshot.children) {
      Friend friend = Friend('${child.key}');
      DatabaseEvent friendInfo =
          await dbReference.child('users/${child.key}').once();
      if (friendInfo.snapshot.value != null) {
        Map data = friendInfo.snapshot.value as Map;
        friend.name = data['name'];
        friend.email = data['email'];
      }
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
