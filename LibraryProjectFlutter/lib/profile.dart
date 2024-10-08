import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'appbar.dart';

class Profile extends StatelessWidget {
  final User user;
  const Profile(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: displayAppBar(context, user, "profile"),
      body: const Placeholder(),
    );
  }
}
