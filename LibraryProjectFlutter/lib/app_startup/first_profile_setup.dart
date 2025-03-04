import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
// TODO this needs goodreads import sokmewhere also idk how exactly to design it but yeh. (remove all these comments when done)
// and when selecting a username there maybe should be something which automatically determines if the username is good
// so that they can import with goodreads on this page. In my head its intuitive to have it that way. You enter the uesrname, it says its
// valid with a nice checkmark and you're good to go and you also can import from goodreads at that point or something
// ehh idk its weird because once you import it assumes your accoutn is created but technically its not right or is it?
// so maybe you enter a username and as soon as it says its valid it writes it ot the db and you are in? Idk if thats good necesarily

class FirstProfileSetup extends StatefulWidget {
  final User user;
  final String? usernameFromEmail;

  const FirstProfileSetup(this.user, {this.usernameFromEmail, super.key});

  @override
  State<FirstProfileSetup> createState() => _FirstProfileSetupState();
}

class _FirstProfileSetupState extends State<FirstProfileSetup> {
  final _inputUsernameController = TextEditingController();
  bool _noUsernameInput = false;
  bool _noUsernameInputOrInputIsMaxLength = false;

  @override
  void initState() {
    super.initState();
    _inputUsernameController.addListener(() {
      if (_noUsernameInputOrInputIsMaxLength && _inputUsernameController.text.isNotEmpty) {
        setState(() {
          _noUsernameInputOrInputIsMaxLength = false;
          _noUsernameInput = false;
        });
      }
      if (_inputUsernameController.text.length == 32) {
        setState(() {
        _noUsernameInputOrInputIsMaxLength = true;
        });
      }
    });
    if (widget.usernameFromEmail != null) {
      String usernameToPutInController = widget.usernameFromEmail!;
      usernameToPutInController = usernameToPutInController.trim().toLowerCase(); // ensure this is done before replacing the invalid characters
      usernameToPutInController = _replaceAllInvalidCharacters(usernameToPutInController);
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
      _noUsernameInputOrInputIsMaxLength = true;
      setState(() {});
      return false;
    }
    if (!_checkIfUsernameContainsValidCharacters(usernameInput)) {
      SharedWidgets.displayErrorDialog(context, "Username contains special characters. Please ensure it's only letters and numbers.");
      return false;
    }
    if (await usernameExists(usernameInput)) {
      if (mounted) {
        SharedWidgets.displayErrorDialog(context, "Username is already taken");
      }
      return false;
    }
    return true;
  }

  // firebase doesnt allow certain characters such as . so to simplify we just guarantee usernames only contain alphanumeric + underscore
  bool _checkIfUsernameContainsValidCharacters(String usernameInput) {
    if (RegExp(r'^[a-z0-9_]+$').hasMatch(usernameInput)) {
      return true;
    }
    return false;
  }

  // this is for usernames extracted from emails since it can have some non-alphanumeric characters, so we just call this
  // before auto putting that username in the text editing controller
  String _replaceAllInvalidCharacters(String usernameToFix) {
    usernameToFix = usernameToFix.replaceAll(RegExp(r'[^a-z0-9]'), "");
    return usernameToFix;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        title: const Text("Set Your Username"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 15, 10, 21),
        child: Column(
          children: [
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
                        errorText: _noUsernameInputOrInputIsMaxLength ? (_noUsernameInput ? "Please enter a username" : "You are at the 32-character limit") : null,
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
            const SizedBox(height: 10),
            Flexible(
              child: SizedBox(
                width: double.infinity,
                  child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: () async {
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
                    child: const Text("Create Account", style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                ),
              ),
            ),
          ],
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