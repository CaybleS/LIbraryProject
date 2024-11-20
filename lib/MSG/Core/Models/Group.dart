import 'package:firebase_database/firebase_database.dart';

class Group {
  final String groupId;
  final String groupName;
  final String groupDescription;
  final List<String> members;
  final String groupImage; // Optional, for group profile picture

  Group({
    required this.groupId,
    required this.groupName,
    required this.groupDescription,
    this.members = const [],
    this.groupImage = '',
  });

// ... other methods like copyWith, fromDataSnapshot, and toMap
  Group copyWith({
    String? groupId,
    String? groupName,
    String? groupDescription,
    List<String>? members,
    String? groupImage,
  }) {
    return Group(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      members: members ?? this.members,
      groupImage: groupImage ?? this.groupImage,
    );
  }
  factory Group.fromDataSnapshot(DataSnapshot snapshot) {
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return Group(
      groupId: data["groupId"],
      groupName: data["groupName"],
      groupDescription: data["groupDescription"],
      members: List<String>.from(data['members'] ?? []),
      groupImage: data["groupImage"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'members': members,
      'groupImage': groupImage,
    };
  }
}