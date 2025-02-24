import 'package:flutter/material.dart';

class UserModel {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String? photoUrl;
  final bool isActive;
  final bool isTyping;
  final Color avatarColor;
  final DateTime lastSignedIn;

  UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.avatarColor,
    this.photoUrl,
    required this.isActive,
    this.isTyping = false,
    required this.lastSignedIn,
  });

  factory UserModel.fromJson(Map<dynamic, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      name: json['name'],
      // TODO remove this placeholder when username is set in some way, it should just be set in the profile setup page which will update the database.dart addUser function
      username: json['username'] ?? "placeholder",
      email: json['email'],
      photoUrl: json['photoUrl'],
      avatarColor: Color(json['avatarColor'] ?? Colors.grey.value),
      isActive: json['isActive'],
      isTyping: json['isTyping'],
      lastSignedIn: DateTime.parse(json['lastSignedIn']),
    );
  }

  // TODO need to remove uid from this and add username and change the user== to compare username I'd say since that should be unique to a specific user as well.
  // with this, users would be identified only with name and username, username being unique and name obviously not being unique. This file will be updated to reflect this.
  // which will involve first setting a default username value in addUser in database.dart and then later on setting up the option for user to set username on profile
  // and the profile setup page which doesnt exist yet
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'avatarColor': avatarColor.value,
      'isActive': isActive,
      'isTyping': isTyping,
      'lastSignedIn': lastSignedIn.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserModel{uid: $uid, name: $name, username: $username, email: $email, photoUrl: $photoUrl, isActive: $isActive, isTyping: $isTyping, lastSignedIn: $lastSignedIn}';
  }

  @override
  bool operator ==(Object other) {
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
