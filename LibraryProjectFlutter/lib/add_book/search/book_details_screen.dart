// TODO ensure UI is good on this page - it seems to have wasted space especially on bigger screens. No idea how to fix it though.
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/ui/colors.dart';

class BookDetailsScreen extends StatelessWidget {
  final Book _bookToView;
  final bool _isBookAlreadyAdded;
  const BookDetailsScreen(this._bookToView, this._isBookAlreadyAdded, {super.key});

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
          mainAxisSize: MainAxisSize.min,
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
                      child: _bookToView.getCoverImage(),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible( 
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _bookToView.title ?? "No title found",
                            style: const TextStyle(fontSize: 20),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _bookToView.author ?? "No author found",
                            style: const TextStyle(fontSize: 16),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  _bookToView.description ?? "No description found",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Flexible(
              child: _isBookAlreadyAdded
                ? const Text("This book is already in your personal library!", style: TextStyle(fontSize: 14))
                : ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, "added"); // this text 'added' will signal to the page above it on the navigator stack, that the user added this book
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColor.pink),
                    child: const Text("Add Book", style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
