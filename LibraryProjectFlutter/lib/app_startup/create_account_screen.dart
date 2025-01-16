import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:library_project/app_startup/persistent_bottombar.dart';
import 'auth.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  String nameErr = "";
  String emailErr = "";
  String pswdErr = "";
  String loginErr = "";

  void createBtnClicked() async {
    String name = nameCtrl.text;
    String email = emailCtrl.text;
    String pswd = passwordCtrl.text;
    emailErr = "";
    pswdErr = "";
    nameErr = "";

    if (email == "") {
      emailErr = "Required";
      setState(() {});
    }

    if (pswd == "") {
      pswdErr = "Required";
      setState(() {});
    }

    if (name == "") {
      nameErr = "Required";
      setState(() {});
    }

    if (email != "" && pswd != "" && name != "") {
      User? user = await createAccount(name, email, pswd);

      if (user == null) {
        loginErr = "Problem with Login";
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
        appBar: AppBar(
          backgroundColor: Colors.blue,
        ),
        backgroundColor: Colors.grey[400],
        body: Align(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),
              Container(
                alignment: Alignment.center,
                width: size.width * 0.9,
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),
              Container(
                width: size.width * 0.9,
                alignment: Alignment.center,
                child: TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                      hintText: 'Display Name',
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
              Text(nameErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
              SizedBox(
                height: size.height * 0.01,
              ),
              Container(
                width: size.width * 0.9,
                alignment: Alignment.center,
                child: TextField(
                  controller: emailCtrl,
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
              Text(emailErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
              SizedBox(
                height: size.height * 0.01,
              ),
              Container(
                width: size.width * 0.9,
                alignment: Alignment.center,
                child: TextField(
                  controller: passwordCtrl,
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
              Text(pswdErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
              SizedBox(
                height: size.height * 0.01,
              ),
              Text(loginErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
              SizedBox(
                height: size.height * 0.015,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(129, 199, 132, 1)),
                  onPressed: () => {createBtnClicked()},
                  child: const Text(
                    "Create Account",
                    style: TextStyle(color: Colors.black, fontSize: 22),
                  )),
            ],
          ),
        ));
  }
}
