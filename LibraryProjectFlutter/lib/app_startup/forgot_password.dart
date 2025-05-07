import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shelfswap/ui/colors.dart';
import 'package:shelfswap/ui/shared_widgets.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  bool showLoading = false;
  String emailErr = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
        title: const Text('Forgot Password'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 25),
                const Text(
                  'Enter your email address and we will send you a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                  },
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(129, 199, 132, 1),
                  ),
                  onPressed: () {
                    _resetPassword();
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Reset Password',
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Icon(IconsaxPlusLinear.arrow_right, color: Colors.black),
                    ],
                  ),
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
      ),
    );
  }

  void _resetPassword() async {
    String email = emailController.text.trim();
    emailErr = '';
    if (email == '') {
      emailErr = 'Required';
      setState(() {});
    } //
    else {
      setState(() {
        showLoading = true;
      });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        setState(() {
          showLoading = false;
        });
        if (mounted) {
          SharedWidgets.displayPositiveFeedbackDialog(context, 'Password Reset Email Sent');
        }
      } catch (e) {
        // print(e.toString());
        setState(() {
          showLoading = false;
          emailErr = 'Invalid Email';
        });
      }

    }
  }
}
