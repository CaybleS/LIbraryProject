import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shelfswap/database/database.dart';
import 'package:shelfswap/ui/colors.dart';

Future<String?> displaySetUsernameDialog(BuildContext context, User user, {String? usernameFromEmail}) async {
  String? usernameInput = await showDialog(
    context: context,
    builder: (context) => SetUsernameDialog(user, usernameFromEmail: usernameFromEmail),
  );
  return usernameInput;
}

class SetUsernameDialog extends StatefulWidget {
  final User user;
  final String? usernameFromEmail;

  const SetUsernameDialog(this.user, {this.usernameFromEmail, super.key});

  @override
  State<SetUsernameDialog> createState() => _SetUsernameDialogState();
}

class _SetUsernameDialogState extends State<SetUsernameDialog> {
  final _inputUsernameController = TextEditingController();
  bool _noUsernameInput = false;
  bool _inputIsMaxLength = false;
  bool _usernameContainsSpecialCharacters = false;
  bool _usernameAlreadyTaken = false;

  @override
  void initState() {
    super.initState();
    _inputUsernameController.addListener(() {
      bool somethingChanged = false; // optimization to prevent unnecessary setStates
      if (_inputIsMaxLength) {
        _inputIsMaxLength = false;
        somethingChanged = true;
      }
      if (_noUsernameInput && _inputUsernameController.text.isNotEmpty) {
        _noUsernameInput = false;
        somethingChanged = true;
      }
      if (!_inputIsMaxLength && _inputUsernameController.text.length == 32) {
        _inputIsMaxLength = true;
        somethingChanged = true;
      }
      if (_usernameContainsSpecialCharacters) {
        _usernameContainsSpecialCharacters = false;
        somethingChanged = true;
      }
      if (_usernameAlreadyTaken) {
        _usernameAlreadyTaken = false;
        somethingChanged = true;
      }
      if (somethingChanged) {
        setState(() {});
      }
    });
    if (widget.usernameFromEmail != null) {
      String usernameToPutInController = widget.usernameFromEmail!;
      usernameToPutInController = usernameToPutInController.trim().toLowerCase(); // ensure this is done before replacing the invalid characters
      usernameToPutInController = replaceAllInvalidCharacters(usernameToPutInController);
      _inputUsernameController.text = usernameToPutInController;
    }
  }

  @override
  void dispose() {
    _inputUsernameController.dispose();
    super.dispose();
  }

  Future<bool> _checkIfUsernameIsValid(String usernameInput) async {
    if (usernameInput.isEmpty) {
      _noUsernameInput = true;
      setState(() {});
      return false;
    }
    if (!checkIfUsernameContainsValidCharacters(usernameInput)) {
      _usernameContainsSpecialCharacters = true;
      setState(() {});
      return false;
    }
    if (await usernameExists(usernameInput)) {
      _usernameAlreadyTaken = true;
      setState(() {});
      return false;
    }
    return true;
  }

  String? _getUsernameControllerError() {
    if (_noUsernameInput) {
      return "Please enter a username";
    }
    if (_inputIsMaxLength) {
      return "You are at the 32-character limit";
    }
    if (_usernameContainsSpecialCharacters) {
      return "Username contains invalid characters";
    }
    if (_usernameAlreadyTaken) {
      return "Username is already taken";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(25)), // dialog has a border, Material widget doesnt
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          "Account Created: Pick A Username",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Flexible(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text("Username:", style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                    Flexible(
                      child: TextField(
                        controller: _inputUsernameController,
                        maxLength: 32,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        inputFormatters: [
                          LowerCaseTextFormatter(),
                        ],
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Enter username here",
                          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25.0)),
                          ),
                          errorText: _getUsernameControllerError(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              _inputUsernameController.clear();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                        onTapOutside: (event) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Flexible(
                child: SizedBox(
                  width: double.infinity,
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () async {
                        // handling the case where the user is on this screen on 2 devices
                        if (await userExists(widget.user.uid) && context.mounted) {
                          Navigator.pop(context, "Error: user already exists");
                          return;
                        }
                        // obviously it needs to be trimmed but I think usernames should be lowercase as well
                        // the LowerCaseTextFormatter should handle this but this is just being safe converting it to lower case again
                        String lowercaseUsernameInput = _inputUsernameController.text.trim().toLowerCase();
                        bool isValid = await _checkIfUsernameIsValid(lowercaseUsernameInput);
                        if (!isValid) {
                          return;
                        }
                        if (context.mounted) {
                          Navigator.pop(context, lowercaseUsernameInput);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColor.skyBlue),
                      child: const Text("Done", style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}

// firebase doesnt allow certain characters such as . so to simplify we just guarantee usernames only contain alphanumeric + underscore
bool checkIfUsernameContainsValidCharacters(String usernameInput) {
  if (RegExp(r'^[a-z0-9_]+$').hasMatch(usernameInput)) {
    return true;
  }
  return false;
}

// this is for usernames extracted from emails since it can have some non-alphanumeric characters, so we just call this
// before auto putting that username in the text editing controller
String replaceAllInvalidCharacters(String usernameToFix) {
  usernameToFix = usernameToFix.replaceAll(RegExp(r'[^a-z0-9]'), "");
  return usernameToFix;
}
