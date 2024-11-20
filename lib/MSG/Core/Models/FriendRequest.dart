import 'package:firebase_database/firebase_database.dart';

import '../Enumerations/FriendRequestStatus.dart';

class FriendRequest {
  final String requestId;
  final String senderId;
  final String recipientId;
  final FriendRequestStatus status; // Pending, Accepted, Rejected

  FriendRequest({
    required this.requestId,
    required this.senderId,
    required this.recipientId,
    this.status = FriendRequestStatus.pending,
  });

// ... other methods like copyWith, fromDataSnapshot, and toMap
  FriendRequest copyWith({
    String? requestId,
    String? senderId,
    String? recipientId,
    FriendRequestStatus? status,
  }) {
    return FriendRequest(
      requestId: requestId ?? this.requestId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      status: status ?? this.status,
    );
  }
  factory FriendRequest.fromDataSnapshot(DataSnapshot snapshot) {
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return FriendRequest(
      requestId: data["requestId"],
      senderId: data["senderId"],
      recipientId: data["recipientId"],
      status: data["status"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'senderId': senderId,
      'recipientId': recipientId,
      'status': status,
    };
  }
}