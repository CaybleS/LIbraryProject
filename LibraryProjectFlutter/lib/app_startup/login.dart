import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:library_project/app_startup/create_account_screen.dart';
import 'package:library_project/app_startup/persistent_bottombar.dart';
import 'package:library_project/ui/colors.dart';
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
  String emailErr = '';
  String pswdErr = '';
  String loginErr = '';
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
      if (auth.currentUser != null && auth.currentUser!.emailVerified) {
        user = auth.currentUser;
        changeStatus(true);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PersistentBottomBar(user!)));
      }
    });
  }

  void click() async {
    setState(() {
      showLoading = true;
    });
    final user = await signInWithGoogle();
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
                  fontFamily: 'Poppins',
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
    emailErr = '';
    pswdErr = '';
    loginErr = '';

    if (email == '') {
      emailErr = 'Required';
      setState(() {});
    }

    if (pswd == '') {
      pswdErr = 'Required';
      setState(() {});
    }

    if (email != '' && pswd != '') {
      setState(() {
        showLoading = true;
      });
      Map<String, dynamic> userLogin = await logIn(email, pswd);

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
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
          // actions: [
          //  TODO: add app logo
          // ],
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
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Text(
                    'Please Sign In',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: controllerEmail,
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: const TextStyle(color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 10),
                  Text(emailErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controllerPswd,
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(pswdErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
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
                                  fontFamily: 'Poppins',
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
                                  fontFamily: 'Poppins',
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
