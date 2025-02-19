import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';
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

  String nameErr = '';
  String emailErr = '';
  String pswdErr = '';
  String loginErr = '';
  bool showLoading = false;
  bool showEmailVerificationText = false;

  void createBtnClicked() async {
    String name = nameCtrl.text.trim();
    String email = emailCtrl.text.trim();
    String pswd = passwordCtrl.text.trim();
    emailErr = '';
    pswdErr = '';
    nameErr = '';

    if (email == '') {
      emailErr = 'Required';
      setState(() {});
    }

    if (pswd == '') {
      pswdErr = 'Required';
      setState(() {});
    }

    if (name == '') {
      nameErr = 'Required';
      setState(() {});
    }

    if (email != '' && pswd != '' && name != '') {
      setState(() {
        showLoading = true;
      });
      User? user = await createAccount(name, email, pswd);

      if (user == null) {
        loginErr = 'Problem with Login';
      }
      setState(() {
        showLoading = false;
        showEmailVerificationText = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.appbarColor,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(IconsaxPlusLinear.arrow_left_1, color: Colors.white, size: 30),
          ),
          title: const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  TextField(
                    controller: nameCtrl,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                        hintText: 'Display Name',
                        hintStyle: const TextStyle(color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 10),
                  Text(nameErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
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
                    controller: passwordCtrl,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    style: const TextStyle(fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 10),
                  Text(pswdErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
                  const SizedBox(height: 10),
                  Text(loginErr, style: const TextStyle(fontSize: 20, color: Colors.red)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
                    ),
                    onPressed: () {
                      createBtnClicked();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(IconsaxPlusLinear.user_add, color: Colors.black),
                      ],
                    ),
                  ),
                  if (showEmailVerificationText) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: const Text(
                        'Verification email sent! Please check your inbox and follow the link to verify your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
