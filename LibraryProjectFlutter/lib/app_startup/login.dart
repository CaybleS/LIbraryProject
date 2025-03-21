import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shelfswap/app_startup/create_account_screen.dart';
import 'package:shelfswap/app_startup/persistent_bottombar.dart';
import 'package:shelfswap/database/database.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controllerEmail = TextEditingController();
  final controllerPswd = TextEditingController();
  String loginErr = '';
  bool showLoading = false;
  bool _noEmailInput = false;
  bool _noPasswordInput = false;

  User? user;

  @override
  void initState() {
    super.initState();

    initial();
    controllerEmail.addListener(() {
      if (_noEmailInput && controllerEmail.text.isNotEmpty) {
        setState(() {
          _noEmailInput = false;
        });
    }});
    controllerPswd.addListener(() {
      if (_noPasswordInput && controllerPswd.text.isNotEmpty) {
        setState(() {
          _noPasswordInput = false;
        });
    }});
    // signOutGoogle();
  }

  void initial() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (auth.currentUser != null && auth.currentUser!.emailVerified) {
        user = auth.currentUser;
        // this handles the case where the user didnt set their username on the first profile setup screen.
        // In this case even though the auth user is set, their account isnt setup
        if (!await userExists(auth.currentUser!.uid) && mounted) {
          FlutterNativeSplash.remove();
          // They signed in with google, so even if they close the app and reopen, if they click the sign in with google button
          // without this signOutGoogle() it will not let them select their email it will just use their last selected email automatically
          for (var data in auth.currentUser!.providerData) {
            if (data.providerId == "google.com") {
              await signOutGoogle();
            }
          }
          return;
        }
        await changeStatus(true);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PersistentBottomBar(user!)));
        }
      }
      else {
        FlutterNativeSplash.remove();
      }
    });
  }

  void click() async {
    setState(() {
      showLoading = true;
    });
    final user = await signInWithGoogle(context);
    setState(() {
      showLoading = false;
    });
    if (user != null) {
      this.user = user;
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PersistentBottomBar(user)));
      }
    }
  }

  Widget googleLoginButton() {
    return OutlinedButton(
      onPressed: click,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: Image(image: AssetImage('assets/google_logo.png'), height: 30),
            ),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void loginBtnClicked() async {
    String email = controllerEmail.text;
    String pswd = controllerPswd.text;
    loginErr = '';

    if (email == '') {
      _noEmailInput = true;
    }

    if (pswd == '') {
      _noPasswordInput = true;
    }

    if (_noEmailInput || _noPasswordInput) {
      setState(() {});
    }

    if (email != '' && pswd != '') {
      setState(() {
        showLoading = true;
      });
      Map<String, dynamic> userLogin = await logIn(email, pswd, context);

      if (userLogin['status'] == false) {
        loginErr = userLogin['error'];
        setState(() {
          showLoading = false;
        });
      } else {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => PersistentBottomBar(userLogin['user'])));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.appbarColor,
          title: const Text(
            'ShelfSwap',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                "assets/logo/app_logo.png",
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      // it was originally the color of the appbar (hard-coded color blue) by whoever made this. I think it's fine to make it the same color as appbar.
                      color: AppColor.appbarColor,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Please Sign In',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: controllerEmail,
                    decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: const TextStyle(color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        errorText: _noEmailInput ? "Required" : null,
                          suffixIcon: IconButton(
                            onPressed: () {
                              controllerEmail.clear();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    ),
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controllerPswd,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      errorText: _noPasswordInput ? "Required" : null,
                      suffixIcon: IconButton(
                        onPressed: () {
                          controllerPswd.clear();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(loginErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
                          onPressed: () {
                            loginBtnClicked();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Log In',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(IconsaxPlusLinear.login, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccount()));
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Register',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(IconsaxPlusLinear.user_add, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: size.height * 0.025,
                  ),
                  googleLoginButton(),
                  SizedBox(
                    height: size.height * 0.05,
                  ),
                ],
              ),
            ),
            if (showLoading)
              Container(
                color: Colors.grey.withOpacity(0.5),
                child: Center(
                  child: SharedWidgets.displayCircularProgressIndicator(),
                ),
              ),
          ],
        ));
  }
}
