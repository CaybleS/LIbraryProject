import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'auth.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController rePasswordController = TextEditingController();

  String loginError = '';
  bool showLoading = false;
  bool showEmailVerificationText = false;
  bool _noNameInput = false;
  bool _noEmailInput = false;
  bool _emailNotCorrectInput = false;
  bool _noPasswordInput = false;
  bool _passwordNotMachInput = false;
  bool _passwordLenghtInput = false;
  static const int _maxDisplayNameLength = 20; // this is set here, and on profile, could move this variable accordingly if you change both of them
  bool _nameisMaxLength = false;

  @override
  void initState() {
    super.initState();
    nameController.addListener(() {
      if (_noNameInput && nameController.text.isNotEmpty) {
        setState(() {
          _noNameInput = false;
        });
      }
      if (_nameisMaxLength) {
        setState(() {
          _nameisMaxLength = false;
        });
      }
      if (!_nameisMaxLength && nameController.text.length == _maxDisplayNameLength) {
        setState(() {
          _nameisMaxLength = true;
        });
      }
    });
    emailController.addListener(() {
      if (_noEmailInput && emailController.text.isNotEmpty) {
        setState(() {
          _noEmailInput = false;
        });
      }
      if (_emailNotCorrectInput && RegExp(emailRegex).hasMatch(emailController.text)) {
        setState(() {
          _emailNotCorrectInput = false;
        });
      }
    });
    passwordController.addListener(() {
      if (_noPasswordInput && passwordController.text.isNotEmpty) {
        setState(() {
          _noPasswordInput = false;
        });
      }
      if (_passwordLenghtInput && passwordController.text.length >= 6) {
        setState(() {
          _passwordLenghtInput = false;
        });
      }
    });
    rePasswordController.addListener(() {
      if (_passwordNotMachInput && rePasswordController.text == passwordController.text) {
        setState(() {
          _passwordNotMachInput = false;
        });
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void createBtnClicked() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String rePassword = rePasswordController.text.trim();

    loginError = '';

    if (email.isEmpty) {
      _noEmailInput = true;
    }

    if (!RegExp(emailRegex).hasMatch(email)) {
      _emailNotCorrectInput = true;
    }
    if (password.isEmpty) {
      _noPasswordInput = true;
    }

    if (password != rePassword) {
      _passwordNotMachInput = true;
    }

    if (password.length < 6) {
      _passwordLenghtInput = true;
    }

    if (name.isEmpty) {
      _noNameInput = true;
    }

    if (_noEmailInput ||
        _noPasswordInput ||
        _noNameInput ||
        _emailNotCorrectInput ||
        _passwordNotMachInput ||
        _passwordLenghtInput) {
      setState(() {});
      return;
    }

    setState(() {
      showLoading = true;
    });
    User? user = await createAccount(name, email, password, context);

    if (user == null) {
      loginError = 'Problem with Login';
    } else {
      showEmailVerificationText = true;
    }
    setState(() {
      showLoading = false;
    });
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
                    controller: nameController,
                    maxLength: 20,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: 'Name',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      errorText: (_noNameInput || _nameisMaxLength) ? (_noNameInput ? "Required" : "You are at the 20-character limit") : null,
                      suffixIcon: IconButton(
                        onPressed: () {
                          nameController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      errorText: _noEmailInput
                          ? "Required"
                          : _emailNotCorrectInput
                              ? "Invalid Email"
                              : null,
                      suffixIcon: IconButton(
                        onPressed: () {
                          emailController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
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
                      errorText: _noPasswordInput
                          ? "Required"
                          : _passwordLenghtInput
                              ? "The passwords must be at least 6 characters long"
                              : null,
                      suffixIcon: IconButton(
                        onPressed: () {
                          passwordController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: rePasswordController,
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      errorText: _noPasswordInput
                          ? "Required"
                          : _passwordNotMachInput
                              ? "Password not match"
                              : null,
                      suffixIcon: IconButton(
                        onPressed: () {
                          rePasswordController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(loginError, style: const TextStyle(fontSize: 16, color: Colors.red)),
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
