import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/book/book_requests_page.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/models/book.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';

Future<void> displayAppReturnDialog(BuildContext context, User user) async {
  int numBooksReadyToReturn = 0;
  for (Book book in userLibrary) {
    if (book.readyToReturn ?? false) {
      numBooksReadyToReturn++;
    }
  }
  // so if there are no requests or books ready to return just dont show the dialog. I think it's better
  if (numBooksReadyToReturn == 0 && receivedBookRequests.isEmpty) {
    return;
  }
  await showDialog(
    context: context,
    builder: (context) => AppReturnDialog(user),
  );
}

class AppReturnDialog extends StatefulWidget {
  final User user;
  const AppReturnDialog(this.user, {super.key});

  @override
  State<AppReturnDialog> createState() => _AppReturnDialogState();
}

class _AppReturnDialogState extends State<AppReturnDialog> {
  late final VoidCallback _updateDialogListener;
  int numBooksReadyToReturn = 0;

  @override
  void initState() {
    _setNumBooksReadyToReturn();
    super.initState();
    _updateDialogListener = () {
      _setNumBooksReadyToReturn();
    };
    pageDataUpdatedNotifier.addListener(_updateDialogListener);
  }

  @override
  void dispose() {
    pageDataUpdatedNotifier.removeListener(_updateDialogListener);
    super.dispose();
  }

  void _setNumBooksReadyToReturn() {
    numBooksReadyToReturn = 0;
    for (Book book in userLibrary) {
      if (book.readyToReturn ?? false) {
        numBooksReadyToReturn++;
      }
    }
    setState(() {});
  }

  Widget _displayInfoOnRequests() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("${receivedBookRequests.length} outstanding book requests"),
        (receivedBookRequests.isEmpty)
        ? const SizedBox.shrink()
        : Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 5),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8),
              ),
              onPressed: () async {
                // TODO should it pop the dialog idk
                await Navigator.push(context, MaterialPageRoute( builder: (context) => BookRequestsPage(widget.user)));
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "View",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

Widget _displayInfoOnReadyToReturn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Have $numBooksReadyToReturn books ready to return"),
        (numBooksReadyToReturn == 0)
        ? const SizedBox.shrink()
        : Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 5),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.skyBlue, padding: const EdgeInsets.all(8),
              ),
              onPressed: () {
                // TODO go to homepage place or something idk
                SharedWidgets.displayPositiveFeedbackDialog(context, "Not implemented sorry :(");
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "View",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _displayDialog() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text("Welcome Back", style: TextStyle(fontSize: 20, color: Colors.black), textAlign: TextAlign.center),
              ),
              const SizedBox(width: 24), // meant to center the "Welcome back" text by being the same size as the icon
            ],
          ),
        ),
        // const SizedBox(height: 6),
        Flexible(
          child: _displayInfoOnRequests(),
        ),
        // const SizedBox(height: 8),
        Flexible(
          child: _displayInfoOnReadyToReturn(),
        ),
        const SizedBox(height: 10),
        Flexible(
          child: SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.acceptGreen,
                padding: const EdgeInsets.all(8),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("Ok", style: TextStyle(fontSize: 16, color: Colors.black)),
              ),
            ),
          ),
        ),
      ],
    );
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
          child: _displayDialog(),
        ),
      ),
    );
  }
}
