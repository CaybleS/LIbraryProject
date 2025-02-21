// TODO this page. Remove these comments when done
// what can be on it?
// 3.) text box with private book notes - idk about this one but most of my uncertainty is due to concerns about the UI being complex and hard to understand with 2 text boxes
// 1.) Note that borrowed_book_page and add_book/search/book_details_screen will have similar layout to this page IMO, but with much of these details missing I'd say
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
  String? _selectedCondition = "-";
  String? _selectedRating = "-";
  @override
  void initState() {
    super.initState();
    _selectedRating = widget.book.rating;
    _selectedRating ??= "-";
    _selectedCondition = widget.book.bookCondition;
    _selectedCondition ??= "-";
    switch (widget.book.hasRead) {
      case "rd":
        selection = {_ReadStatus.read};
        setState(() {});
        break;
      case "nr":
        selection = {_ReadStatus.notRead};
        setState(() {});
        break;
      case "cr":
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
        if (widget.book.hasRead != "nr") {
          widget.book.hasRead = "nr";
          widget.book.update();
          setState(() {});
          break;
        }
      case _ReadStatus.read:
        if (widget.book.hasRead != "rd") {
          widget.book.hasRead = "rd";
          widget.book.update();
          setState(() {});
          break;
        }
      case _ReadStatus.currentlyReading:
        if (widget.book.hasRead != "cr") {
          widget.book.hasRead = "cr";
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
        ),
        backgroundColor: const Color.fromARGB(255, 33, 150, 248),
      ),
      child: const SizedBox(
        height: 160,
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_upward,
              size: 48,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            SizedBox(height: 5),
            Text(
              'Lend',
              style:
                  TextStyle(fontSize: 19, color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ],
        ),
      ),
    );
  }

  // maybe put this somewhere else idk, I just have it here for simplicity
  Widget _returnBookButton() {
    return ElevatedButton(
      onPressed: () async {
        bool shouldReturn = await SharedWidgets.displayConfirmActionDialog(
            context, "Do you want to return this book?");
        if (shouldReturn) {
          widget.book.returnBook();
          if (mounted) {
            SharedWidgets.displayPositiveFeedbackDialog(
                context, "Book Returned");
            setState(() {});
          }
        }
      },
      style: ElevatedButton.styleFrom(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(0.0),
        ),
        backgroundColor: const Color.fromARGB(255, 33, 150, 248),
      ),
      child: const SizedBox(
        height: 160,
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_downward,
              size: 48,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            SizedBox(height: 5),
            Text(
              'Return',
              style:
                  TextStyle(fontSize: 16, color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ],
        ),
      ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
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
                    height: 200,
                    width: 150,
                    //left column with status, rating, and condition
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        //display if book is available
                        _displayStatus(),
                        SizedBox(height: 5),
                        const Text(
                          "Rating:",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButton<String?>(
                              value: _selectedRating,
                              iconSize: 0.0,
                              items: ["-", "1", "2", "3", "4", "5"]
                                  .map((rating) => DropdownMenuItem<String?>(
                                        value: rating,
                                        child: Text(
                                          rating,
                                          style: const TextStyle(fontSize: 30),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRating = value;
                                    widget.book.rating =
                                        value;
                                    widget.book.update();
                                  });
                                }
                              },
                            ),
                            //_displayRating(),
                            const Padding(
                              padding: EdgeInsets.only(top: 3.0),
                              child: Icon(
                                Icons.star_border,
                                size: 40,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        //SizedBox(height: 10),
                        const Text(
                          "Condition:",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        
                        DropdownButton<String?>(
                          value: _selectedCondition,
                          isExpanded: true,
                          iconSize: 0.0,
                          items: [
                            "-",
                            "Perfect",
                            "Good",
                            "Poor",
                            "Damaged",
                            "Lost"
                          ]
                              .map((condition) => DropdownMenuItem<String?>(
                                    value: condition,
                                    alignment: AlignmentDirectional.center,
                                    child: Text(
                                      condition,
                                      style: const TextStyle(fontSize: 25),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCondition = value;
                                widget.book.bookCondition =
                                    value;
                                widget.book.update();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Row(
                        children: [
                          (widget.book.lentDbKey != null)
                              ? _returnBookButton()
                              : _lendBookButton(),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              bool hasRemoved = await SharedWidgets
                                  .displayConfirmActionDialog(context,
                                      "Do you want to remove this book from your library?");
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
                              ),
                              backgroundColor:
                                  const Color.fromARGB(255, 202, 35, 23),
                            ),
                            child: const SizedBox(
                              height: 160,
                              width: 50,
                              child: Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 45,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      (widget.book.borrowerId != null)
                          ? SizedBox(
                              child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Lent to:\n",
                                    style: TextStyle(
                                      fontSize: 18, // Larger font for "Lent to"
                                      fontWeight: FontWeight.bold,
                                      color: Colors
                                          .black, // Ensure proper color rendering
                                    ),
                                  ),
                                  TextSpan(
                                    text: widget.book.userLent.toString(),
                                    style: TextStyle(
                                      fontSize:
                                          15, // Smaller font for borrowerId
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),)
                          : const SizedBox.shrink(),
                    ],
                  ),
                  //const SizedBox(height: 2),
                ],
              ),
            ),
            //const SizedBox(height: 10),
            Flexible(
              child: SegmentedButton<_ReadStatus>(
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
            ),
            
            (widget.book.isManualAdded == true)
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
    );
  }
}
