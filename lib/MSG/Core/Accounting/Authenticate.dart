import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../LIB/homepage.dart';
import '../../Screens/LoginScreen.dart';

class Authenticate extends StatelessWidget {
  Authenticate({super.key});
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    if(auth.currentUser != null){
      return HomePage(auth.currentUser!);  //check user to see if it has been already  created or no
    }else{
      return const LoginScreen();
    }
  }
}
