import 'package:library_project/models/book.dart';
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
// Thats why its stored uid/bookkey, but beyond that there is just a bunch of senders, represented as a map of sender : dateSent. This is needed since any
// book can have any N number of requests for it. Pretty sure this is optimal. So the representation in the database is not the representation of the object itself.
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