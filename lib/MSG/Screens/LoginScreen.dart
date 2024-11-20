import 'package:flutter/material.dart';
import 'package:library_project/LIB/homepage.dart';
import 'package:library_project/MSG/Screens/MSG/HomeScreen.dart';

import '../Core/Accounting/CreateAccount.dart';
import '../Core/Accounting/LoginWithGoogleAccount.dart';
import '../Widgets/GoogleLoginButton_Widget.dart';
import 'MSG/CreateAccountScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false;


  @override
  void initState() {
    super.initState();
    signOutGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: isLoading
          ? Center(
        child: Container(
          alignment: Alignment.center,
          width: size.height / 20,
          height: size.height / 20,
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: size.height / 20),
            Container(
              alignment: Alignment.centerLeft,
              width: size.width / 1.05,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_back_ios),
              ),
            ),
            SizedBox(
              height: size.height / 50,
            ),
            Container(
              alignment: Alignment.centerLeft,
              width: size.width / 1.1,
              child: const Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              width: size.width / 1.1,
              child: const Text(
                "Sign In to Continue!",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              height: size.height / 10,
            ),
            Container(
              width: size.width,
              alignment: Alignment.center,
              child: field(size, "email", Icons.email, _email),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0),
              child: Container(
                width: size.width,
                alignment: Alignment.center,
                child: field(size, "password", Icons.lock, _password),
              ),
            ),
            SizedBox(
              height: size.height / 10,
            ),
            customButton(size),
            SizedBox(
              height: size.height / 40,
            ),
            googleLoginButtonWidget(loginClick),
            SizedBox(
              height: size.height / 40,
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CreateAccount())),
              child: const Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget customButton(Size size) {
    return GestureDetector(
      onTap: () {
        if (_email.text.isNotEmpty && _password.text.isNotEmpty) {
          setState(() {
            isLoading = true;
          });
          logIn(_email.text, _password.text).then((user) {
            if (user != null) {
              debugPrint("Login Success");
              setState(() {
                isLoading = false;
              });
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => HomePage(user)));
            } else {
              debugPrint("Login Failed");
            }
          });
        } else {
          debugPrint("Please Fill form Correctly");
        }
      },
      child: Container(
        height: size.height / 14,
        width: size.width / 1.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue,
        ),
        alignment: Alignment.center,
        child: const Text(
          "Login",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

//*********************************** Widgets

Widget field(Size size, String hintTxt, IconData icon,
    TextEditingController controllerBtn) {
  return Container(
    alignment: Alignment.center,
    height: size.height / 15,
    width: size.width / 1.08,
    child: TextField(
      controller: controllerBtn,
      decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hintTxt,
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
    ),
  );
}
