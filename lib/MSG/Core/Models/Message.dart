import 'package:firebase_database/firebase_database.dart';

import '../Enumerations/MessageType.dart';

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime timestamp;
  final MessageType messageType;
  final String? mediaUrl; // Optional, for media messages
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.mediaUrl = "",
    this.isRead = false

  });


  Message copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? content,
    DateTime? timestamp,
    MessageType? messageType,
    String? mediaUrl,
    bool? isRead
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isRead: isRead ?? this.isRead
    );
  }
  factory Message.fromDataSnapshot(DataSnapshot snapshot) {
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return Message(
      id: data["id"],
      senderId: data["senderId"],
      recipientId: data["recipientId"],
      content: data["content"],
      timestamp: data["timestamp"],
      messageType: data["messageType"],
      mediaUrl: data["mediaUrl"],
      isRead: data["isRead"]
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'timestamp': timestamp,
      'messageType': messageType,
      'mediaUrl':mediaUrl,
      'isRead':isRead
    };
  }


}