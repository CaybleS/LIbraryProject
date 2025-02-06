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
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
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
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }

  static void displayErrorDialog(BuildContext context, String errorText) {
    showDialog(
    context: context,
    builder: (context) =>
      Dialog(
        child: Material(
          borderRadius: const BorderRadius.all(Radius.circular(25)), // dialog has a border, Material widget doesnt
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
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.acceptGreen,
                      padding: const EdgeInsets.all(8),
                    ),
                    child: const Text("Ok", style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // this is a warning dialog which has 2 options, 1 to return false, indicating a cancellation of the action, or true, indicating the
  // action should take place on the page which calls this function.
  static Future<bool> displayWarningDialog(BuildContext context, String warningText, String aintCareDoItAnywaysText) async {
    bool? retVal;
    retVal = await showDialog(
    context: context,
    builder: (context) =>
      Dialog(
        child: Material(
          borderRadius: const BorderRadius.all(Radius.circular(25)), // dialog has a border, Material widget doesnt
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Warning!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 15),
                    child: Text(
                    warningText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.cancelRed,
                          padding: const EdgeInsets.all(8),
                        ),
                        child: const Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.acceptGreen,
                          padding: const EdgeInsets.all(8),
                        ),
                        child: Text(aintCareDoItAnywaysText, style: const TextStyle(fontSize: 16, color: Colors.black)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return retVal ?? false;
  }

  static Future<bool> displayConfirmActionDialog(BuildContext context, String messageText) async {
    bool? retVal;
    retVal = await showDialog(
    context: context,
    builder: (context) => 
      Dialog(
        child: Material(
          borderRadius: const BorderRadius.all(Radius.circular(25)), // dialog has a border, Material widget doesnt
          child: Container(
            padding: const EdgeInsets.all(15),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Are you sure?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 15),
                    child: Text(
                    messageText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.cancelRed,
                          padding: const EdgeInsets.all(8),
                        ),
                        child: const Text(
                          "No!",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.acceptGreen,
                          padding: const EdgeInsets.all(8),
                        ),
                        child: const Text(
                          "Yes!",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return retVal ?? false;
  }

  static void displayPositiveFeedbackDialog(BuildContext context, String msgToShow) {
    bool hasPopped = false;
    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 750), () { // feel free to change duration as you see fit
          if (context.mounted && !hasPopped) {
            hasPopped = true;
            Navigator.pop(context);
          }
        });
        return Dialog( // this may make this longer since it overrides the child's set width, but it styles text in a way I like so
          child: Material(
            borderRadius: const BorderRadius.all(Radius.circular(25)), // dialog has a border, Material widget doesnt
            child: Container(
              height: 40,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    msgToShow,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.check,
                    color: AppColor.acceptGreen,
                    size: 35,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    // in cases where users click off this dialog, closing it, it can sometimes do 2 pops if they click off at a similar time as when it auto-pops; this prevents that
    ).then((_) {
      hasPopped = true;
    });
  }
}
