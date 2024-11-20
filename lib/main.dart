import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'MSG/Core/Accounting/Authenticate.dart';
import 'firebase_options.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MainApp());
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
          backgroundColor: Colors.white
        )
      ),
        home: Authenticate());
  }
}
