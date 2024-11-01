import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Screens/Library/homepage.dart';
import '../../Screens/LoginScreen.dart';

class Authenticate extends StatelessWidget {
  Authenticate({super.key});
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    if(auth.currentUser != null){
      return HomePage(auth.currentUser!);
    }else{
      return const LoginScreen();
    }
  }
}
