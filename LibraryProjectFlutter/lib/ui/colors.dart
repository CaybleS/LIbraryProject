import 'package:flutter/material.dart';
// commented some colors out to signal that I didnt use them, also in general they didnt look good when I tried to use them!

// using this class with all statics just as a namespace for better readability
class AppColor {
  AppColor._(); // prevents class instantiation
  // static const Color veryDarkBlue = Color(0xFF101C29);
  static const Color darkBlue = Color(0xFF0A1C3D);
  static const Color blue = Color(0xFF2868C6);
  static const Color skyBlue = Color(0xFF91D2F4);
  static const Color pink = Color(0xFFCBA2EA);
  static const Color cancelRed = Color(0xFFD32F2F);
  static const Color acceptGreen = Color(0xFF43A047);
  static const Color appBackgroundColor = Color(0xFFBDBDBD); // grey[400], also dont set this in Scaffold widgets you create; its set in main.dart for all scaffolds
  static const Color lightGray = Color(0xFFEEEEEE); // grey[200]
  static const Color appbarColor = Colors.blue;
  // static const Color purple = Color(0xFF3F3381);
  // static const Color darkPurple = Color(0xFF1D1F5A);
}
