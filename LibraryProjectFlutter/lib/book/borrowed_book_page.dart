import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/models/book.dart';

class BorrowedBookPage extends StatefulWidget {
  final User user;
  final LentBookInfo lentBookInfo; // note that this object contains the book object itself
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
                      child: widget.lentBookInfo.book.getCoverImage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.lentBookInfo.book.title ?? "No title found",
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            widget.lentBookInfo.book.author ?? "No author found",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Text(
                              widget.lentBookInfo.book.description ?? "No description found",
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
            Text("This book is lent to you from ${widget.lentBookInfo.lenderId}", style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 10,),
            Text("This book has ${widget.lentBookInfo.book.usersWhoRequested?.length ?? 0} users who currently requested it!"), // TODO make this good
          ],
        ),
      ),
    );
  }
}
