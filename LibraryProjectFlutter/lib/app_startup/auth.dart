import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shelfswap/app_startup/appwide_setup.dart';
import 'package:shelfswap/app_startup/set_username_dialog.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/core/settings.dart';
import 'package:shelfswap/database/database.dart';
import 'package:shelfswap/models/user.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'login.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<bool> _setupProfileAndAddUser(User user, BuildContext context, {String? usernameFromEmail}) async {
  String? username = await displaySetUsernameDialog(context, user, usernameFromEmail: usernameFromEmail);
  if (username == null) {
    return false;
  }
  // this handles the case where 2 devices are both on SetUsernamePage at once, if so it just pops with that and we dont add the 2nd device
  if (username != "Error: user already exists") {
    addUser(user, username);
  }
  return true;
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
    if (user == null) {
      return null;
    }

    if (!(await userExists(user.uid)) && context.mounted) {
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
      bool? usernameAdded = await _setupProfileAndAddUser(user, context, usernameFromEmail: userEmail);
      if (!usernameAdded) {
        // in this case the user signed in with google but didnt set their username on the username setup page
        // so we just sign them out with google and start from square 1 (only difference being that the auth
        // account exists now). So thats the point of the return null
        for (var data in _auth.currentUser!.providerData) {
          if (data.providerId == "google.com") {
            await signOutGoogle();
          }
        }
        return null;
      }
    }

    final DataSnapshot userSnapshot = await dbReference.child('users/${user.uid}').get();
    if (userSnapshot.value != null) {
      Map data = userSnapshot.value as Map;
      userModel.value = UserModel.fromJson(data, userSnapshot.key!);
      await changeStatus(true);
    }

    return user;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

Future<void> signOutGoogle() async {
  await _googleSignIn.signOut();
}

Future<void> logout(context) async {
  await changeStatus(false);
  if (_auth.currentUser != null) {
    cancelDatabaseSubscriptions(_auth.currentUser!); // ensuring the onvalue listeners are canceled before we are signed out
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

Future<Map<String, dynamic>> logIn(String email, String password, BuildContext context) async {
  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

    if (userCredential.user == null) {
      // I don't know if we need to return here but I do just to be safe
      return {
        'status': false,
        'error': 'An unknown error occured. Please try again.',
      };
    }

    if (userCredential.user?.emailVerified == false) {
      return {
        'status': false,
        'error': 'Your email is not verified. Please check your inbox and verify your account to continue.',
      };
    }

    // this checks for the case where the user signs up the account but doesnt enter username in the
    // input username dialog
    if (!(await userExists(userCredential.user!.uid)) && context.mounted) {
      bool? usernameAdded = await _setupProfileAndAddUser(userCredential.user!, context);
      if (!usernameAdded) {
        return {
          'status': false,
          'error': 'You must set a username. Please try again.',
        };
      }
    }

    final DataSnapshot userSnapshot = await dbReference.child('users/${userCredential.user!.uid}').get();
    if (userSnapshot.value != null) {
      Map data = userSnapshot.value as Map;
      userModel.value = UserModel.fromJson(data, userSnapshot.key!);
      await changeStatus(true);
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
        bool usernameSet = await _setupProfileAndAddUser(user, context);
        if (!usernameSet) {
          return null;
        }
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
    // check if user exists since users can use oauth to create account but not set a username on the set username page,
    // so their auth currentUser is set but they dont exist yet
    if (await userExists(_auth.currentUser!.uid)) {
      await FirebaseDatabase.instance.ref('users/${_auth.currentUser!.uid}').update({
        'isActive': status,
        'lastSignedIn': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }
}

// false return value signals error which causes the calling function to just return instead of continuing
Future<bool> reauthenticateUser(BuildContext context, User user) async {
  AuthCredential? credential;
  try {
    for (var userInfo in user.providerData) {
      if (userInfo.providerId == "google.com") {
        final GoogleSignInAccount? googleSignInAccount = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication? googleSignInAuthentication = await googleSignInAccount?.authentication;
        if (googleSignInAuthentication == null) {
          return false;
        }
        credential = GoogleAuthProvider.credential(idToken: googleSignInAuthentication.idToken, accessToken: googleSignInAuthentication.accessToken);
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      else if (userInfo.providerId == "password") {
        String? pwd = await displayReenterPasswordDialog(context, user);
        if (pwd == null) {
          return false; // user closed the password dialog without submitting anything
        }
        if (pwd.isEmpty && context.mounted) {
          SharedWidgets.displayErrorDialog(context, "Please enter a password");
          return false;
        }
        credential = EmailAuthProvider.credential(email: user.email!, password: pwd);
        await user.reauthenticateWithCredential(credential);
        return true;
      }
    }
    return false;
  } on FirebaseAuthException catch (e) {
    // print(e); // more error handling can be added here as deemed necessary
    if (e.code == 'invalid-credential') {
      SharedWidgets.displayErrorDialog(context, "Incorrect password. Please try again.");
    }
    else {
      SharedWidgets.displayErrorDialog(context, "An unknown error occured.");
    }
    return false;
  }
  catch (e) {
    SharedWidgets.displayErrorDialog(context, "An unknown error occured.");
    return false;
  }
}