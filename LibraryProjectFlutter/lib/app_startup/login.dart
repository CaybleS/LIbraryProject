import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:library_project/app_startup/create_account_screen.dart';
import 'package:library_project/app_startup/persistent_bottombar.dart';
import 'package:library_project/ui/shared_widgets.dart';
import 'auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controllerEmail = TextEditingController();
  final controllerPswd = TextEditingController();
  String emailErr = "";
  String pswdErr = "";
  String loginErr = "";
  bool showLoading = false;

  User? user;

  @override
  void initState() {
    super.initState();

    initial();
    // signOutGoogle();
  }

  void initial() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (auth.currentUser != null) {
        user = auth.currentUser;
        changeStatus(true);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PersistentBottomBar(user!)));
      }
    });
  }

  void click() {
    setState(() {
      showLoading = true;
    });
    signInWithGoogle().then((user) {
      if (user != null) {
        setState(() {
          showLoading = false;
        });
        this.user = user;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PersistentBottomBar(user)));
      }
    });
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
                    child: Text('Sign in with Google',
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)))
              ],
            )));
  }

  void loginBtnClicked() async {
    String email = controllerEmail.text;
    String pswd = controllerPswd.text;
    emailErr = "";
    pswdErr = "";
    loginErr = "";

    if (email == "") {
      emailErr = "Required";
      setState(() {});
    }

    if (pswd == "") {
      pswdErr = "Required";
      setState(() {});
    }

    if (email != "" && pswd != "") {
      setState(() {
        showLoading = true;
      });
      User? user = await logIn(email, pswd);

      if (user == null) {
        loginErr = "Incorrect Email or Password";
        setState(() {
          showLoading = false;
        });
      } else {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PersistentBottomBar(user)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text(
            'ShelfSwap',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          centerTitle: true,
          // actions: [
          //  TODO: add app logo
          // ],
        ),
        backgroundColor: Colors.grey[400],
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.center,
                    width: size.width * 0.9,
                    child: const Text(
                      "Welcome!",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: size.width * 0.9,
                    child: const Text(
                      "Please Sign In",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.1,
                  ),
                  Container(
                    width: size.width * 0.9,
                    alignment: Alignment.center,
                    child: TextField(
                      controller: controllerEmail,
                      decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: const TextStyle(color: Colors.grey),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.01,
                  ),
                  Text(emailErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
                  SizedBox(
                    height: size.height * 0.01,
                  ),
                  Container(
                    width: size.width * 0.9,
                    alignment: Alignment.center,
                    child: TextField(
                      controller: controllerPswd,
                      decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.grey),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.01,
                  ),
                  Text(pswdErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
                  SizedBox(
                    height: size.height * 0.015,
                  ),
                  Text(loginErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
                  SizedBox(
                    height: size.height * 0.05,
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
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
                                "Log In",
                                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 4),
                              Icon(IconsaxPlusLinear.login, color: Colors.black),
                            ],
                          )),
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
                                "Register",
                                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 4),
                              Icon(IconsaxPlusLinear.user_add, color: Colors.black),
                            ],
                          )),
                    ),
                  ]),
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
