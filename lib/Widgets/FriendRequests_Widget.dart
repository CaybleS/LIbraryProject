import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestsWidget extends StatefulWidget {
  final String userId;

  const FriendRequestsWidget({super.key, required this.userId});

  @override
  _FriendRequestsWidgetState createState() => _FriendRequestsWidgetState();
}

class _FriendRequestsWidgetState extends State<FriendRequestsWidget> {
  int friendRequestCount = 0;
  List<String> friendRequests = [];

  Future<void> _updateFriendRequestStatus(String senderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: widget.userId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'status': newStatus});
        }
      });
      if (newStatus == 'accepted') {
        await _addFriend(senderId, widget.userId);
        await _addFriend(widget.userId, senderId);
      }
      fetchFriendRequests();
    } catch (error) {
      print("Error updating friend request status: $error");
    }
  }

  Future<void> _addFriend(String userId, String friendId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friends')
          .doc(userId)
          .set({
        'friendIds': FieldValue.arrayUnion([friendId]),
      }, SetOptions(merge: true));
    } catch (error) {
      print("Error adding friend: $error");
    }
  }

  Future<void> fetchFriendRequests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('receiverId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending') //
          .get();

      //
      List<String> requests = snapshot.docs.map((doc) => doc['senderId'] as String).toList();

      setState(() {
        friendRequests = requests;
        friendRequestCount = requests.length;
      });
    } catch (error) {
      print("Error fetching friend requests: $error");
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
