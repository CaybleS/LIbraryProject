import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
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

  String loginErr = '';
  bool showLoading = false;
  bool showEmailVerificationText = false;
  bool _noNameInput = false;
  bool _noEmailInput = false;
  bool _noPasswordInput = false;

  @override
  void initState() {
    super.initState();
    nameCtrl.addListener(() {
      if (_noNameInput && nameCtrl.text.isNotEmpty) {
        setState(() {
          _noNameInput = false;
        });
    }});
    emailCtrl.addListener(() {
      if (_noEmailInput && emailCtrl.text.isNotEmpty) {
        setState(() {
          _noEmailInput = false;
        });
    }});
    passwordCtrl.addListener(() {
      if (_noPasswordInput && passwordCtrl.text.isNotEmpty) {
        setState(() {
          _noPasswordInput = false;
        });
    }});
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  void createBtnClicked() async {
    String name = nameCtrl.text.trim();
    String email = emailCtrl.text.trim();
    // TODO is it problematic to trim a password or no? Also login page doesnt trim the passowrd input
    String pswd = passwordCtrl.text.trim();

    if (email == '') {
      _noEmailInput = true;
    }

    if (pswd == '') {
      _noPasswordInput = true;
    }

    if (name == '') {
      _noNameInput = true;
    }

    if (_noEmailInput || _noPasswordInput  || _noNameInput) {
      setState(() {});
    }

    if (email != '' && pswd != '' && name != '') {
      setState(() {
        showLoading = true;
      });
      User? user = await createAccount(name, email, pswd, context);

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
            child: const Icon(Icons.arrow_back),
          ),
          title: const Text(
            'Create Account',
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
                    decoration: InputDecoration(
                        hintText: 'Name',
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        errorText: _noNameInput ? "Required" : null,
                        suffixIcon: IconButton(
                          onPressed: () {
                            nameCtrl.clear();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailCtrl,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        errorText: _noEmailInput ? "Required" : null,
                          suffixIcon: IconButton(
                            onPressed: () {
                              emailCtrl.clear();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordCtrl,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    obscureText: true,
                    decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        errorText: _noPasswordInput ? "Required" : null,
                        suffixIcon: IconButton(
                          onPressed: () {
                            passwordCtrl.clear();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                    ),
                  ),
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
