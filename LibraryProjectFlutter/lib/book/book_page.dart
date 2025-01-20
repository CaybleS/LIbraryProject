// TODO this page. Remove these comments when done
// what can be on it?
// 1.) book condition slider, some segmented button or something with some middle nullable default value
// 2.) test box with public book notes - seems good to do, maybe call it "public comments" or something idk
// 3.) text box with private book notes - idk about this one but most of my uncertainty is due to concerns about the UI being complex and hard to understand with 2 text boxes
// 4.) review/rating - could be some rating segmented button with middle nullable default value
// 5.) read status - whether user has read the book - in my head its a 3 option segmented button with nullable default value - seems very good to do imo
// 6.) who the book is lent to, obviously. Also for manually added books, button to go to a page to edit it (only if its not lent tho),
// and a button to remove books, and a button to lend books
// 7.) also book cover, title, author, description, and status (whether its lent or available)
// 8.) Note that borrowed_book_page and add_book/search/book_details_screen will have similar layout to this page IMO, but with much of these details missing I'd say
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/book/book_lend_page.dart';
import 'package:library_project/book/custom_added_book_edit.dart';

enum _ReadStatus {hasNotRead, unknown, hasRead}

class BookPage extends StatefulWidget {
  final Book book;
  final User user;
  const BookPage(this.book, this.user, {super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  Set<_ReadStatus> selection = <_ReadStatus>{_ReadStatus.unknown};

  @override
  void initState() {
    super.initState();
    switch (widget.book.hasRead) {
      case true:
        selection = {_ReadStatus.hasRead};
        setState(() {});
        break;
      case false:
        selection = {_ReadStatus.hasNotRead};
        setState(() {});
        break;
      case null:
        break; // since the default selection is unknown, we dont need to do anything
    }

  }

  void processSelectionOption(_ReadStatus selection) {
    switch (selection) {
      case _ReadStatus.hasNotRead:
        if (widget.book.hasRead != false) {
          widget.book.hasRead = false;
          widget.book.update();
          setState(() {});
          break;
        }
      case _ReadStatus.hasRead:
        if (widget.book.hasRead != true) {
          widget.book.hasRead = true;
          widget.book.update();
          setState(() {});
          break;
        }
      case _ReadStatus.unknown:
        if (widget.book.hasRead != null) {
          widget.book.hasRead = null;
          widget.book.update();
          setState(() {});
          break;
        }
    }
  }

  Widget _displayStatus() {
    String availableTxt;
    Color availableTxtColor;

    if (widget.book.lentDbKey != null) {
      availableTxt = "Lent";
      availableTxtColor = Colors.red;
    } else {
      availableTxt = "Available";
      availableTxtColor = const Color(0xFF43A047);
    }

    return Text(
      availableTxt,
      style: TextStyle(fontSize: 22, color: availableTxtColor),
    );
  }

  Widget _lendBookButton() {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => BookLendPage(widget.book, widget.user)));
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
      ),
      child: const Text('Lend book',
        style: TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }

  // maybe put this somewhere else idk, I just have it here for simplicity
  Widget _returnBookButton() {
    return Column(
      children: [
         // TODO this ui sucks change this also change id to username or somethign whenver thats done, should be easy func call similar to userExists() function right?
        (widget.book.borrowerId != null) ? Text("lent to ${widget.book.borrowerId}") : const SizedBox.shrink(),
        ElevatedButton(
          onPressed: () async {
            widget.book.returnBook();
            setState(() {});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
          ),
          child: const Text('Return book',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ],
    );
  }

 Future<void> _displayConfirmRemoveDialog(Book bookToRemove) async {
    String? retVal = await showDialog(
    context: context,
    builder: (context) =>
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(15),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Are you sure you want to remove this book from your library?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("No!", style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        bookToRemove.remove();
                        // if the book is removed I need to pop the dialog and then pop again so this is how I make this happen
                        // for some reason just having 2 pops here wouldnt work when I added persistent bottombar but this does
                        Navigator.pop(context, "removed"); // signaling to the outside of the dialog to pop from the page it was called from
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Yes!", style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
    if (retVal != null && mounted) {
      Navigator.pop(context);
    }
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
        child: Column(
          children: [
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 220,
                    width: 150,
                    child: AspectRatio(
                      aspectRatio: 0.7,
                      child: widget.book.getCoverImage(),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Flexible( 
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.book.title ?? "No title found",
                            style: const TextStyle(fontSize: 20),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            widget.book.author ?? "No author found",
                            style: const TextStyle(fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Text(
                              widget.book.description ?? "No description found",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text("Status:", style: TextStyle(fontSize: 22)),
            _displayStatus(),
            const SizedBox(height: 10),
            (widget.book.lentDbKey != null) ? _returnBookButton() : _lendBookButton(),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await _displayConfirmRemoveDialog(widget.book);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 202, 35, 23)),
              child: const Text("Remove book from library", style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
            (widget.book.isManualAdded && widget.book.lentDbKey == null) // book needs to be manually added AND not lent out, to be able to edit title/author stuff
            ? ElevatedButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => CustomAddedBookEdit(widget.book, widget.user)));
                  setState(() {});
                },
                child: const Text("edit manually added book here"),
              )
            : const SizedBox.shrink(),
            const SizedBox(height: 10),
            SegmentedButton<_ReadStatus>(
              selected: selection,
              onSelectionChanged: (Set<_ReadStatus> newSelection) {
                selection = newSelection;
                processSelectionOption(newSelection.single);
              },
              segments: const <ButtonSegment<_ReadStatus>> [
                ButtonSegment(
                  icon: Icon(Icons.bookmark_remove),
                  value: _ReadStatus.hasNotRead,
                  label: Text("Has no read"),
                ),
                ButtonSegment(
                  icon: Icon(Icons.question_mark),
                  value: _ReadStatus.unknown,
                  label: Text("default"),
                ),
                ButtonSegment(
                  icon: Icon(Icons.book),
                  value: _ReadStatus.hasRead,
                  label: Text("Has read"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}