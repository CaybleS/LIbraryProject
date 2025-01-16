import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/create_account_screen.dart';
import 'package:library_project/app_startup/persistent_bottombar.dart';
import 'package:library_project/database/firebase_options.dart';
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

  User? user;

  @override
  void initState() {
    super.initState();

    initial();
    // signOutGoogle();
  }

  void initial() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseAuth auth = FirebaseAuth.instance;

    if (auth.currentUser != null) {
      user = auth.currentUser;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => PersistentBottomBar(user!)));
    }
  }

  void click() {
    signInWithGoogle().then((user) => {
          if (user != null)
            {
              this.user = user,
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => PersistentBottomBar(user))) // the bottombar will load the necessary pages when it exists
            }
        });
  }

  Widget googleLoginButton() {
    return OutlinedButton(
        onPressed: click,
        child: const Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(image: AssetImage('assets/google_logo.png'), height: 35),
                Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text('Sign in with Google',
                        style: TextStyle(color: Colors.grey, fontSize: 25)))
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
      User? user = await logIn(email, pswd);

      if (user == null) {
        loginErr = "Incorrect Email or Password";
        setState(() {});
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => PersistentBottomBar(user)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        // appBar: AppBar(
        //   backgroundColor: Colors.blue,
        // ),
        backgroundColor: Colors.grey[400],
        body: Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ),
              SizedBox(
                height: size.height * 0.01,
              ),
              Text(emailErr,
                  style: const TextStyle(fontSize: 20, color: Colors.red)),
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ),
              SizedBox(
                height: size.height * 0.01,
              ),
              Text(pswdErr,
                  style: const TextStyle(fontSize: 20, color: Colors.red)),
              SizedBox(
                height: size.height * 0.015,
              ),
              Text(loginErr,
                  style: const TextStyle(fontSize: 20, color: Colors.red)),
              SizedBox(
                height: size.height * 0.05,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(129, 199, 132, 1)),
                    onPressed: () => {loginBtnClicked()},
                    child: const Text(
                      "Log In",
                      style: TextStyle(color: Colors.black, fontSize: 22),
                    )),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(129, 199, 132, 1)),
                    onPressed: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CreateAccount()))
                        },
                    child: const Text(
                      "Create Account",
                      style: TextStyle(color: Colors.black, fontSize: 22),
                    )),
              ]),
              SizedBox(
                height: size.height * 0.025,
              ),
              googleLoginButton(),
            ],
          ),
        ));
  }
}
