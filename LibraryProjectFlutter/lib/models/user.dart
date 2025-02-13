import 'package:flutter/material.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final bool isActive;
  final bool isTyping;
  final Color avatarColor;
  final DateTime lastSignedIn;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarColor,
    this.photoUrl,
    required this.isActive,
    this.isTyping = false,
    required this.lastSignedIn,
  });

  factory UserModel.fromJson(Map<dynamic, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      avatarColor: Color(json['avatarColor'] ?? Colors.grey.value),
      isActive: json['isActive'],
      isTyping: json['isTyping'],
      lastSignedIn: DateTime.parse(json['lastSignedIn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'avatarColor': avatarColor.value,
      'isActive': isActive,
      'isTyping': isTyping,
      'lastSignedIn': lastSignedIn.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserModel{uid: $uid, name: $name, email: $email, photoUrl: $photoUrl, isActive: $isActive, isTyping: $isTyping, lastSignedIn: $lastSignedIn}';
  }

  @override
  bool operator ==(Object other) {
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
