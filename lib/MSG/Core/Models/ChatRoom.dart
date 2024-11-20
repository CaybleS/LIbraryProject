import 'package:firebase_database/firebase_database.dart';

import 'Message.dart';

class ChatRoom {
  final String roomId;
  final String roomName;
  final List<String> members;
  final Message lastMessage;
  final DateTime createdAt;

  ChatRoom({
    required this.roomId,
    required this.roomName,
    required this.members,
    required this.lastMessage,
    required this.createdAt,
  });

// ... other methods like copyWith, fromDataSnapshot, and toMap

  ChatRoom copyWith({
    String? roomId,
    String? roomName,
    List<String>? members,
    Message? lastMessage,
    DateTime? createdAt,

  }) {
    return ChatRoom(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  factory ChatRoom.fromDataSnapshot(DataSnapshot snapshot) {
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return ChatRoom(
        roomId: data["roomId"],
        roomName: data["roomName"],
        members: List<String>.from(data['members'] ?? []),
        lastMessage: data["lastMessage"],
        createdAt: data["createdAt"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'members': members,
      'lastMessage': lastMessage,
      'createdAt': createdAt,
    };
  }


}