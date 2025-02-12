import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/connectivity_wrapper.dart';

class AppLifeCycle extends StatefulWidget {
  const AppLifeCycle({super.key, required this.child});

  final Widget child;

  @override
  AppLifeCycleState createState() => AppLifeCycleState();
}

class AppLifeCycleState extends State<AppLifeCycle> with WidgetsBindingObserver {
  FirebaseAuth auth = FirebaseAuth.instance;
  final dbReference = FirebaseDatabase.instance.ref();

  changeStatus(bool status) async {
    if (auth.currentUser != null) {
      await FirebaseDatabase.instance.ref('users/${auth.currentUser!.uid}').update({
        'isActive': status,
        'lastSignedIn': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      changeStatus(true);
      // when app gets reopened the connection checker re-checks for connectivity changes, since in some "rare" cases the backgrounded app doesnt detect them correctly
      connectivityKey.currentState?.initConnectivity();
    } //
    else {
      changeStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
