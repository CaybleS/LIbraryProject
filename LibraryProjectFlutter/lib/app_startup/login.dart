import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/persistent_bottombar.dart';
import 'auth.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoginBody(),
    );
  }
}

class LoginBody extends StatefulWidget {
  const LoginBody({super.key});

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  User? user;

  @override
  void initState() {
    super.initState();
    signOutGoogle();
    //This will make user sign in every time, commented out bc I got tired of logging in when testing :)
  }

  void click() {
    signInWithGoogle().then((user) => {
          if (user != null)
            {
              this.user = user,
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => PersistentBottomBar(user))) // the bottombar will load the necessary pages when it exists
            }
        });
  }

  Widget googleLoginButton() {
    return OutlinedButton(
        onPressed: click,
        child: const Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(image: AssetImage('assets/google_logo.png'), height: 35),
                Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text('Sign in with Google',
                        style: TextStyle(color: Colors.grey, fontSize: 25)))
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: googleLoginButton(),
    );
  }
}
