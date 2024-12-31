import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/book/book_lend_page.dart';
import 'package:library_project/book/custom_added_book_edit.dart';
import 'package:library_project/database/database.dart';

class BookPage extends StatefulWidget {
  final Book book;
  final User user;
  const BookPage(this.book, this.user, {super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  LentBookInfo? lentBookInfo;

  @override
  void initState() {
    super.initState();
    getLentBookInfo();
  }

  Future<void> getLentBookInfo() async {
    if (widget.book.lentDbPath != null) {
      lentBookInfo = await getLentBook(widget.book);
      setState(() {});
    }
  }

  Widget _displayStatus() {
    String availableTxt;
    Color availableTxtColor;

    if (widget.book.lentDbPath != null) {
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
        await getLentBookInfo();
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
        (lentBookInfo?.borrowerId != null) ? Text("lent to ${lentBookInfo?.borrowerId}") : const SizedBox.shrink(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
        ),
        backgroundColor: Colors.grey[400],
        body: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 200,
                    width: 140,
                    child: widget.book.getCoverImage(),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(children: [
                    SizedBox(
                        width: 200,
                        child: Text(
                          widget.book.title ?? "No title found",
                          style: const TextStyle(fontSize: 30),
                        )),
                    const SizedBox(height: 5),
                    SizedBox(
                        width: 200,
                        child: Text(widget.book.author ?? "No author found",
                            style: const TextStyle(fontSize: 25))),
                    const SizedBox(height: 5),
                    SizedBox(
                        width: 200,
                        child: Text(widget.book.description ?? "No description found",
                            style: const TextStyle(fontSize: 12),
                            softWrap: true,
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                        ),
                    ),
                  ])
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              const Text("Status:", style: TextStyle(fontSize: 22)),
              _displayStatus(),
              const SizedBox(
                height: 10,
              ),
              // buttons go here
              (widget.book.lentDbPath != null) ? _returnBookButton() : _lendBookButton(),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  widget.book.remove(widget.user.uid);
                  Navigator.pop(context, "removed");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 202, 35, 23)),
                child: const Text("Remove book from library",
                  style: TextStyle(fontSize: 16, color: Colors.black)),
              ),
              (widget.book.isManualAdded)
              ? ElevatedButton(onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => CustomAddedBookEdit(widget.book, widget.user)));
                  setState(() {});
                },
                child: const Text("edit manually added book here"),
                )
              : const SizedBox.shrink(),
            ],
          ),
        ));
  }
}