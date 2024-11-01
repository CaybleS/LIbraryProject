import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Screens/MSG/HomeScreen.dart';


FirebaseAuth auth = FirebaseAuth.instance;


String kGetTime(DateTime lastSign) {
  int time = DateTime.now().difference(lastSign).inHours;
  if (time < 48) return 'last seen recently';
  if (time >= 48 && time < 168) return 'last seen less than a week';
  return 'last seen... ';
}

kNavigator(context, String text , User user) async {
  if (text == 'home') {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser!.uid)
        .update({
      'isActive': true,
      'lastSignedIn': DateTime.now(),
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
}