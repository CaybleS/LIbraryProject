import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/add_book/shared_helper_util.dart';
import 'package:library_project/ui/shared_widgets.dart';

class CustomAddDriver {
  bool _bookAlreadyAddedError = false;
  late final User _user;
  late final List<Book> _userLibrary;

  CustomAddDriver(this._user, this._userLibrary);

  void checkInputs(String titleInput, String authorInput, BuildContext context) {
    _resetErrors();
    Book customAddedBook = Book(title: titleInput, author: authorInput, isManualAdded: true);
    for (int i = 0; i < _userLibrary.length; i++) {
      if (areBooksSame(customAddedBook, _userLibrary[i])) {
        _bookAlreadyAddedError = true;
        break;
      }
    }
    if (_bookAlreadyAddedError) {
      String failMessage = _getFailMessage();
      SharedWidgets.displayErrorDialog(context, failMessage);
    }
    else {
      Navigator.pop(context, "added");
      addBookToLibrary(customAddedBook, _user, _userLibrary, context);
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

}