import 'package:flutter/material.dart';
import 'package:library_project/models/book.dart';

class FriendBookPage extends StatelessWidget {
  final Book _bookToView;
  const FriendBookPage(this._bookToView, {super.key});

  Widget _displayStatus() {
    String availableTxt;
    Color availableTxtColor;

    if (_bookToView.lentDbKey != null) {
      availableTxt = "Lent";
      availableTxtColor = Colors.red;
    } else {
      availableTxt = "Available";
      availableTxtColor = const Color(0xFF43A047);
    }

    return Text(
      availableTxt,
      style: TextStyle(fontSize: 16, color: availableTxtColor),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Row(
                children: [
                  AspectRatio(
                    aspectRatio: 0.7,
                    child: _bookToView.getCoverImage(),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            _bookToView.author ?? "No author found",
                            style: const TextStyle(fontSize: 16),
                            maxLines: 2,
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
              height: 15,
            ),
            const Text("Current Status:", style: TextStyle(fontSize: 16)),
            Flexible(
              child: _displayStatus(),
            ),
          ],
        ),
      ),
    );
  }
}
