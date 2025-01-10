import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/ui/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'dart:io';

class CustomAddedBookEdit extends StatefulWidget {
  final User user;
  final Book book; // obviously this book will have the isManualAdded bool set to true
  final List<Book> userLibrary; // only used for duplicate checking (so if user changes title and author both to a book already in user library, we show error and disallow it)
  const CustomAddedBookEdit(this.book, this.user, this.userLibrary, {super.key});

  @override
  State<CustomAddedBookEdit> createState() => _CustomAddedBookEditState();
}

class _CustomAddedBookEditState extends State<CustomAddedBookEdit> {
  final _editTitleController = TextEditingController();
  final _editAuthorController = TextEditingController();
  bool _noChangeError = false;
  bool _bookAlreadyAddedError = false;
  XFile? _newCoverImage;
  late final int _userLibraryIndexOfThisBook; // could just pass this in from homepage but its fine

  @override
  void initState() {
    super.initState();
    _editTitleController.text = widget.book.title!;
    _editAuthorController.text = widget.book.author!;
    for (int i = 0; i < widget.userLibrary.length; i++) {
      if (areBooksSame(widget.book, widget.userLibrary[i])) {
        _userLibraryIndexOfThisBook = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _editTitleController.dispose();
    _editAuthorController.dispose;
    super.dispose();
  }

  void _checkInputs(String titleInput, String authorInput) {
    _resetErrors();
    Book customAddedBook = Book(title: titleInput, author: authorInput, isManualAdded: true);
    if (_newCoverImage == null && areBooksSame(customAddedBook, widget.book)) {
      _noChangeError = true;
    }
    for (int i = 0; i < widget.userLibrary.length; i++) {
      // ensuring we don't change the custom added book to any books already added while also allowing it to change if we dont change title and author
      // and only change cover image
      if (areBooksSame(customAddedBook, widget.userLibrary[i]) && i != _userLibraryIndexOfThisBook) {
        _bookAlreadyAddedError = true;
        break;
      }
    }
  
    String failMessage = _getFailMessage();
    if (failMessage != "") {
      SharedWidgets.displayErrorDialog(context, failMessage);
    }
    else {
      if (titleInput.isEmpty) {
        titleInput = widget.book.title!;
      }
      if (authorInput.isEmpty) {
        authorInput = widget.book.author!;
      }
      widget.book.title = titleInput;
      widget.book.author = authorInput;
      widget.book.update();
      Navigator.pop(context);
      SharedWidgets.displayPositiveFeedbackDialog(context, "Book edited");
    }
  }

  void _resetErrors() {
    _noChangeError = false;
    _bookAlreadyAddedError = false;
  }

  String _getFailMessage() {
    if (_noChangeError) {
      return "Please make a change to the book.";
    }
    if (_bookAlreadyAddedError) {
      return "You already have this book added.";
    }
    return "";
  }

  Future<void> _addCoverFromFile(BuildContext context) async {
    try {
      _newCoverImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (e) {
      // do some signaling that photo gallery was inaccessible
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, "Failed to access photo gallery. Please ensure that photo access is enabled in your device settings.");
      }
    }
  }

  Future<void> _addCoverFromCamera(BuildContext context) async {
    try {
      _newCoverImage = await ImagePicker().pickImage(source: ImageSource.camera);
    } catch (e) {
      // do some signaling that camera was inaccessible
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, "Camera setup failed. Please ensure that camera access is enabled in your device settings.");
      }
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
        padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
        child: Column(
          children: [
            const Text(
              "Edit Custom Added Book Here",
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Row(
                children: [
                  const SizedBox(
                    width: 60,
                    child: Text("Title:",
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                  Flexible(child: SharedWidgets.displayTextField("Enter title here", _editTitleController, false, "")),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Row(
                children: [
                  const SizedBox(
                    width: 60,
                    child: Text("Author:", style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                  Flexible(child: SharedWidgets.displayTextField("Enter author here", _editAuthorController, false, "")),
                ],
              )
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(
                    width: 60,
                    child: Text("Cover:", style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: 0.7,
                      child: (_newCoverImage != null)
                        ? Image.file(
                            File(_newCoverImage!.path),
                            fit: BoxFit.cover,
                          )
                        : widget.book.getCoverImage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await _addCoverFromFile(context);
                            if (_newCoverImage != null) {
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8)),
                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text("Add Cover From File", style: TextStyle(fontSize: 16, color: Colors.black))),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _addCoverFromCamera(context);
                            if (_newCoverImage != null) {
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8)),
                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text("Add Cover From Camera", style: TextStyle(fontSize: 16, color: Colors.black))),
                        ),
                        _newCoverImage != null
                        ? ElevatedButton(
                            onPressed: () async {
                              _newCoverImage = null;
                              setState(() {
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8)),
                            child: const FittedBox(fit: BoxFit.scaleDown, child: Text("Clear cover", style: TextStyle(fontSize: 16, color: Colors.black))),
                          )
                        : const SizedBox.shrink(),
                      ],
                    )
                  )
                ],
              )
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue),
                      child: const Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: () {
                        String title = _editTitleController.text;
                        String author = _editAuthorController.text;
                        _checkInputs(title, author);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue),
                      child: const Text("Edit Book", style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
