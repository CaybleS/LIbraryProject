import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:library_project/app_startup/appwide_setup.dart';
import 'package:library_project/app_startup/first_profile_setup.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/models/user.dart';
import 'login.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<void> _setupProfileAndAddUser(User user, BuildContext context, {String? usernameFromEmail}) async {
  String username = await Navigator.push(context, MaterialPageRoute(builder: (context) => FirstProfileSetup(user, usernameFromEmail: usernameFromEmail)));
  addUser(user, username);
}

Future<User?> signInWithGoogle(BuildContext context) async {
  try {
    final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
    final GoogleSignInAuthentication? googleSignInAuthentication = await googleSignInAccount?.authentication;
    if(googleSignInAuthentication == null) return null;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken, accessToken: googleSignInAuthentication.accessToken);

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {

      if (!(await userExists(user.uid))) {
        if (context.mounted) {
          // this feteches the part of the email before the @ to use as placeholder default username input
          // so test@gmail.com, this will fetch the test part of the email, this logic also works if there are multiple @s in the email
          String? userEmail = user.email;
          if (userEmail != null) {
            int indexOfLastAtcharacter = 0;
            for (int i = 0; i < userEmail.length; i++) {
              if (userEmail[i] == "@") {
                indexOfLastAtcharacter = i;
              }
            }
            userEmail = userEmail.substring(0, indexOfLastAtcharacter);
          }
          await _setupProfileAndAddUser(user, context, usernameFromEmail: userEmail);
        }
      }

      final userRef = await dbReference.child('users/${user.uid}').once();
      if (userRef.snapshot.value != null) {
        Map data = userRef.snapshot.value as Map;
        userModel.value = UserModel.fromJson(data, userRef.snapshot.key!);
      }

      await changeStatus(true);

      return user;
    } else {
      return null;
    }
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

Future<void> signOutGoogle() async {
  await _googleSignIn.signOut();
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

Future<Map<String, dynamic>> logIn(String email, String password) async {
  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

    if (userCredential.user == null) {
      debugPrint("user null");
    }

    if (userCredential.user?.emailVerified == false) {
      return {
        'status': false,
        'error': 'Your email is not verified. Please check your inbox and verify your account to continue.',
      };
    }

    await changeStatus(true);
    final userRef = await dbReference.child('users/${userCredential.user!.uid}').once();
    if (userRef.snapshot.value != null) {
      Map data = userRef.snapshot.value as Map;
      userModel.value = UserModel.fromJson(data, userRef.snapshot.key!);
    }

    return {'status': true, 'user': userCredential.user};
  } catch (e) {
    debugPrint(e.toString());
    return {
      'status': false,
      'error': 'Incorrect Email or Password',
    };
  }
}

Future<User?> createAccount(String name, String email, String password, BuildContext context) async {
  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

    if (userCredential.user == null) {
      debugPrint("user null");
    }

    // debugPrint("Account created Successful");
    await userCredential.user!.updateDisplayName(name);
    await userCredential.user!.reload();
    User? user = _auth.currentUser;
    await user?.sendEmailVerification();

    if (user?.displayName == null) {
      debugPrint("display name null");
    }

    if (user?.email == null) {
      debugPrint("email null");
    }

    if (user != null) {
      if (context.mounted) {
        await _setupProfileAndAddUser(user, context);
      }
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
      'lastSignedIn': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
