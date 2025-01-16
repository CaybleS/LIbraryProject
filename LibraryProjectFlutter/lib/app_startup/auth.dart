import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:library_project/database/database.dart';
// import 'package:library_project/database/firebase_options.dart';
import 'login.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<User?> signInWithGoogle() async {
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication? googleSignInAuthentication =
      await googleSignInAccount?.authentication;

  final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication?.idToken,
      accessToken: googleSignInAuthentication?.accessToken);

  final UserCredential userCredential =
      await _auth.signInWithCredential(credential);
  final User? user = userCredential.user;

  if (user != null) {
    assert(!user.isAnonymous);

    final User currentUser = _auth.currentUser!;
    assert(currentUser.uid == user.uid);

    // TODO: should probably send to some kind of profile set up instead of this, but for now this is fine
    if (!(await userExists(user.uid))) {
      addUser(user);
    }

    return user;
  } else {
    return null;
  }
}

Future<void> signOutGoogle() async {
  await googleSignIn.signOut();
}

void logout(context) async {
  if (_auth.currentUser != null) {
    for (var data in _auth.currentUser!.providerData) {
      debugPrint(data.providerId);
      if (data.providerId == "google.com") {
        await signOutGoogle();
      }
    }
  }
  await _auth.signOut();

  //TODO: I think the bottom bar navigators might be messing with this logout, but not sure
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const LoginPage()));
}

Future<User?> logIn(String email, String password) async {
  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    // print("Login Sucessfull");
    // _firestore
    //     .collection('users')
    //     .doc(_auth.currentUser!.uid)
    //     .get()
    //     .then((value) => userCredential.user!.updateDisplayName(value['name']));

    return userCredential.user;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

Future<User?> createAccount(String name, String email, String password) async {
  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

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
    }

    return user;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}