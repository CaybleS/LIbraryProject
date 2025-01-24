import 'package:library_project/models/message.dart';

enum ChatType { private, group }

class Chat {
  final String id;
  final ChatType type;
  final String name;
  final String? chatImage;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? createdBy;
  final List<String> participants;
  final Map<String, MessageModel>? messages;
  final Map<String, String?> lastReadMessages;
  final int unreadCount;

  Chat({
    required this.id,
    this.type = ChatType.private,
    required this.name,
    this.chatImage,
    this.lastMessage,
    this.lastMessageTime,
    this.createdBy,
    this.participants = const [],
    this.messages,
    this.lastReadMessages = const {},
    this.unreadCount = 0,
  });

  factory Chat.fromJson(String id, Map<dynamic, dynamic> json) => Chat(
        id: id,
        type: ChatType.values.byName(json['info']['type'] ?? 'private'),
        name: json['info']['name'],
        chatImage: json['info']['chatImage'],
        createdBy: json['info']['createdBy'],
        participants: (json['participants'] as Map?)?.keys.cast<String>().toList() ?? [],
        messages: (json['messages'] as Map?)?.map(
              (key, value) => MapEntry(key, MessageModel.fromJson(key, value)),
            ) ??
            {},
        lastReadMessages: (json['cursor'] as Map?)?.cast<String, String?>() ?? {},
      );

  Map<String, dynamic> toJson() => {
        'info': {
          'type': type.name,
          'name': name,
          'createdBy': createdBy,
          'chatImage': chatImage,
        },
        'participants': {for (var uid in participants) uid: true},
        if (messages != null) 'messages': {for (var entry in messages!.entries) entry.key: entry.value.toJson()},
        'cursor': lastReadMessages,
      };

  Chat copyWith({
    String? id,
    ChatType? type,
    String? name,
    String? chatImage,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? createdBy,
    List<String>? participants,
    Map<String, MessageModel>? messages,
    Map<String, String?>? lastReadMessages,
    int? unreadCount,
  }) =>
      Chat(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        chatImage: chatImage ?? this.chatImage,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        createdBy: createdBy ?? this.createdBy,
        participants: participants ?? this.participants,
        messages: messages ?? this.messages,
        lastReadMessages: lastReadMessages ?? this.lastReadMessages,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

// class ChatShort {
//   // late DatabaseReference _id;
//   late String roomID;
//   String type;
//   String name;
//   String lastMsg;
//   String? lastSender;
//   String? displayName;
//   DateTime lastTime;
//
//   ChatShort(this.type, this.name, this.lastMsg, this.lastTime, [this.lastSender]);
//
//   Map<String, dynamic> toJson() {
//     return {
//       'type': type,
//       'name': name,
//       'lastMsg': lastMsg,
//       'lastSender': lastSender,
//       'lastTime': lastTime,
//     };
//   }
//
//   Widget getCard(Size size, int index, Function(String) chatClicked) {
//     String lastMessage = "";
//     Icon icon = const Icon(Icons.person);
//     DateTime lastMsgSent = lastTime.toLocal();
//
//     if (type == "group") {
//       lastMessage += "$lastSender: $lastMsg";
//       icon = const Icon(Icons.people);
//     }
//     if (type == "individual") {
//       lastMessage += lastMsg;
//     }
//
//     DateTime startOfDay = DateTime.now().toLocal();
//     String timeText = "";
//     startOfDay = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
//
//     if (lastMsgSent.isBefore(startOfDay)) {
//       if (lastMsgSent.isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
//         if (lastMsgSent.isBefore(DateTime(startOfDay.year - 1, startOfDay.month, startOfDay.day))) {
//           timeText = DateFormat.yMMMd().format(lastMsgSent);
//         } else {
//           timeText = DateFormat.MMMd().format(lastMsgSent);
//         }
//       } else {
//         switch (lastMsgSent.weekday) {
//           case 1:
//             timeText = "Mon";
//             break;
//           case 2:
//             timeText = "Tue";
//             break;
//           case 3:
//             timeText = "Wed";
//             break;
//           case 4:
//             timeText = "Thurs";
//             break;
//           case 5:
//             timeText = "Fri";
//             break;
//           case 6:
//             timeText = "Sat";
//             break;
//           case 7:
//             timeText = "Sun";
//             break;
//         }
//       }
//     } else {
//       timeText = DateFormat.jm().format(lastMsgSent);
//     }
//
//     return InkWell(
//         onTap: () {
//           chatClicked(roomID);
//         },
//         child: Card(
//             margin: const EdgeInsets.all(5),
//             child: Row(children: [
//               SizedBox(
//                 width: size.width * 0.03,
//               ),
//               SizedBox(
//                   width: size.width * 0.6,
//                   height: size.height * 0.095,
//                   child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Column(
//                         children: [
//                           SizedBox(
//                             height: size.height * 0.02,
//                           ),
//                           Align(
//                               alignment: Alignment.centerLeft,
//                               child: Text(
//                                 displayName!,
//                                 style: const TextStyle(color: Colors.black, fontSize: 20),
//                                 softWrap: true,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               )),
//                           Align(
//                               alignment: Alignment.centerLeft,
//                               child: Text(
//                                 lastMessage,
//                                 style: const TextStyle(color: Colors.black, fontSize: 16),
//                                 softWrap: true,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               )),
//                         ],
//                       ))),
//               SizedBox(
//                   height: size.height * 0.095,
//                   width: size.width * 0.3,
//                   child: Column(
//                     children: [
//                       SizedBox(
//                         height: size.height * 0.025,
//                       ),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: icon,
//                       ),
//                       Align(
//                           alignment: Alignment.centerRight,
//                           child: Text(timeText, style: const TextStyle(color: Colors.black, fontSize: 16)))
//                     ],
//                   ))
//             ])));
//   }
// }
//
// Future<ChatShort> createChatDisplay(record) async {
//   ChatShort chat = ChatShort(record['type'], record['name'], record['lastMsg'], DateTime.parse(record['lastTime']));
//
//   if (record.containsKey('lastSender')) {
//     chat.lastSender = record['lastSender'];
//     chat.lastSender = await getUserDisplayName(chat.lastSender!);
//   }
//
//   if (chat.type == "individual") {
//     chat.displayName = await getUserDisplayName(chat.name);
//   } else {
//     chat.displayName = chat.name;
//   }
//
//   return chat;
// }
