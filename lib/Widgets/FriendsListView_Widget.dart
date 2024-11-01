import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('friends')
        .doc(widget.userId)
        .get();

    setState(() {
      friendIds = snapshot.data()?['friendIds'] ?? [];
      isLoading = false;
    });
  }

  Future<void> _removeFriend(String friendId) async {
    try {
      setState(() {
        friendIds.remove(friendId);
      });

      await FirebaseFirestore.instance
          .collection('friends')
          .doc(widget.userId)
          .update({
        'friendIds': friendIds,
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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();
      if (userDoc.exists) {
        friendsDetails.add({
          'id': friendId,
          'name': userDoc['name'],
          'email': userDoc['email'],
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
