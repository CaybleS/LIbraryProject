import 'package:flutter/material.dart';
import 'appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Settings extends StatelessWidget {
  final User user;
  const Settings(this.user, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: displayAppBar(context, user, "settings"),
      backgroundColor: Colors.grey[400],
      body: const Placeholder(),
    );
  }
}
