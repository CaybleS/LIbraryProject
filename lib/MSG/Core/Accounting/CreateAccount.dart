import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../Screens/LoginScreen.dart';


final DatabaseReference _database = FirebaseDatabase.instance.ref();
final FirebaseAuth auth = FirebaseAuth.instance;
Future<User?> createAccount(String name, String email, String password) async {


  try {
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email, password: password);

    debugPrint("Account created Successful");

    userCredential.user!.updateDisplayName(name);

    await _database.child('users').child(auth.currentUser!.uid).set({
      "name": name,
      "email": email,
      "status": "Unavailable",
      "uid": auth.currentUser!.uid,
    });

    return userCredential.user;
  } catch (e) {
    debugPrint("Create Account Is Failed : $e");
    return null;
  }
}

Future<User?> logIn(String email, String password) async {
  try {
    UserCredential userCredential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    debugPrint("Login Successful");
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      debugPrint("Current user is null after login.");
      return null;
    }
    final snapshot = await _database.child('users').child(currentUser.uid).once();
    if (snapshot.snapshot.value != null) {
      Map<dynamic, dynamic> userData = snapshot.snapshot.value as Map<dynamic, dynamic>;
      await currentUser.updateDisplayName(userData['name']);
    } else {
      debugPrint("No user data found in database for UID: ${currentUser.uid}");
    }
    return userCredential.user;
  } catch (e) {
    debugPrint("Login Failed: $e");
    return null;
  }
}


Future logOut(BuildContext context) async {
  try {
    await _database.child('users').child(auth.currentUser!.uid).update({
      "status": "Offline",
    });
    await auth.signOut().then((value) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    });
  } catch (e) {
    debugPrint("User Logout Is Failed With Error Is : $e");
  }
}
