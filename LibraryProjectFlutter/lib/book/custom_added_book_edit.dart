import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _noTitleInput = false;
  bool _noAuthorInput = false;
  bool _noChangeError = false;
  bool _bookAlreadyAddedError = false;
  bool _bookNoLongerExistsError = false; // can only occur in scenarios where user is running the app on multiple devices
  XFile? _newCoverImage;

  @override
  void initState() {
    super.initState();
    _editTitleController.addListener(() {
      if (_noTitleInput && _editTitleController.text.isNotEmpty) {
        setState(() {
          _noTitleInput = false;
        });
      }
    });
    _editAuthorController.addListener(() {
      if (_noAuthorInput && _editAuthorController.text.isNotEmpty) {
        setState(() {
          _noAuthorInput = false;
        });
      }
    });
    _editTitleController.text = widget.book.title!;
    _editAuthorController.text = widget.book.author!;
  }

  @override
  void dispose() {
    _editTitleController.dispose();
    _editAuthorController.dispose();
    super.dispose();
  }

  // Should be like this since the index can theoretically change while user is on this page if they have the app open on another device
  int? _getUserLibraryIndexOfThisBook() {
    for (int i = 0; i < widget.userLibrary.length; i++) {
      if (widget.book == widget.userLibrary[i]) {
        return i;
      }
    }
    return null;
  }

  void _checkInputs(String titleInput, String authorInput) {
    _resetErrors();
    int? userLibraryIndexOfThisBook = _getUserLibraryIndexOfThisBook();
    if (userLibraryIndexOfThisBook == null) {
      _bookNoLongerExistsError = true;
    }
    Book customAddedBook = Book(title: titleInput, author: authorInput, isManualAdded: true);
    if (_newCoverImage == null && customAddedBook == widget.book) {
      _noChangeError = true;
    }
    for (int i = 0; i < widget.userLibrary.length; i++) {
      // ensuring we don't change the custom added book to any books already added while also allowing it to change if
      // we dont change title and author and only change cover image
      if (customAddedBook == widget.userLibrary[i] && i != userLibraryIndexOfThisBook) {
        _bookAlreadyAddedError = true;
        break;
      }
    }
  
    String failMessage = _getFailMessage();
    if (failMessage != "") {
      SharedWidgets.displayErrorDialog(context, failMessage);
      if (_bookNoLongerExistsError) {
        // this just takes us to the first route on this navigator stack which is the homepage
        Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
      }
    }
    else {
      if (titleInput.isEmpty || authorInput.isEmpty) {
        return;
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
    _bookNoLongerExistsError = false;
  }

  String _getFailMessage() {
    if (_bookNoLongerExistsError) { // should be highest priority error for obvious reasons
      return "Book no longer exists in your user library";
    }
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
    } on PlatformException catch (e) {
      if (e.code != "already_active" && context.mounted) {
        SharedWidgets.displayErrorDialog(context, "An unexpected error occurred. Please try again later.");
      }
    }
    catch (e) {
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, "An unexpected error occurred. Please try again later.");
      }
    }
  }

  Future<void> _addCoverFromCamera(BuildContext context) async {
    try {
      _newCoverImage = await ImagePicker().pickImage(source: ImageSource.camera);
    } on PlatformException catch (e) {
      if (!context.mounted) {
        return;
      }
      if (e.code == "camera_access_denied") {
        SharedWidgets.displayErrorDialog(context, "Camera access denied. Please enable it in your device settings.");
      }
      else if (e.code != "already_active") {
        SharedWidgets.displayErrorDialog(context, "An unexpected error occurred. Please try again later.");
      }
    }
    catch (e) {
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, "An unexpected error occurred. Please try again later.");
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
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
        child: Column(
          children: [
            const Text(
              "Edit Custom Added Book Here",
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Row(
                children: [
                  const SizedBox(
                    width: 60,
                    child: Text("Title:", style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                  Flexible(child: SharedWidgets.displayTextField("Enter title here", _editTitleController, _noTitleInput, "Please enter a title")),
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
                  Flexible(child: SharedWidgets.displayTextField("Enter author here", _editAuthorController, _noAuthorInput, "Please enter an author")),
                ],
              )
            ),
            const SizedBox(height: 16),
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
                  const SizedBox(width: 13),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        if (title.isEmpty) {
                          _noTitleInput = true;
                        }
                        if (author.isEmpty) {
                          _noAuthorInput = true;
                        }
                        if (_noTitleInput || _noAuthorInput) {
                          setState(() {});
                          return;
                        }
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
