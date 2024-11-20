import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../Screens/MSG/HomeScreen.dart';


FirebaseAuth auth = FirebaseAuth.instance;
final DatabaseReference _database = FirebaseDatabase.instance.ref();

String kGetTime(DateTime lastSign) {
  int time = DateTime.now().difference(lastSign).inHours;
  if (time < 48) return 'last seen recently';
  if (time >= 48 && time < 168) return 'last seen less than a week';
  return 'last seen... ';
}

kNavigator(context, String text , User user) async {
  if (text == 'home') {
    await _database.child('users').child(auth.currentUser!.uid).update({
      'isActive': true,
      'lastSignedIn': DateTime.now().toIso8601String(),
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
}