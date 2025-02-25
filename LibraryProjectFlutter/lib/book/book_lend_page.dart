import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
// note that we dont check the receiver's library to see if they already own the book before lending it to them; we could do this
// but it could use up database reads and add a slight delay between the "lend book" button click and the actual lending
// so overall I decided its not worth.

Future<void> displayLendDialog(BuildContext context, Book book, User user, {String? idToLendTo}) async {
  await showDialog(
    context: context,
    builder: (context) => BookLendDialog(book, user, idToLendTo: idToLendTo),
  );
}

void tryToLendBook(String? selectedFriendId, BuildContext context, User user, Book book, {int daysToReturn = 30}) {
    if (selectedFriendId == null) {
      SharedWidgets.displayErrorDialog(context, "You have not selected a friend to lend to");
      return;
    }
    String borrowerId = selectedFriendId;
    bool foundFriend = false;
    for (String friend in friendIDs) {
      if (friend == borrowerId) {
        foundFriend = true;
        book.userLent = userIdToUserModel[friend]!.name;
      }
    }
    if (!foundFriend) {
      // dont think this is possible as long as selectedFriendId gets updated correctly, just being safe tho
      SharedWidgets.displayErrorDialog(context, "This user does not exist");
      return;
    }
    DateTime dateLent = DateTime.now().toUtc();
    DateTime dateToReturn = dateLent.add(Duration(days: daysToReturn));
    // could add a SharedWidgets.displayConfirmActionDialog() to confirm the lend action right here, but I decided its not
    // necessary, its just 1 extra button press. If the user screws up they can just unlend right after.
    book.lendBook(dateLent, dateToReturn, borrowerId, user.uid);
    Navigator.pop(context);
    SharedWidgets.displayPositiveFeedbackDialog(context, "Book Lent");
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
      if (friendIDs.isEmpty) {
        _noFriends = true;
      }
      else {
        _noFriends = false;
      }
      // if the selected friend got removed from friends list
      if (_selectedFriendId != null && !(friendIDs.map((item) => item).contains(_selectedFriendId))) {
        _selectedFriendId = null;
      }
      _filter(_filterFriendsTextController.text);
    };
    pageDataUpdatedNotifier.addListener(_friendsUpdatedListener);
    _getUnfilteredShownList();
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_friendsUpdatedListener);
    _filterFriendsTextController.dispose();
    super.dispose();
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
    _shownList.sort((a, b) => (userIdToUserModel[friendIDs[a]]!.name.trim().toLowerCase()).compareTo(userIdToUserModel[friendIDs[b]]!.name.trim().toLowerCase()));
  }

  void _getUnfilteredShownList() {
    _shownList = Iterable<int>.generate(friendIDs.length).toList();
    _sortShownList();
    if (!_sortingAscending) {
      _flipShownList();
    }
  }

  void _flipShownList() {
    _shownList = _shownList.reversed.toList();
  }

  void _filter(String filterText) {
    filterText = filterText.toLowerCase().trim();
    if (filterText.isEmpty) {
      // setting shown list with no filters here
      _getUnfilteredShownList();
    } else {
      List<int> newShownList = [];
      List<String> individualWordsToFilter = filterText.split(" ");
      for (int i = 0; i < friendIDs.length; i++) {
        if ((userIdToUserModel[friendIDs[i]]!.name.toLowerCase()).contains(filterText)
        || (userIdToUserModel[friendIDs[i]]!.username.toLowerCase()).contains(filterText)
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
        Row( // I'll say that in general a lot of the sizes here are fine tuned to make the filter controller in the center so be careful when editing
          children: [
            const SizedBox(width: 43),
            Expanded(
              child: TextField(
                controller: _filterFriendsTextController,
                onChanged: (text) {
                  _filter(text);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Filter by name or username",
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
                (_sortingAscending) ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
          // the space, so i just make it max 330 height but with logic to make it smaller if shown list is smaller. Seems to work well.
          constraints: BoxConstraints(maxHeight: _shownList.length <= 5 ? _shownList.length * 55 : 330),
          child: ListView.builder(
          itemCount: _shownList.length,
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
            onTap: () {
              setState(() {
                // this logic allows for an "unselecting" if you click on the friend id again
                if (friendIDs[_shownList[index]] == _selectedFriendId) {
                  _selectedFriendId = null;
                }
                else {
                  _selectedFriendId = friendIDs[_shownList[index]];
                }
              });
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              color: (_selectedFriendId == friendIDs[_shownList[index]]) ? AppColor.acceptGreen : Colors.grey[300],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(1, 0, 5, 0),
                      child: Icon(Icons.person),
                    ),
                    Expanded( // this is what gives these widgets in the column constraints
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            userIdToUserModel[friendIDs[_shownList[index]]]!.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), // TODO look into this weight stuff. The concern is universality mainly
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userIdToUserModel[friendIDs[_shownList[index]]]!.username,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 30),
                  ],
                ),
              ),
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
                  return Colors.grey[300];
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
            Expanded(
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
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  tryToLendBook(_selectedFriendId, context, widget.user, widget.book, daysToReturn: _daysToReturn.single);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.acceptGreen,
                  padding: const EdgeInsets.all(8),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Flag as lent",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
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
