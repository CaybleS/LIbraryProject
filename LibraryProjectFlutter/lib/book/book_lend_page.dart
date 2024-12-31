// TODO that this will need to be changed, it must store the friendId but should display username or something
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/core/friends_page.dart';
import 'package:library_project/misc_util/get_current_time.dart';
import 'package:library_project/ui/shared_widgets.dart';

class BookLendPage extends StatefulWidget {
  final Book book;
  final User user;
  const BookLendPage(this.book, this.user, {super.key});

  @override
  State<BookLendPage> createState() => _BookLendPageState();
}

class _BookLendPageState extends State<BookLendPage> {
  int _daysToReturn = 30;
  List<Friend> _friends = [];
  bool _friendsListLoaded = false;
  bool _invalidFriendIdError = false;
  bool _noTextInputError = false;
  String? _selectedFriendId;

  @override
  void initState() {
    super.initState();
    _getFriendsList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getFriendsList() async {
    _friends = await getFriends(widget.user);
    _friendsListLoaded = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _resetErrors() {
    // I don't even know where to call this but its here, so yeah. Don't even know if its needed tbh, why the crud did i make this i dont rember
    _invalidFriendIdError = false;
    _noTextInputError = false;
  }

  Widget _printError() {
    if (_invalidFriendIdError) {
      return const Text("Invalid friend code!");
    }
    if (_noTextInputError) {
      return const Text("Please enter a friend id");
    }
    return const SizedBox.shrink();
  }

  Widget _displayLendForm() {
    return Column(
      children: [
        const Text(
          "Friend to lend to:",
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(
          height: 5,
        ),
        SizedBox(
          height: 300,
          child: ListView.builder(
          itemCount: _friends.length,
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
            onTap: () {
              setState(() {
                _selectedFriendId = _friends[index].friendId;
              });
            },
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(_friends[index].friendId), // TODO update this with real username when thats added
                subtitle: Text('ID: ${_friends[index].friendId}'),
                tileColor: (_selectedFriendId == _friends[index].friendId) ? Colors.green : null,
              ),
            ),
            );
          }
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        _printError(),
        const Text("Days to return"),
        DropdownButton<int>(
          value: _daysToReturn,
          onChanged: (newValue) {
            setState(() {
              _daysToReturn = newValue!;
            });
          },
          items: <int>[7, 14, 30, 60, 90].map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value days'),
            );
          }).toList(),
        ),
        // I HAVE NO IDEA IF DATE PICKER OR INT INPUT OR THIS DROPDOWNMENU IS BEST I JUST DONT KNOW. Don't really like any of them enough to choose.
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () async {
            if (_selectedFriendId == null) {
              _noTextInputError = true;
              setState(() {});
              return;
            }
            String borrowerId = _selectedFriendId!;
            bool foundFriend = false;
            for (Friend friend in _friends) {
              if (friend.friendId == borrowerId) {
                foundFriend = true;
              }
            }
            if (!foundFriend) {
              _invalidFriendIdError = true;
              setState(() {});
              return;
            }
            DateTime dateLent = await getCurrentTimeUTC();
            DateTime dateToReturn = dateLent.add(Duration(days: _daysToReturn));
            widget.book.lendBook(dateLent, dateToReturn, borrowerId, widget.user.uid);
            if (mounted) {
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
          ),
          child: const Text(
            "Flag book as lent",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[400],
      body: Container(
        padding: const EdgeInsets.all(10),
        child: _friendsListLoaded
            ? _displayLendForm()
            : SharedWidgets.displayCircularProgressIndicator(),
      ),
    );
  }
}
