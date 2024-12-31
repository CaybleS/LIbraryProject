import 'package:flutter/material.dart';
import 'package:library_project/ui/colors.dart';

class SharedWidgets {
  SharedWidgets._(); // prevents class instantiation

  static Widget displayCircularProgressIndicator() {
    return const CircularProgressIndicator(
      color: AppColor.darkBlue,
      backgroundColor: AppColor.blue,
      strokeWidth: 5.0,
    );
  }

  // The isInputInvalid flag is meant to show a "no input" error, managed by the page which calls this function. If you
  // want more advanced input validation beyond just no input checks I recommend Form and TextFormField widgets rather
  // than using this. Also if input is always valid just pass in false.
  static Widget displayTextField(String hintText, TextEditingController controller, bool isInputInvalid, String invalidInputText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        errorText: isInputInvalid ? invalidInputText : null,
        suffixIcon: IconButton(
          onPressed: () {
            controller.clear(); // clears the page's controller since dart passes objects by reference
          },
          icon: const Icon(Icons.clear),
        ),
      ),
    );
  }

  static void displayErrorDialog(BuildContext context, String errorText) {
    showDialog(
    context: context,
    builder: (context) =>
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min, // this allows the errorText length to dynamically increase the size of the popup
            children: [
              const Text(
                "Error!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 15),
                  child: Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.skyBlue,
                  ),
                  child: const Text("Ok", style: TextStyle(fontSize: 16, color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
