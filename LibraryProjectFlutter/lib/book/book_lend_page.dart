// TODO that this will need to be changed, it must store the friendId but should display username or something
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import '../Social/friends_page.dart';
import 'package:library_project/misc_util/misc_helper_functions.dart';

class BookLendPage extends StatefulWidget {
  final Book book;
  final User user;
  final List<Friend> friends;
  const BookLendPage(this.book, this.user, this.friends, {super.key});

  @override
  State<BookLendPage> createState() => _BookLendPageState();
}

class _BookLendPageState extends State<BookLendPage> {
  int _daysToReturn = 30;
  bool _invalidFriendIdError = false;
  bool _noTextInputError = false;
  String? _selectedFriendId;

  void _resetErrors() {
    // its not used yet but should probably be called for the input validation stuff to verify each input independently
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
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Friend to lend to:",
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(
          height: 5,
        ),
        Flexible(
          child: ListView.builder(
          itemCount: widget.friends.length, // TODO should this list be sorted by friend username, alphabetically. I think so imo.
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
            onTap: () {
              setState(() {
                _selectedFriendId = widget.friends[index].friendId;
              });
            },
            child: Card(
              margin: const EdgeInsets.all(5),
              color: (_selectedFriendId == widget.friends[index].friendId) ? Colors.green : null,
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Icon(Icons.person),
                  ),
                  Column(
                    children: [
                      Text(widget.friends[index].friendId), // TODO update this with real username when thats added I'd say
                      Text('ID: ${widget.friends[index].friendId}'),
                    ],
                  ),
                ],
              )
            ));
          }),
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
            for (Friend friend in widget.friends) {
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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: _displayLendForm(),
      ),
    );
  }
}
