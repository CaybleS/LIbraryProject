

import 'package:firebase_database/firebase_database.dart';

class AppUser {
  final String userId;
  final String name;
  final String username;
  final int lastSignedIn;
  final int createdTime;
  final String imageAddress;
  final bool isActive;
  final Map<String,dynamic> friends;
  final List<String> groups;

  AppUser({
    required this.userId,
    required this.name,
    required this.username,
    required this.lastSignedIn,
    required this.createdTime,
    this.imageAddress = "",
    required this.isActive,
    required this.friends,
    this.groups = const [],
  });
  AppUser copyWith({
    String? userId,
    String? name,
    String? username,
    int? lastSignedIn,
    int? createdTime,
    String? imageAddress,
    bool? isActive,
    Map<String , dynamic>? friends,
    List<String>? groups,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      lastSignedIn: lastSignedIn ?? this.lastSignedIn,
      createdTime: createdTime ?? this.createdTime,
      imageAddress: imageAddress ?? this.imageAddress,
      isActive: isActive ?? this.isActive,
      friends: friends ?? this.friends,
      groups: groups ?? this.groups,
    );
  }
  factory AppUser.fromDataSnapshot(DataSnapshot snapshot) {
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return AppUser(
      userId: data['userId'],
      name: data['name'],
      username: data['username'],
      lastSignedIn: data['lastSignedIn'],
      createdTime: data['createdTime'],
      imageAddress: data['imageAddress'],
      isActive: data['isActive'],
      friends: Map<String,dynamic>.from(data['friends'] ?? []),
      groups: List<String>.from(data['groups'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'username': username,
      'lastSignedIn': lastSignedIn,
      'createdTime': createdTime,
      'imageAddress': imageAddress,
      'isActive': isActive,
      'friends': friends,
      'groups': groups,
    };
  }
}
