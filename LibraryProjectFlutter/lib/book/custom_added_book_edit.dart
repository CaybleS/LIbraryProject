import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/add_book/custom_add/book_cover_changers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/models/book.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'dart:io';

class CustomAddedBookEdit extends StatefulWidget {
  final User user;
  final Book book; // obviously this book will have the isManualAdded bool set to true
  const CustomAddedBookEdit(this.book, this.user, {super.key});

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
  bool _coverIsSet = false; // needed to allow for users to only clear the cover and nothing else
  bool _coverChanged = false;
  XFile? _newCoverImage;
  String? _newCoverImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.book.cloudCoverUrl != null || widget.book.coverUrl != null) {
      _coverIsSet = true;
    }
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
    for (int i = 0; i < userLibrary.length; i++) {
      if (widget.book == userLibrary[i]) {
        return i;
      }
    }
    return null;
  }

  Future<void> _checkInputs(String titleInput, String authorInput) async {
    _resetErrors();
    int? userLibraryIndexOfThisBook = _getUserLibraryIndexOfThisBook();
    if (userLibraryIndexOfThisBook == null) {
      _bookNoLongerExistsError = true;
    }
    Book customAddedBook = Book(title: titleInput, author: authorInput, isManualAdded: true);
    // the first check is intuitive, the last checks for the either no cover change (simple) or the case where the book
    // initially has no cover, a cover is set, and then the cover is cleared again.
    if (customAddedBook == widget.book && (!_coverChanged || (_newCoverImage == null && !_coverIsSet))) {
      _noChangeError = true;
    }
    for (int i = 0; i < userLibrary.length; i++) {
      // ensuring we don't change the custom added book to any books already added while also allowing it to change if
      // we dont change title and author and only change cover image
      if (customAddedBook == userLibrary[i] && i != userLibraryIndexOfThisBook) {
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
      if (_newCoverImage != null) {
        _newCoverImageUrl = await uploadCoverToStorage(context, _newCoverImage!);
        // note that if newCoverImageUrl is null, an error occured and an error dialog should be shown. In this case, the book still gets updated
        // just without a cover image set. HOWEVER the condition below this checks if both the changed cover failed to upload, and the cover is
        // the only thing changed. In this case, we don't change anything and just show the error.
        if (_newCoverImageUrl == null && widget.book == customAddedBook) {
          return;
        }
        widget.book.cloudCoverUrl = _newCoverImageUrl;
      }
      else if (_coverChanged && widget.book.cloudCoverUrl != null) { // this is the case where the user clears the custom added cover (resets to no cover placeholder)
        deleteCoverFromStorage(widget.book.cloudCoverUrl!);
        widget.book.cloudCoverUrl = null;
      }
      widget.book.title = titleInput;
      widget.book.author = authorInput;
      widget.book.update();
      if (mounted) {
        // ordered this way intentionally so that we see the previous page before the feedback
        Navigator.pop(context);
        SharedWidgets.displayPositiveFeedbackDialog(context, "Book edited");
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Book"),
        centerTitle: true,
        backgroundColor: AppColor.appbarColor,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
        child: Column(
          children: [
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
            IntrinsicHeight( // the column inside of this row needs to be not be constrained by this row, I believe this achieves this
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
                      child: (_coverChanged)
                        ? (_newCoverImage != null) 
                            ? Image.file(
                                File(_newCoverImage!.path),
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                "assets/no_cover.jpg",
                                fit: BoxFit.fill,
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
                            _newCoverImage = await selectCoverFromFile(context);
                            if (_newCoverImage != null) {
                              _coverChanged = true;
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8)),
                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text("Upload From File", style: TextStyle(fontSize: 16, color: Colors.black))),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            _newCoverImage = await selectCoverFromCamera(context);
                            if (_newCoverImage != null) {
                              _coverChanged = true;
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8)),
                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text("Upload From Camera", style: TextStyle(fontSize: 16, color: Colors.black))),
                        ),
                        (_coverIsSet || _newCoverImage != null)
                          ? ElevatedButton(
                              onPressed: () async {
                                _newCoverImage = null;
                                _coverChanged = true;
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
            Flexible(
              child: Row(
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
                        onPressed: () async {
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
                          await _checkInputs(title, author);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue),
                        child: const Text("Edit Book", style: TextStyle(fontSize: 16, color: Colors.black), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
