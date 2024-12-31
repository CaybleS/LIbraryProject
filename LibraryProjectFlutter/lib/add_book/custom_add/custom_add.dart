import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/add_book/custom_add/custom_add_driver.dart';
//import 'package:camera/camera.dart'; // currently unnecessary, but i want to scan book covers and import, and store in some cloud storage and also temp directory okay?
//import 'package:image_picker/image_picker.dart';
import 'package:library_project/ui/shared_widgets.dart';
//import 'package:path_provider/path_provider.dart';

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

  late CustomAddDriver _customAddInstance;

  @override
  void initState() {
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
    _customAddInstance = CustomAddDriver(widget.user, widget.userLibrary);
    super.initState();
  }

  @override
  void dispose() {
    _inputTitleController.dispose();
    _inputAuthorController.dispose;
    super.dispose();
  }

  void _clearControllers() {
    _inputTitleController.clear();
    _inputAuthorController.clear();
  }

  // TODO will do this when cloud storage method is determined; should be fairly easy to implement based off the working scanner_screen function
  // Future<void> _addCoverFromFile() async {
  //   try {
  //     final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);

  //     if (!mounted || file == null) {
  //       return;
  //     }
  //     if (mounted) {
  //     }
  //   } catch (e) {
  //     // obviously add some error handling
  //   }
  // }

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
            SharedWidgets.displayTextField("Enter title here", _inputTitleController, _noTitleInput, "Please enter a title"),
            const SizedBox(height: 5),
            const Text(
              "Author:",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 5),
            SharedWidgets.displayTextField("Enter author here", _inputAuthorController, _noAuthorInput, "Please enter an author"),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () {
                String title = _inputTitleController.text;
                String author = _inputAuthorController.text;
                if (title.isEmpty) {
                  _noTitleInput = true;
                }
                if (author.isEmpty) {
                  _noAuthorInput = true;
                }
                // ensures that title and author are both not null, since null titles or authors for manually added books can cause errors in custom added book edit file
                // not to mention for custom added books there just should be title and author both given
                if (_noTitleInput || _noAuthorInput) {
                  setState(() {});
                  return;
                }
                _customAddInstance.checkInputs(title, author, context);
                _clearControllers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.skyBlue,
              ),
              child: const Text("Add Book", style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
