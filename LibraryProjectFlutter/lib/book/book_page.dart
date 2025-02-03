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
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/book/book_lend_page.dart';
import 'package:library_project/book/custom_added_book_edit.dart';
import 'package:library_project/ui/shared_widgets.dart';

enum _ReadStatus { notRead, currentlyReading, unknown, read }

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
      case ReadingState.read:
        selection = {_ReadStatus.read};
        setState(() {});
        break;
      case ReadingState.notRead:
        selection = {_ReadStatus.notRead};
        setState(() {});
        break;
      case ReadingState.currentlyReading:
        selection = {_ReadStatus.currentlyReading};
        setState(() {});
        break;
      case null:
        selection = {_ReadStatus.unknown};
        break;
    }
    setState(() {});
  }

  void processSelectionOption(_ReadStatus selection) {
    switch (selection) {
      case _ReadStatus.notRead:
        if (widget.book.hasRead != ReadingState.notRead) {
          widget.book.hasRead = ReadingState.notRead;
          widget.book.update();
          setState(() {});
          break;
        }
      case _ReadStatus.read:
        if (widget.book.hasRead != ReadingState.read) {
          widget.book.hasRead = ReadingState.read;
          widget.book.update();
          setState(() {});
          break;
        }
      case _ReadStatus.currentlyReading:
        if (widget.book.hasRead != ReadingState.currentlyReading) {
          widget.book.hasRead = ReadingState.currentlyReading;
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
        await displayLendDialog(context, widget.book, widget.user);
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
            side: BorderSide(
                color: const Color.fromARGB(255, 82, 185, 87), width: 5)),
        backgroundColor: Colors.grey[400],
      ),
      child: Container(
        height: 160,
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_upward,
              size: 48,
              color: const Color.fromARGB(255, 82, 185, 87),
            ),
            const SizedBox(height: 5),
            const Text(
              'Lend',
              style: TextStyle(
                fontSize: 19,
                color: const Color.fromARGB(255, 82, 185, 87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // maybe put this somewhere else idk, I just have it here for simplicity
  Widget _returnBookButton() {
    return Column(
      children: [
        // TODO this ui sucks change this also change id to username or somethign whenver thats done, should be easy func call similar to userExists() function right?
        (widget.book.borrowerId != null)
            ? Text("lent to ${widget.book.borrowerId}")
            : const SizedBox.shrink(),
        ElevatedButton(
          onPressed: () async {
            bool shouldReturn = await SharedWidgets.displayConfirmActionDialog(context, "Do you want to return this book?");
            if (shouldReturn) {
              widget.book.returnBook();
              if (mounted) {
                SharedWidgets.displayPositiveFeedbackDialog(context, "Book Returned");
                setState(() {});
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
          ),
          child: const Text(
            'Return book',
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
        title: const Text("Book Info"),
        centerTitle: true,
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
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 160,
                    width: 150,
                    //left column with status, rating, and condition
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        //display if book is available
                        _displayStatus(),
                        SizedBox(height: 10),
                        const Text(
                          "Rating:",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        //display rating TODO: change to edit rating
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "5",
                              style: TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                            Icon(
                              Icons.star_border, // Icon for the button
                              size: 40,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        const Text(
                          "Condition:",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        //display condition TODO: change to edit condition
                        const Text(
                          "Perfect",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  (widget.book.lentDbKey != null)
                      ? _returnBookButton()
                      : _lendBookButton(),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      bool hasRemoved = await SharedWidgets.displayConfirmActionDialog(context, "Do you want to remove this book from your library?");
                      if (hasRemoved) {
                        widget.book.remove(widget.user.uid);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0),
                          side: BorderSide(
                              color: const Color.fromARGB(255, 202, 35, 23),
                              width: 5)),
                      backgroundColor: Colors.grey[400],
                    ),
                    child: Container(
                      height: 160,
                      width: 50,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Center contents vertically
                        children: [
                          Icon(
                            Icons
                                .delete_outline_outlined, // Icon for the button
                            size: 45,
                            color: const Color.fromARGB(255, 202, 35, 23),
                          ),
                          const SizedBox(
                              height: 5), // Space between icon and text
                          const Text(
                            'Delete', // Text below the icon
                            style: TextStyle(
                              fontSize: 17, // Smaller font size for text
                              color: const Color.fromARGB(255, 202, 35, 23),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  (widget.book.isManualAdded && widget.book.lentDbKey == null)
                      ? ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomAddedBookEdit(
                                  widget.book,
                                  widget.user,
                                ),
                              ),
                            );
                            setState(() {});
                          },
                          child: const Text("Edit manually added book here"),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<_ReadStatus>(
              selected: selection,
              onSelectionChanged: (Set<_ReadStatus> newSelection) {
                selection = newSelection;
                processSelectionOption(newSelection.single);
              },
              segments: const <ButtonSegment<_ReadStatus>>[
                ButtonSegment(
                  icon: Icon(Icons.bookmark_remove),
                  value: _ReadStatus.notRead,
                  label: Text("Not read"),
                ),
                ButtonSegment(
                  icon: Icon(Icons.auto_stories),
                  value: _ReadStatus.currentlyReading,
                  label: Text("Currently Reading"),
                ),
                ButtonSegment(
                  icon: Icon(Icons.book),
                  value: _ReadStatus.read,
                  label: Text("Read"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
