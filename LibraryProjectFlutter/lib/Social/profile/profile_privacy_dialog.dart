import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/ui/colors.dart';

Future<void> displayProfilePrivacyDialog(BuildContext prevContext, User user) async {
  await showDialog(context: prevContext, builder: (context) => ProfilePrivacyDialog(user));
}

class ProfilePrivacyDialog extends StatelessWidget {
  final User user;
  const ProfilePrivacyDialog(this.user, {super.key});

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
                child: Text("Change Profile Privacy",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 15),
          child: Text(
            "Making your profile public will allow any user to view your profile, friends list, and library. "
            "While your profile is private you will still be able to recieve friend requests through your username, "
            "friend code, or QR code",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              DatabaseReference dbRef = FirebaseDatabase.instance.ref("users/${user.uid}/");
              await dbRef.update({"isPublic": false});
              // Private
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.skyBlue,
              padding: const EdgeInsets.all(6),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(userIdToUserModel[user.uid]!.isPublic ?
                "Make profile private" : "Keep profile private",
                style: const TextStyle(fontSize: 16, color: Colors.black),
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
              DatabaseReference dbRef = FirebaseDatabase.instance.ref("users/${user.uid}/");
              await dbRef.update({"isPublic": true});
              // Public
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.skyBlue,
              padding: const EdgeInsets.all(6),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(userIdToUserModel[user.uid]!.isPublic ?
                "Keep profile public" : "Make profile public",
                style: const TextStyle(fontSize: 16, color: Colors.black),
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
        borderRadius: const BorderRadius.all(
            Radius.circular(25)), // dialog has a border, Material widget doesnt
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
