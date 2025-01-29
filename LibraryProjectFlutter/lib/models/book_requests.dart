import 'package:firebase_database/firebase_database.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/book.dart';

class SentBookRequest {
  String receiverId;
  DateTime sendDate;
  late Book book;
  late DatabaseReference _id;

  SentBookRequest(this.receiverId, this.sendDate);

  void setId(DatabaseReference id) {
    _id = id;
  }

  void remove() {
    removeRef(_id);
  }

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

class ReceivedBookRequest {
  String senderId;
  DateTime sendDate;
  late Book book;
  late DatabaseReference _id;

  ReceivedBookRequest(this.senderId, this.sendDate);

  void setId(DatabaseReference id) {
    _id = id;
  }

  void remove() {
    removeRef(_id);
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'sendDate': sendDate.toIso8601String(),
    };
  }
}

ReceivedBookRequest createReceivedBookRequest(dynamic record, Book book) {
  String senderId = record['senderId'];
  DateTime sendDate = DateTime.parse(record['sendDate']);
  ReceivedBookRequest receivedBookRequest = ReceivedBookRequest(senderId, sendDate);
  receivedBookRequest.book = book;
  return receivedBookRequest;
}