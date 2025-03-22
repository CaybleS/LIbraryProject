import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shelfswap/add_book/goodreads/goodreads_export.dart';
import 'package:shelfswap/add_book/goodreads/goodreads_import.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';

Future<void> displayGoodreadsDialog(BuildContext contextFromPageUserIsOn, User user) async {
  await showDialog(
    context: contextFromPageUserIsOn,
    builder: (context) => GoodreadsDialog(user, contextFromPageUserIsOn),
  );
}

class GoodreadsDialog extends StatelessWidget {
  final User user;
  final BuildContext contextFromPageUserIsOn;
  const GoodreadsDialog(this.user, this.contextFromPageUserIsOn, {super.key});

  Widget _displayDialogContent(BuildContext dialogContext) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(dialogContext),
                child: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text("Goodreads", style: TextStyle(fontSize: 20, color: Colors.black), textAlign: TextAlign.center),
              ),
              const SizedBox(width: 24), // meant to center the "Goodreads" text by being the same size as the icon
            ],
          ),
        ),
        const SizedBox(height: 6),
          SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              // basically i cant use url_launcher package to auto redirect users to this page, since goodreads force redirects users
              // to their app if they have it installed, and the import/export does not work on their app, only in web browsers.
              // So I believe this is the best way to do it, just having users copy the link and manually paste in their web browser.
              await Clipboard.setData(const ClipboardData(text: "https://www.goodreads.com/review/import"));
              if (contextFromPageUserIsOn.mounted) {
                SharedWidgets.displayPositiveFeedbackDialog(contextFromPageUserIsOn, "Goodreads link copied");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.skyBlue,
              padding: const EdgeInsets.all(6),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Copy link to goodreads import/export page",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await tryGoodreadsImport(user, contextFromPageUserIsOn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.skyBlue,
              padding: const EdgeInsets.all(6),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Import from goodreads csv",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await tryGoodreadsExport(contextFromPageUserIsOn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.skyBlue,
              padding: const EdgeInsets.all(6),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Export books to csv",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 15),
            child: Text(
            "The Goodreads import/export page doesn't exist in their app, so you need to download your books from Goodreads by going to the "
            "export page in your web browser by copying the link here and pasting it in a web browser. Also, for our exporting to "
            "Goodreads, not all our books can be transferred to Goodreads.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black),
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
          child: _displayDialogContent(context),
        ),
      ),
    );
  }
}
