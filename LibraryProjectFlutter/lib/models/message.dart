import 'package:library_project/models/user.dart';

class Message {
  String id;
  String text;
  UserModel sender;
  String? replyTo;
  UserModel? userReply;
  bool isEdited;
  DateTime date;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.date,
    this.replyTo,
    this.userReply,
    this.isEdited = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      sender: UserModel.fromJson(json['sender']),
      date: DateTime.parse(json['date']),
      replyTo: json['replyTo'],
      userReply: json['userReply'] != null ? UserModel.fromJson(json['userReply']) : null,
      isEdited: json['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender.toJson(),
      'replyTo': replyTo,
      'userReply': userReply?.toJson(),
      'date': date.toIso8601String(),
      'isEdited': isEdited,
    };
  }
}