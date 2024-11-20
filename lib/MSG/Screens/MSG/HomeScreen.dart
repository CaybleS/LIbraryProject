import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/LIB/homepage.dart';
import 'package:library_project/MSG/Widgets/ShowHistoryChat_Widget.dart';
import '../../Core/Models/Chat.dart';
import '../../Widgets/FriendRequests_Widget.dart';
import '../../Widgets/FriendsListView_Widget.dart';
import '../../Widgets/SearchTextFiled_Widget.dart';
import '../Futchers/CustomSnackBar.dart';
import 'ChatRoomScreen.dart';
import 'GroupChatScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? userMap;
  List<Map<String, dynamic>> friendsList = [];
  bool isLoading = false;
  final TextEditingController _search = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    setStatus("Online");
    fetchFriends().then((friends) {
      setState(() {
        friendsList = friends;
      });
    });
  }

  void sendFriendRequest(String receiverId) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      final senderId = currentUser.uid;
      await _database.ref().child('friend_requests').push().set({
        'senderId': senderId,
        'receiverId': receiverId,
        'status': 'pending',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request sent")),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final currentUser = _auth.currentUser;
    final List<Map<String, dynamic>> requests = [];

    if (currentUser != null) {
      final snapshot = await _database
          .ref()
          .child('friend_requests')
          .orderByChild('receiverId')
          .equalTo(currentUser.uid)
          .once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
            snapshot.snapshot.value as Map<String, dynamic>);
        data.forEach((key, value) {
          if (value['status'] == 'pending') {
            requests.add(Map<String, dynamic>.from(value));
          }
        });
      }
    }
    return requests;
  }

  void respondToFriendRequest(String requestId, bool isAccepted) async {
    final requestRef =
        _database.ref().child('friend_requests').child(requestId);
    if (isAccepted) {
      await requestRef.update({'status': 'accepted'});
      final snapshot = await requestRef.once();
      final request = Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<String, dynamic>);
      final senderId = request['senderId'];
      final receiverId = request['receiverId'];
      await _database.ref().child('friends').child(senderId).push().set({
        'friendId': receiverId,
        'status': 'accepted',
      });
      await _database.ref().child('friends').child(receiverId).push().set({
        'friendId': senderId,
        'status': 'accepted',
      });

    } else {
      await requestRef.update({'status': 'rejected'});
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(isAccepted
              ? "Friend request accepted"
              : "Friend request rejected")),
    );
  }


  Future<List<Map<String, dynamic>>> fetchFriends() async {
    final currentUser = _auth.currentUser;
    List<Map<String, dynamic>> friends = [];

    if (currentUser != null) {
      final snapshot = await _database
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child("friendIds")
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final friendIds = data.values.map((value) => value.toString()).toList();

        final usersSnapshot = await _database.ref().child('users').get();
        if (usersSnapshot.exists) {
          final allUsers =
              Map<String, dynamic>.from(usersSnapshot.value as Map);
          final filteredFriends = allUsers.entries.where((userEntry) {
            return friendIds.contains(userEntry.key);
          }).map((entry) {
            final userData = Map<String, dynamic>.from(entry.value as Map);
            return {
              'id': friendIds,
              'name': userData['name'],
              'email': userData['email'],
            };
          }).toList();
          setState(() {
            friends = filteredFriends;
          });
        }
      }
    }
    return friends;
  }

  void setStatus(String status) async {
    await _database.ref().child('users').child(_auth.currentUser!.uid).update({
      "status": status,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // online
      setStatus("Online");
    } else {
      // offline
      setStatus("Offline");
    }
  }

  String chatRoomId(String userOne, String userTwo) {
    return userOne.compareTo(userTwo) < 0
        ? "$userOne - $userTwo"
        : "$userTwo - $userOne";
  }

  void onSearch() async {
    if (_search.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      final snapshot = await _database
          .ref()
          .child('users')
          .orderByChild("name")
          .equalTo(_search.text)
          .once();
      if (snapshot.snapshot.value != null) {
        setState(() {
          userMap = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.build(
            message: 'User Not Found.',
            actionLabel: 'OK',
            icon: Icons.error,
            isError: true,
          ),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(
          message: 'This is a custom SnackBar message',
          actionLabel: 'OK',
          icon: Icons.error,
          isError: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Messenger"),
        actions: [
          IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HomePage(_auth.currentUser!))),
              icon: const Icon(Icons.close)),
          FriendRequestsWidget(
            userId: _auth.currentUser!.uid,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Container(
                alignment: Alignment.center,
                width: size.width / 20,
                height: size.height / 20,
                child: const CircularProgressIndicator(),
              ),
            )
          : Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  height: size.height / 30,
                  width: size.width,
                  child: Container(
                    alignment: Alignment.center,
                    width: size.width / 1.2,
                    height: size.height / 14,
                  ),
                ),
                SearchTextFieldWidget(
                    searchController: _search, onSearch: onSearch),
                SizedBox(
                  height: size.height / 50,
                ),
                userMap != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            onTap: () {
                              String roomId = chatRoomId(
                                  _auth.currentUser!.displayName!,
                                  userMap!.values.first["name"]);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ChatRoomScreen(
                                        chatRoomId: roomId,
                                        userMap: userMap!,
                                      )));
                            },
                            leading: const Icon(
                              Icons.account_box,
                              color: Colors.black,
                            ),
                            title: Text(
                              userMap!.values.isNotEmpty
                                  ? (userMap!.values.first["name"])
                                  : "ٔNot Exist",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                                userMap!.values.first["email"] ?? "Not Exist"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat,
                                      color: Colors.black),
                                  onPressed: () {
                                    String roomId = chatRoomId(
                                        _auth.currentUser!.displayName!,
                                        userMap!.values.first["name"]);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChatRoomScreen(
                                          chatRoomId: roomId,
                                          userMap: userMap!,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  onPressed: () {
                                    sendFriendRequest(
                                        userMap!.values.first["uid"]);
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.black,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      )
                    : Container(),
                const Divider(
                  color: Colors.grey,
                  thickness: 2,
                  indent: 8,
                  endIndent: 16,
                ),
                FriendsListWidget(
                  userId: _auth.currentUser!.uid,
                  onFriendTap: (friendId, friendName) {
                    String roomId = chatRoomId(
                      _auth.currentUser!.displayName!,
                      friendName,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          chatRoomId: roomId,
                          userMap: {'name': friendName, 'uid': friendId},
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                const Divider(
                  color: Colors.grey,
                  thickness: 2,
                  indent: 8,
                  endIndent: 16,
                ),
                const SizedBox(
                  height: 15,
                ),
                Expanded(
                    child: ShowHistoryChatWidget(
                        userId: _auth.currentUser!.uid,
                        database: _database.ref()))
              ],
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.group),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GroupChatScreen()),
        ),
      ),
    );
  }

  Widget buildFriendList() {
    return Expanded(
      child: ListView.builder(
        itemCount: friendsList.length,
        itemBuilder: (context, index) {
          final friend = friendsList[index];
          return ListTile(
            title: Text("User Name: ${friend['name']}"),
            subtitle: Text("Email: ${friend['email']}"),
            trailing: IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                String roomId = chatRoomId(
                  _auth.currentUser!.displayName!,
                  friend['name'],
                );
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    chatRoomId: roomId,
                    userMap: {
                      'uid': friend['id'],
                    },
                  ),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}
