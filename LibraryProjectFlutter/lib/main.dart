import 'package:flutter/material.dart';
import 'package:library_project/app_startup/connectivity_wrapper.dart';
import 'package:library_project/app_startup/login.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Instead of going to LoginPage the internet connectivity checker is first inserted above the navigator so that it can show an error anywhere
      // if no internet connection is detected regardless of navigation. LoginPage is still the next page but takes as input LoginPage and runs it when its setup.
      builder: (context, child) {
        return ConnectivityWrapper(child: child ?? const SizedBox.shrink());
      },
      home: const LoginPage(),
    );
  }
}
