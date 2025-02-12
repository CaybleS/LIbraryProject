import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/user.dart';

// import 'package:library_project/database/firebase_options.dart';
import 'login.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<User?> signInWithGoogle() async {
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication? googleSignInAuthentication = await googleSignInAccount?.authentication;

  final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication?.idToken, accessToken: googleSignInAuthentication?.accessToken);

  final UserCredential userCredential = await _auth.signInWithCredential(credential);
  final User? user = userCredential.user;

  if (user != null) {
    assert(!user.isAnonymous);

    final User currentUser = _auth.currentUser!;
    assert(currentUser.uid == user.uid);

    // TODO: should probably send to some kind of profile set up instead of this, but for now this is fine
    if (!(await userExists(user.uid))) {
      addUser(user);
    }

    final userRef = await dbReference.child('users/${user.uid}').once();
    if (userRef.snapshot.value != null) {
      Map data = userRef.snapshot.value as Map;
      userModel.value = UserModel.fromJson(data);
    }

    await changeStatus(true);

    return user;
  } else {
    return null;
  }
}

Future<void> signOutGoogle() async {
  await googleSignIn.signOut();
}

void logout(context) async {
  await changeStatus(false);
  cancelDatabaseSubscriptions(); // ensuring the onvalue listeners are canceled before we are signed out
  if (_auth.currentUser != null) {
    for (var data in _auth.currentUser!.providerData) {
      debugPrint(data.providerId);
      if (data.providerId == "google.com") {
        await signOutGoogle();
      }
    }
  }
  await _auth.signOut();
  userModel.value = null;

  // we cant use the 5 bottombar navigators to do this logout, we use the root navigator
  Navigator.of(context, rootNavigator: true)
      .pushReplacement(MaterialPageRoute(builder: (context) => const LoginPage()));
}

Future<User?> logIn(String email, String password) async {
  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

    await changeStatus(true);
    final userRef = await dbReference.child('users/${userCredential.user!.uid}').once();
    if (userRef.snapshot.value != null) {
      Map data = userRef.snapshot.value as Map;
      userModel.value = UserModel.fromJson(data);
    }

    return userCredential.user;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

Future<User?> createAccount(String name, String email, String password) async {
  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

    if (userCredential.user == null) {
      debugPrint("user null");
    }

    // debugPrint("Account created Successful");
    await userCredential.user!.updateDisplayName(name);
    await userCredential.user!.reload();
    User? user = _auth.currentUser;

    if (user?.displayName == null) {
      debugPrint("display name null");
    }

    if (user?.email == null) {
      debugPrint("email null");
    }

    if (user != null) {
      addUser(user);
      await changeStatus(true);
    }

    return user;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

changeStatus(bool status) async {
  if (_auth.currentUser != null) {
    await FirebaseDatabase.instance.ref('users/${_auth.currentUser!.uid}').update({
      'isActive': status,
      'lastSignedIn': DateTime.now().toIso8601String(),
    });
  }
}
