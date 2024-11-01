import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../Widgets/FriendRequests_Widget.dart';
import '../../Widgets/FriendsListView_Widget.dart';
import '../../Widgets/SearchTextFiled_Widget.dart';
import '../Futchers/CustomSnackBar.dart';
import '../Library/homepage.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    setStatus("Online");
    fetchFriends();
  }

  void sendFriendRequest(String receiverId) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      final senderId = currentUser.uid;
      await _firestore.collection('friend_requests').add({
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
      final querySnapshot = await _firestore
          .collection('friend_requests')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in querySnapshot.docs) {
        requests.add(doc.data());
      }
    }
    return requests;
  }

  void respondToFriendRequest(String requestId, bool isAccepted) async {
    final requestRef = _firestore.collection('friend_requests').doc(requestId);
    if (isAccepted) {
      await requestRef.update({'status': 'accepted'});
      final request = await requestRef.get();
      final senderId = request['senderId'];
      final receiverId = request['receiverId'];
      await _firestore
          .collection('friends')
          .doc(senderId)
          .collection('userFriends')
          .add({
        'friendId': receiverId,
        'status': 'accepted',
      });
      await _firestore
          .collection('friends')
          .doc(receiverId)
          .collection('userFriends')
          .add({
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

  void fetchFriends() async {
    FirebaseFirestore fStore = FirebaseFirestore.instance;

    setState(() {
      isLoading = true;
    });
    final userId = _auth.currentUser!.uid;
    final friendsSnapshot = await fStore
        .collection('users')
        .doc(userId)
        .collection('friendRequests')
        .get();
    setState(() {
      friendsList = friendsSnapshot.docs.map((doc) => doc.data()).toList();
      debugPrint("Friend List Is : ${friendsList.length.toString()}");
      debugPrint(userId);
      setState(() {
        isLoading = false;
      });
    });
  }

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
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
      FirebaseFirestore _firestore = FirebaseFirestore.instance;

      setState(() {
        isLoading = true;
      });

      await _firestore
          .collection('users')
          .where("email", isEqualTo: _search.text)
          .get()
          .then((value) {
        setState(() {
          userMap = value.docs[0].data();
          isLoading = false;
        });
        debugPrint(userMap?.values.length.toString());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(
          message: 'This is a custom SnackBar message',
          actionLabel: 'OK',
          icon:Icons.error,
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
        title: const Text("Messenger"),
        automaticallyImplyLeading: false,
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
                        children: [
                          ListTile(
                            onTap: () {
                              String roomId = chatRoomId(
                                  _auth.currentUser!.displayName!,
                                  userMap!["name"]);
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
                              userMap!["name"] ?? "ٔNot Exist",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(userMap!["email"] ?? "Not Exist"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat,
                                      color: Colors.black),
                                  onPressed: () {
                                    String roomId = chatRoomId(
                                        _auth.currentUser!.displayName!,
                                        userMap!["name"]);
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
                                    icon: const Icon(Icons.person_add,
                                        color: Colors.black),
                                    onPressed: () =>
                                        sendFriendRequest(userMap!["uid"])),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Container(),
                SizedBox(height: size.height / 50),
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
                )
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
}
