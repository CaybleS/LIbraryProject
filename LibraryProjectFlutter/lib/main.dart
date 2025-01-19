import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/connectivity_wrapper.dart';
import 'package:library_project/app_startup/login.dart';
import 'package:library_project/core/app_life_cycle.dart';
import 'package:library_project/database/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseDatabase.instance.setPersistenceEnabled(true);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLifeCycle(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ShelfSwap',
        // Instead of going to LoginPage the internet connectivity checker is first inserted above the navigator so that it can show an error anywhere
        // if no internet connection is detected regardless of navigation. LoginPage is still the next page but takes as input LoginPage and runs it when its setup.
        builder: (context, child) {
          return ConnectivityWrapper(child: child ?? const SizedBox.shrink());
        },
        home: const LoginPage(),
      ),
    );
  }
}
