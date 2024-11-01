import 'package:flutter/material.dart';

Widget googleLoginButtonWidget(VoidCallback click) {
  return OutlinedButton(
    onPressed: click,
    child: const Padding(
      padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image(image: AssetImage('assets/google_logo.png'), height: 25),
          Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text('Sign in with Google',
                  style: TextStyle(color: Colors.grey, fontSize: 18)))
        ],
      ),
    ),
  );
}