import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../Core/Models/Chat.dart';
import '../Screens/MSG/ChatRoomScreen.dart';

class ShowHistoryChatWidget extends StatelessWidget {
  final String userId;
  final DatabaseReference database;
  ShowHistoryChatWidget({super.key, required this.userId, required this.database});

  final List<String> friendIds = [];
  final List<Map<String , dynamic>> friendSnapshot = [];

  String chatRoomId(String userOne, String userTwo) {
    return userOne.compareTo(userTwo) < 0
        ? "$userOne - $userTwo"
        : "$userTwo - $userOne";
  }


  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final snapshot = await database.child('friend_requests').get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> friendRequests = data.entries.map((entry) {
        return {
          "requestId": entry.key,
          ...Map<String, dynamic>.from(entry.value),
        };
      }).toList();

      for (var request in friendRequests) {
        if (request["receiverId"] == userId && request["status"] == "accepted") {
          friendIds.add(request["senderId"]);
        }
      }

      for (var fx in friendIds) {
        final userSnapshot = await database.child("users/${fx.toString()}").get();
        if (userSnapshot.exists) {
          // Check if the value can be cast as Map<String, dynamic>
          Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map<Object? , Object?>);
          friendSnapshot.add(userData);
        }
      }

      return friendSnapshot;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: getChatHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No additional chat history available"));
          }

          // Displaying the data in a ListView
          List<Map<String, dynamic>> chatHistory = snapshot.data!;
          return ListView.builder(
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                final chat = chatHistory[index];
                return ListTile(
                  title: Text("User Name: ${chat['name']}"),
                  subtitle: Text("Email: ${chat['email']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () {
                      String roomId = chatRoomId(
                       userId,
                        chat['name'],
                      );
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          chatRoomId: roomId,
                          userMap: {

                            'uid': chat['uid'],
                            "name":chat["name"],
                          },
                        ),
                      ));
                    },
                  ),
                );

              }
          );
        });
  }

}
