import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/ui/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class CustomAdd extends StatefulWidget {
  final User user;
  final List<Book> userLibrary;
  const CustomAdd(this.user, this.userLibrary, {super.key});

  @override
  State<CustomAdd> createState() => _CustomAddState();
}

class _CustomAddState extends State<CustomAdd> {
  final _inputTitleController = TextEditingController();
  final _inputAuthorController = TextEditingController();
  bool _noTitleInput = false;
  bool _noAuthorInput = false;
  bool _bookAlreadyAddedError = false;
  XFile? _coverImage;
  String? _coverImageUrl;

  @override
  void initState() {
    super.initState();
    _inputTitleController.addListener(() {
      if (_noTitleInput && _inputTitleController.text.isNotEmpty) {
        setState(() {
          _noTitleInput = false;
        });
    }});
    _inputAuthorController.addListener(() {
      if (_noAuthorInput && _inputAuthorController.text.isNotEmpty) {
        setState(() {
          _noAuthorInput = false;
        });
    }});
  }

  @override
  void dispose() {
    _inputTitleController.dispose();
    _inputAuthorController.dispose();
    super.dispose();
  }

  void _checkInputs(String titleInput, String authorInput) {
    _resetErrors();
    Book customAddedBook = Book(title: titleInput, author: authorInput, coverUrl: _coverImageUrl, isManualAdded: true);
    for (int i = 0; i < widget.userLibrary.length; i++) {
      if (customAddedBook == widget.userLibrary[i]) {
        _bookAlreadyAddedError = true;
        break;
      }
    }
    if (_bookAlreadyAddedError) {
      String failMessage = _getFailMessage();
      SharedWidgets.displayErrorDialog(context, failMessage);
    }
    else {
      // ordered this way so that we pop to add book homepage before showing book added dialog
      Navigator.pop(context, "added");
      addBookToLibrary(customAddedBook, widget.user, context);
    }
  }

  void _resetErrors() {
    _bookAlreadyAddedError = false;
  }

  String _getFailMessage() {
    if (_bookAlreadyAddedError) {
      return "You already have this book added.";
    }
    return "";
  }

  Future<void> _addCoverFromFile(BuildContext context) async {
    try {
      XFile? inputCoverImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (inputCoverImage != null) {
        File coverImageFile = File(inputCoverImage.path);
        String coverImageFileName = const Uuid().v1();
        bool coverImgUploadError = false;
        final Reference imageRef = FirebaseStorage.instance.ref().child('customBookCovers/$coverImageFileName');
        TaskSnapshot uploadTask = await imageRef.putFile(coverImageFile).catchError((error) {
          coverImgUploadError = true;
        });
        if (!coverImgUploadError) {
          _coverImageUrl = await uploadTask.ref.getDownloadURL();
          _coverImage = inputCoverImage;
        }
      }
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
      XFile? inputCoverImage = await ImagePicker().pickImage(source: ImageSource.camera);
      if (inputCoverImage != null) {
        File coverImageFile = File(inputCoverImage.path);
        String coverImageFileName = const Uuid().v1();
        bool coverImgUploadError = false;
        final Reference imageRef = FirebaseStorage.instance.ref().child('customBookCovers/$coverImageFileName');
        TaskSnapshot uploadTask = await imageRef.putFile(coverImageFile).catchError((error) {
          coverImgUploadError = true;
        });
        if (!coverImgUploadError) {
          _coverImageUrl = await uploadTask.ref.getDownloadURL();
          _coverImage = inputCoverImage;
        }
      }
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
              "Add Custom Book Here",
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
                  Flexible(child: SharedWidgets.displayTextField("Enter title here", _inputTitleController, _noTitleInput, "Please enter a title")),
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
                  Flexible(child: SharedWidgets.displayTextField("Enter author here", _inputAuthorController, _noAuthorInput, "Please enter an author")),
                ],
              )
            ),
            const SizedBox(height: 16),
            IntrinsicHeight( // the column inside of this row needs to be not be constrained by this row, I believe this achieves this
              child: Row(
                children: [
                  const SizedBox(
                    width: 60,
                    child: Text("Cover:", style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: 0.7,
                      child: (_coverImage != null)
                        ? Image.file(
                            File(_coverImage!.path),
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                          "assets/no_cover.jpg".toString(),
                            fit: BoxFit.fill,
                          ),
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
                            if (_coverImage != null) {
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8)),
                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text("Add Cover From File", style: TextStyle(fontSize: 16, color: Colors.black))),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _addCoverFromCamera(context);
                            if (_coverImage != null) {
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8)),
                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text("Add Cover From Camera", style: TextStyle(fontSize: 16, color: Colors.black))),
                        ),
                        _coverImage != null
                        ? ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _coverImage = null;
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
                        onPressed: () {
                          String title = _inputTitleController.text;
                          String author = _inputAuthorController.text;
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
                        child: const Text("Add Book", style: TextStyle(fontSize: 16, color: Colors.black)),
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
