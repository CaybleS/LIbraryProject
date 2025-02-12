import 'package:flutter/material.dart';
import 'package:library_project/app_startup/global_variables.dart';

enum ChatType { private, group }

class Chat {
  final String id;
  final ChatType type;
  final String name;
  final String? chatImage;
  final String? lastMessage;
  final String? lastMessageSender;
  final DateTime? lastMessageTime;
  final Color avatarColor;
  final String? createdBy;
  final List<String> participants;
  final Map<String, String?> lastReadMessages;
  final int unreadCount;

  Chat({
    required this.id,
    this.type = ChatType.private,
    required this.name,
    this.chatImage,
    this.lastMessage,
    this.lastMessageSender,
    this.lastMessageTime,
    this.avatarColor = Colors.transparent,
    this.createdBy,
    this.participants = const [],
    this.lastReadMessages = const {},
    this.unreadCount = 0,
  });

  factory Chat.fromJson(String id, Map<dynamic, dynamic> json) {
    List<String> names = (json['info']['name'] as String).split('*');
    return Chat(
      id: id,
      type: ChatType.values.byName(json['info']['type'] ?? 'private'),
      name: json['info']['type'] == 'group'
          ? json['info']['name']
          : names.firstWhere((element) => element != userModel.value!.name),
      chatImage: json['info']['chatImage'],
      createdBy: json['info']['createdBy'],
      avatarColor: Color(json['info']['avatarColor'] ?? Colors.grey.value),
      participants: (json['participants'] as Map?)?.keys.cast<String>().toList() ?? [],
      lastReadMessages: (json['cursor'] as Map?)?.cast<String, String?>() ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'info': {
          'type': type.name,
          'name': name,
          'createdBy': createdBy,
          'chatImage': chatImage,
          'avatarColor': avatarColor.value,
        },
        'participants': {for (var uid in participants) uid: true},
        'cursor': lastReadMessages,
      };

  Chat copyWith({
    String? id,
    ChatType? type,
    String? name,
    String? chatImage,
    String? lastMessage,
    String? lastMessageSender,
    DateTime? lastMessageTime,
    String? createdBy,
    List<String>? participants,
    Map<String, String?>? lastReadMessages,
    int? unreadCount,
    Color? avatarColor,
  }) =>
      Chat(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        chatImage: chatImage ?? this.chatImage,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageSender: lastMessageSender ?? this.lastMessageSender,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        createdBy: createdBy ?? this.createdBy,
        participants: participants ?? this.participants,
        lastReadMessages: lastReadMessages ?? this.lastReadMessages,
        unreadCount: unreadCount ?? this.unreadCount,
        avatarColor: avatarColor ?? this.avatarColor,
      );
}
