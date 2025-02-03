import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/models/user.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';

Future<void> displayLendDialog(BuildContext context, Book book, User user, {String? idToLendTo}) async {
  await showDialog(
    context: context,
    builder: (context) => BookLendDialog(book, user, idToLendTo: idToLendTo),
  );
}

class BookLendDialog extends StatefulWidget {
  final Book book;
  final User user;
  final String? idToLendTo;
  const BookLendDialog(this.book, this.user, {this.idToLendTo, super.key});

  @override
  State<BookLendDialog> createState() => _BookLendDialogState();
}

class _BookLendDialogState extends State<BookLendDialog> {
  Set<int> _daysToReturn = {30};
  // for requests, if you "accept" a request, it just takes you to this page with the request sender's friend id auto selected
  String? _selectedFriendId; // fyi, if its filtered off, it doesnt get deselected, i just think its better that way
  late final VoidCallback _friendsUpdatedListener;
  final TextEditingController _filterFriendsTextController = TextEditingController();
  List<int> _shownList = [];
  bool _sortingAscending = true;
  bool _noFriends = false;

  @override
  void initState() {
    super.initState();
    _selectedFriendId = widget.idToLendTo;
    _friendsUpdatedListener = () {
      if (refreshNotifier.value == homepageIndex) {
        if (friends.isEmpty) {
          _noFriends = true;
        }
        else {
          _noFriends = false;
        }
        // if the selected friend got removed from friends list
        if (_selectedFriendId != null && !(friends.map((item) => item.uid).contains(_selectedFriendId))) {
          _selectedFriendId = null;
        }
        _filter(_filterFriendsTextController.text);
      }
    };
    refreshNotifier.addListener(_friendsUpdatedListener);
    _getUnfilteredShownList();
  }

  @override
  void dispose() {
    refreshNotifier.removeListener(_friendsUpdatedListener);
    _filterFriendsTextController.dispose();
    super.dispose();
  }

  void _tryToLendBook() async {
    if (_selectedFriendId == null) {
      SharedWidgets.displayErrorDialog(context, "You have not selected a friend to lend to");
      return;
    }
    String borrowerId = _selectedFriendId!;
    bool foundFriend = false;
    for (UserModel friend in friends) {
      if (friend.uid == borrowerId) {
        foundFriend = true;
      }
    }
    if (!foundFriend) {
      // dont think this is possible as long as selectedFriendId gets updated correctly, just being safe tho
      SharedWidgets.displayErrorDialog(context, "This user does not exist");
      return;
    }
    DateTime dateLent = DateTime.now().toUtc();
    DateTime dateToReturn = dateLent.add(Duration(days: _daysToReturn.single));
    // could add a SharedWidgets.displayConfirmActionDialog() to confirm the lend action right here, but I decided its not
    // necessary, its just 1 extra button press. If the user screws up they can just unlend right after.
    widget.book.lendBook(dateLent, dateToReturn, borrowerId, widget.user.uid);
    Navigator.pop(context);
    SharedWidgets.displayPositiveFeedbackDialog(context, "Book Lent");
  }

  bool _isFilterTextOneOfTheIndividualWords(List<String> individualWordsToFilter, String filterText) {
    if (individualWordsToFilter.length < 2) {
      // in this case there is only 0 or 1 words detected, which defeats the whole purpose of this function
      return false;
    }
    for (int i = 0; i < individualWordsToFilter.length; i++) {
      if (individualWordsToFilter[i] == filterText) {
        return true;
      }
    }
    return false;
  }

  void _sortShownList() {
    // Fun fact which I didnt know, you gotta make them lowercase or else uppercase C comes before lowercase b for example. Its some ascii value stuff I think,
    // so ig when sorting just trim and make it lowercase always or else freaky stuff will happen.
    _shownList.sort((a, b) => (friends[a].name.trim().toLowerCase()).compareTo(friends[b].name.trim().toLowerCase()));
  }

  void _getUnfilteredShownList() {
    _shownList = Iterable<int>.generate(friends.length).toList();
    _sortShownList(); // TODO ensure this should exist, some sorting, preferable of the key display attribute of a user, which I would guess is username when thats working
  }

  void _flipShownList() {
    _shownList = _shownList.reversed.toList();
  }

  void _filter(String filterText) { // TODO update the filtering whenever user attributes are finalized
    filterText = filterText.toLowerCase().trim();
    if (filterText.isEmpty) {
      // setting shown list with no filters here
      _getUnfilteredShownList();
    } else {
      List<int> newShownList = [];
      List<String> individualWordsToFilter = filterText.split(" ");
      for (int i = 0; i < friends.length; i++) {
        if ((friends[i].uid.toLowerCase()).contains(filterText)
        || (friends[i].email.toLowerCase()).contains(filterText)
        || (friends[i].name.toLowerCase()).contains(filterText)
        || _isFilterTextOneOfTheIndividualWords(individualWordsToFilter, filterText)) {
          newShownList.add(i);
        }
      }
      if (listEquals(newShownList, _shownList)) {
        // optimization to prevent unnecessary rebuilds (if shownList doesn't change, no need to setState)
        return;
      } else {
        _shownList = List.from(newShownList);
        _sortShownList();
        if (!_sortingAscending) {
          _flipShownList();
        }
      }
    }
    setState(() {});
  }

  Widget _displayLendForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Text("Lend Book", style: TextStyle(fontSize: 20, color: Colors.black)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _filterFriendsTextController,
                onChanged: (text) {
                  _filter(text);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Filter by uid, email, username",
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _filter(""); // needed to signal to the filtering that there is no more filter being applied
                      _filterFriendsTextController.clear();
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ),
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
            ),
            IconButton(
              onPressed: () {
                _sortingAscending = !_sortingAscending;
                _flipShownList();
                setState(() {});
              },
              icon: Icon(
                (_sortingAscending) ? Icons.arrow_upward : Icons.arrow_downward,
                size: 30,
                color: Colors.black45,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        (_noFriends)
        ? const Text("You have no friends to lend to", style: TextStyle(fontSize: 14, color: Colors.black))
        : ConstrainedBox(
          // It seems for dynamic sizing, ListView always tries to take maximum size even if its length 1 or whatever it still asks for all
          // the space, so i just make it max 300 height but with logic to make it smaller if shown list is smaller. Seems to work well.
          constraints: BoxConstraints(maxHeight: _shownList.length <= 5 ? _shownList.length * 50 : 300),
          child: ListView.builder(
          itemCount: _shownList.length,
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
            onTap: () {
              setState(() {
                // this logic allows for an "unselecting" if you click on the friend id again
                if (friends[_shownList[index]].uid == _selectedFriendId) {
                  _selectedFriendId = null;
                }
                else {
                  _selectedFriendId = friends[_shownList[index]].uid;
                }
              });
            },
            child: Card(
              margin: const EdgeInsets.all(5),
              color: (_selectedFriendId == friends[_shownList[index]].uid) ? AppColor.acceptGreen : Colors.grey[200],
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.person),
                  ),
                  Flexible( // this is what gives these widgets in the column constraints
                  fit: FlexFit.tight,
                    child: Column(
                      children: [
                        Text(
                          friends[_shownList[index]].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          friends[_shownList[index]].email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ));
          }),
        ),
        const SizedBox(height: 10),
        const Text("Days to return", style: TextStyle(fontSize: 16, color: Colors.black)),
        SegmentedButton<int>(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColor.acceptGreen;
                }
                else {
                  return Colors.grey[200];
                }
              },
            ),
          ),
          showSelectedIcon: false,
          selected: _daysToReturn,
          onSelectionChanged: (Set<int> newSelection) {
            setState(() {
              _daysToReturn = newSelection;
            });
          },
          segments: const <ButtonSegment<int>>[
            ButtonSegment(
              value: 7,
              label: Text("7"),
            ),
            ButtonSegment(
              value: 14,
              label: Text("14"),
            ),
            ButtonSegment(
              value: 30,
              label: Text("30"),
            ),
            ButtonSegment(
              value: 60,
              label: Text("60"),
            ),
            ButtonSegment(
              value: 90,
              label: Text("90"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.cancelRed,
                  padding: const EdgeInsets.all(8),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: () async {
                  _tryToLendBook();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.acceptGreen,
                  padding: const EdgeInsets.all(8),
                ),
                child: const Text(
                  "Flag book as lent",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        )
        
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(25)), // dialog has a border, Material widget doesnt
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 2,
              ),
            ],
          ),
          child: _displayLendForm(),
        ),
      ),
    );
  }
}
