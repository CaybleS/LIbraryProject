import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Firebase/database.dart';

class ChatShort {
  // late DatabaseReference _id;
  late String roomID;
  String type;
  String name;
  String lastMsg;
  String? lastSender;
  String? displayName;
  DateTime lastTime;

  ChatShort(this.type, this.name, this.lastMsg, this.lastTime,
      [this.lastSender]);

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'lastMsg': lastMsg,
      'lastSender': lastSender,
      'lastTime': lastTime,
    };
  }

  Widget getCard(Size size, int index, Function(String) chatClicked) {
    String lastMessage = "";
    Icon icon = const Icon(Icons.person);
    DateTime lastMsgSent = lastTime.toLocal();

    if (type == "group") {
      lastMessage += "$lastSender: $lastMsg";
      icon = const Icon(Icons.people);
    }
    if (type == "individual") {
      lastMessage += lastMsg;
    }

    DateTime startOfDay = DateTime.now().toLocal();
    String timeText = "";
    startOfDay = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);

    if (lastMsgSent.isBefore(startOfDay)) {
      if (lastMsgSent
          .isBefore(DateTime.now().subtract(const Duration(days: 7)))) {
        if (lastMsgSent.isBefore(
            DateTime(startOfDay.year - 1, startOfDay.month, startOfDay.day))) {
          timeText = DateFormat.yMMMd().format(lastMsgSent);
        } else {
          timeText = DateFormat.MMMd().format(lastMsgSent);
        }
      } else {
        switch (lastMsgSent.weekday) {
          case 1:
            timeText = "Mon";
            break;
          case 2:
            timeText = "Tue";
            break;
          case 3:
            timeText = "Wed";
            break;
          case 4:
            timeText = "Thurs";
            break;
          case 5:
            timeText = "Fri";
            break;
          case 6:
            timeText = "Sat";
            break;
          case 7:
            timeText = "Sun";
            break;
        }
      }
    } else {
      timeText = DateFormat.jm().format(lastMsgSent);
    }

    return InkWell(
        onTap: () {
          chatClicked(roomID);
        },
        child: Card(
            margin: const EdgeInsets.all(5),
            child: Row(children: [
              SizedBox(
                width: size.width * 0.03,
              ),
              SizedBox(
                  width: size.width * 0.6,
                  height: size.height * 0.095,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        children: [
                          SizedBox(
                            height: size.height * 0.02,
                          ),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                displayName!,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 20),
                                softWrap: true,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                lastMessage,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16),
                                softWrap: true,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ))),
              SizedBox(
                  height: size.height * 0.095,
                  width: size.width * 0.3,
                  child: Column(
                    children: [
                      SizedBox(
                        height: size.height * 0.025,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: icon,
                      ),
                      Align(
                          alignment: Alignment.centerRight,
                          child: Text(timeText,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 16)))
                    ],
                  ))
            ])));
  }
}

Future<ChatShort> createChatDisplay(record) async {
  ChatShort chat = ChatShort(record['type'], record['name'], record['lastMsg'],
      DateTime.parse(record['lastTime']));

  if (record.containsKey('lastSender')) {
    chat.lastSender = record['lastSender'];
    chat.lastSender = await getUserDisplayName(chat.lastSender!);
  }

  if (chat.type == "individual") {
    chat.displayName = await getUserDisplayName(chat.name);
  } else {
    chat.displayName = chat.name;
  }

  return chat;
}
