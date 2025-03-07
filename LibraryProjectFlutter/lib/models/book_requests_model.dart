import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/database/database.dart';
import 'package:shelfswap/database/subscriptions.dart';
import 'package:shelfswap/models/book.dart';
import 'dart:async';
// maybe could have designed it better but basically, if a book is removed, all requests for it need to be deleted as well,
// so most of the logic for these requests is in the book and database files. This file is just the simple requests which
// we will have lists for throughout the app.
// these dont have setId, or remove functions, since the deletion logic needs to be tied to both the requests and to the book
// itself, so I felt it easier to just tie it to receiver id and/or sender id, and book db key (which is all that is needed to delete any)

class SentBookRequest {
  String receiverId;
  DateTime sendDate;
  late Book book;

  SentBookRequest(this.receiverId, this.sendDate);

  Map<String, dynamic> toJson() {
    return {
      'receiverId': receiverId,
      'sendDate': sendDate.toIso8601String(),
    };
  }
}

SentBookRequest createSentBookRequest(dynamic record, Book book) {
  String receiverId = record['receiverId'];
  DateTime sendDate = DateTime.parse(record['sendDate']);
  SentBookRequest sentBookRequest = SentBookRequest(receiverId, sendDate);
  sentBookRequest.book = book;
  return sentBookRequest;
}

// In case you wonder why its done this way, basically the received requests store the receiver id first and then the book db key. It needs to be
// this way so that any user can immediately view all requests sent to them, and also removing a book will remove all requests for this book.
// Thats why its stored uid/bookkey, but beyond that there is just a bunch of senders, represented as a map of sender : sendDate. This is needed since any
// book can have any N number of requests for it. Pretty sure this is optimal. So the representation in the database is not the representation of the object itself.
// It's stored as this map rather than some list [0], [1] with a map of senderId, sentDate for each index so that removing the 0th index of that list for example
// doesnt cause the rest of the entries to move up 1 (assumming the list will not have gaps in indicies when stored in the database, I guess it could and it'd be fine but whatev)
class ReceivedBookRequest {
  String senderId;
  DateTime sendDate;
  late Book book;

  ReceivedBookRequest(this.senderId, this.sendDate);
}

ReceivedBookRequest createReceivedBookRequest(String senderId, DateTime sendDate, Book book) {
  ReceivedBookRequest receivedBookRequest = ReceivedBookRequest(senderId, sendDate);
  receivedBookRequest.book = book;
  return receivedBookRequest;
}

// this will be called for the unfriend feature and the delete account feature I'd say so in both cases you have the books already somewhere
// for removing friends this will need to be called twice, to remove each user's relevant request database data. It's only so complicated
// since each book stores info on who requested it (so that removing a book removes all requests for it).
Future<void> removeAllBookRequestsInvolvingThisUser(String userUid, String uidToDeleteBookRequestsFor, {deletingThisAccount = false}) async {
  // I think this is needed in the case where we dont load this friends books by going to their friends library page since we're gonna need them
  if (uidToDeleteBookRequestsFor != userUid && friendIdToBooks[uidToDeleteBookRequestsFor] == null) {
    Completer<void> blockUntilFriendsBooksLoaded = Completer<void>();
    friendIdToLibrarySubscription[uidToDeleteBookRequestsFor] = setupFriendsBooksSubscription(
      friendIdToBooks, uidToDeleteBookRequestsFor, friendsBooksUpdated, signalFriendsBooksLoaded: blockUntilFriendsBooksLoaded);
    await blockUntilFriendsBooksLoaded.future;
  }
  // 1.) removing all this users sentBookRequests usersWhoRequested tied to their books (since each book stores in it all users who requested it)
  sentBookRequests.forEach((k, v) async {
    List<Book> books = friendIdToBooks[v.receiverId]!;
    for (Book book in books) {
      if (book.id.key! == k) {
        // 2.) removing all book requests stored associated with this user's sent requests
        await removeBookRequestData(uidToDeleteBookRequestsFor, v.receiverId, book.id.key!);
        book.usersWhoRequested!.remove(uidToDeleteBookRequestsFor);
        if (book.usersWhoRequested!.isEmpty) {
          book.usersWhoRequested = null;
        }
        book.update();
        break;
      }
    }
  });
  List<Book> books = [];
  // 3.) removing all this users receivedBookRequests usersWhoRequested tied to their books
  books = (uidToDeleteBookRequestsFor == userUid) ? userLibrary : friendIdToBooks[uidToDeleteBookRequestsFor]!;
  for (Book book in books) {
    if (book.usersWhoRequested != null) {
      for (int i = 0; i < book.usersWhoRequested!.length; i++) {
        // 4.) removing all book requests stored associated with this user's received requests
        await removeBookRequestData(book.usersWhoRequested![i], uidToDeleteBookRequestsFor, book.id.key!, removeAllReceivedRequests: true);
      }
    }
    book.usersWhoRequested = null;
    // in this case we are deleting this users entire account if this bool is true so this book will just get deleted from the database anyway
    // so dont need to update it here (its an almost useless optimization but whatever)
    if (!deletingThisAccount) {
      book.update();
    }
  }
}
