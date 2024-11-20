import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class FriendRequestsWidget extends StatefulWidget {
  final String userId;

  const FriendRequestsWidget({super.key, required this.userId});

  @override
  _FriendRequestsWidgetState createState() => _FriendRequestsWidgetState();
}

class _FriendRequestsWidgetState extends State<FriendRequestsWidget> {
  int friendRequestCount = 0;
  List<String> friendRequests = [];
  final DatabaseReference _database = FirebaseDatabase.instance.ref();


  Future<void> _updateFriendRequestStatus(String senderId, String newStatus) async {
    try {
      final snapshot = await _database
        .child('friend_requests')
        .orderByChild('senderId')
        .equalTo(senderId)
        .once();
      for(var child in snapshot.snapshot.children){
        if(child.child('receiverId').value == widget.userId){
          await child.ref.update({'status':newStatus});
        }
      }
      if (newStatus == 'accepted') {
        await _addFriend(senderId, widget.userId);
        await _addFriend(widget.userId, senderId);
      }
      fetchFriendRequests();
    } catch (error) {
      debugPrint("Error updating friend request status: $error");
    }
  }

  Future<void> _addFriend(String userId, String friendId) async {

    try {
      final ref = _database.child('friends').child(userId).child('friendIds');
      await ref.push().set(friendId);
    } catch (error) {
      debugPrint("Error adding friend: $error");
    }
  }

  Future<void> fetchFriendRequests() async {
    try{
      final snapshot = await _database
        .child('friend_requests')
        .orderByChild('receiverId')
        .equalTo(widget.userId)
        .once();
      List<String> requests = [];

      for(var child in snapshot.snapshot.children){
        if(child.child("status").value == 'pending'){
          requests.add(child.child('senderId').value as String);
        }

      }
      setState(() {
        friendRequests = requests;
        friendRequestCount = requests.length;
      });
    } catch (error) {
      debugPrint("Error fetching friend requests: $error");
    }
  }







  @override
  void initState() {
    super.initState();
    fetchFriendRequests();
  }

  void showFriendRequestsModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Friend Requests'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: friendRequests.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(friendRequests[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          _updateFriendRequestStatus(friendRequests[index], 'accepted');
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _updateFriendRequestStatus(friendRequests[index], 'rejected');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.person_add),
          onPressed: showFriendRequestsModal,
        ),
        if (friendRequestCount > 0)
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                '$friendRequestCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
