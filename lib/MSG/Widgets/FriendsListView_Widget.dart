import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class FriendsListWidget extends StatefulWidget {
  final String userId;
  final Function(String friendId, String friendName) onFriendTap;
  const FriendsListWidget({super.key, required this.userId, required this.onFriendTap});

  @override
  State<FriendsListWidget> createState() => _FriendsListWidgetState();
}

class _FriendsListWidgetState extends State<FriendsListWidget> {
  List<dynamic> friendIds = [];
  bool isLoading = true;
  final dbReference = FirebaseDatabase.instance.ref();

  @override
  void initState(){
    super.initState();
    _loadFriends();

  }

  Future<void> _loadFriends() async {
    final snapshot = await dbReference.child('friends/${widget.userId}').get();
    if(snapshot.exists && snapshot.value is Map){
      Map<dynamic , dynamic> data = snapshot.value as Map<dynamic , dynamic>;
      setState(() {
        friendIds = data['friendIds'] != null
            ? (data["friendIds"] is List
        ?List<String>.from(data["friendIds"])
        :List<String>.from((data["friendIds"] as Map).values))
        :[];
        isLoading = false;
      });
    }else{
      setState(() {
        friendIds = [];
        isLoading = false;
      });
    }

  }

  Future<void> _removeFriend(String friendId) async {
    try {
      setState(() {
        friendIds.remove(friendId);
      });

      await dbReference.child('friends/${widget.userId}').update({
        'friendIds':friendId,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing friend: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getFriendsDetails( List<dynamic> friendIds) async {
    List<Map<String, dynamic>> friendsDetails = [];
    for (String friendId in friendIds) {
      final userSnapshot = await dbReference.child('users/$friendId').get();
      if (userSnapshot.exists) {
        Map<dynamic , dynamic> userData = userSnapshot.value as Map<dynamic , dynamic>;
        friendsDetails.add({
          'id': friendId,
          'name': userData['name'],
          'email': userData['email'],
        });
      }
    }
    return friendsDetails;
  }



  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }


    return SingleChildScrollView(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getFriendsDetails(friendIds),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> friendsSnapshot) {
          if (friendsSnapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (friendsSnapshot.hasError) {
            return Text('Error: ${friendsSnapshot.error}');
          }

          List<Map<String, dynamic>> friendsDetails =
              friendsSnapshot.data ?? [];

          return ListView.builder(
            itemCount: friendsDetails.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () {
                  widget.onFriendTap(
                    friendsDetails[index]['id'],
                    friendsDetails[index]['name'],
                  );
                },
                leading: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.green,
                ),
                title: Text(
                  friendsDetails[index]['name'],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(friendsDetails[index]['email']),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_from_queue_rounded,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    _removeFriend(friendsDetails[index]['id']);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
