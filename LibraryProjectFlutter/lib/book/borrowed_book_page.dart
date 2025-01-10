import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';

class BorrowedBookPage extends StatefulWidget {
  final User user;
  final LentBookInfo lentBookInfo; // note that this object contains relevant the book object itself
  const BorrowedBookPage(this.lentBookInfo, this.user, {super.key});

  @override
  State<BorrowedBookPage> createState() => _BorrowedBookPageState();
}

class _BorrowedBookPageState extends State<BorrowedBookPage> {

  Widget _displayStatus() {
    String availableTxt;
    Color availableTxtColor;

    availableTxt = "Lent";
    availableTxtColor = Colors.red;

    return Text(
      availableTxt,
      style: TextStyle(fontSize: 22, color: availableTxtColor),
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
                    child: widget.lentBookInfo.book.getCoverImage(),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(children: [
                    SizedBox(
                        width: 200,
                        child: Text(
                          widget.lentBookInfo.book.title ?? "No title found",
                          style: const TextStyle(fontSize: 30),
                        )),
                    const SizedBox(height: 5),
                    SizedBox(
                        width: 200,
                        child: Text(widget.lentBookInfo.book.author ?? "No author found",
                            style: const TextStyle(fontSize: 25))),
                    const SizedBox(height: 5),
                    SizedBox(
                        width: 200,
                        child: Text(widget.lentBookInfo.book.description ?? "No description found",
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
              Text("This book is lent to you from ${widget.lentBookInfo.lenderId}", style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            ],
          ),
        ));
  }
}
