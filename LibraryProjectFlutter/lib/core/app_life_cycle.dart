import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shelfswap/app_startup/auth.dart';
import 'package:shelfswap/app_startup/connectivity_wrapper.dart';

class AppLifeCycle extends StatefulWidget {
  const AppLifeCycle({super.key, required this.child});

  final Widget child;

  @override
  AppLifeCycleState createState() => AppLifeCycleState();
}

class AppLifeCycleState extends State<AppLifeCycle> with WidgetsBindingObserver {
  FirebaseAuth auth = FirebaseAuth.instance;
  final dbReference = FirebaseDatabase.instance.ref();

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
