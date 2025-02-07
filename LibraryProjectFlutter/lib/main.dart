import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shelfswap/app_startup/connectivity_wrapper.dart';
import 'package:shelfswap/app_startup/login.dart';
import 'package:shelfswap/core/app_life_cycle.dart';
import 'package:shelfswap/database/firebase_options.dart';
import 'package:shelfswap/ui/colors.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  // not awaited because the first thing it does is await the function which generates the "ask for notifications"
  // popup. It awaits what it needs to get notifications to work but we want UI to load regardless.
  setupDeviceNotifications();

  await dotenv.load(fileName: ".env");
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
        // this themeData does not override explicitly specified themes, so don't set scaffold background color unless you want to override this
        // you can make many things universal from here, its prob worth doing, you'd just have to go through every file to make sure its not overriden.
        theme: ThemeData(scaffoldBackgroundColor: AppColor.appBackgroundColor),
        home: const LoginPage(),
      ),
    );
  }
}
