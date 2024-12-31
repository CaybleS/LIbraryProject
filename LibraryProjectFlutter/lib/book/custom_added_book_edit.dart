// TODO this hole page.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';

class CustomAddedBookEdit extends StatefulWidget {
  final Book book; // obviously this book will have the isManualAdded bool set to true
  final User user;
  const CustomAddedBookEdit(this.book, this.user, {super.key});

  @override
  State<CustomAddedBookEdit> createState() => _CustomAddedBookEditState();
}

class _CustomAddedBookEditState extends State<CustomAddedBookEdit> {
  final _editTitleController = TextEditingController();
  final _editAuthorController = TextEditingController();

  @override
  void dispose() {
    _editTitleController.dispose();
    _editAuthorController.dispose;
    super.dispose();
  }

  void _clearControllers() {
    _editTitleController.clear();
    _editAuthorController.clear();
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
            const Text(
              "Title:",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 5),
            SharedWidgets.displayTextField("Enter title here", _editTitleController, false, ""),
            const SizedBox(height: 5),
            const Text(
              "Author:",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 5),
            SharedWidgets.displayTextField("Enter author here", _editAuthorController, false, ""),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () {
                String title = _editTitleController.text;
                String author = _editAuthorController.text;
                if (title.isEmpty) {
                  title = widget.book.title!;
                }
                if (author.isEmpty) {
                  author = widget.book.author!;
                }
                widget.book.title = title;
                widget.book.author = author;
                widget.book.update();
                _clearControllers();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.skyBlue,
              ),
              child: const Text("Edit Book", style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
