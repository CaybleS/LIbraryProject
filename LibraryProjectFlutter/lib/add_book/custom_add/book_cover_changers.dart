import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfswap/ui/shared_widgets.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

Future<XFile?> selectCoverFromFile(BuildContext context) async {
  try {
      XFile? inputCoverImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      return inputCoverImage;
  }
  on PlatformException catch (e) {
    if (e.code != "already_active" && context.mounted) {
      SharedWidgets.displayErrorDialog(context, "An unexpected error occurred. Please try again later.");
    }
  }
  catch (e) {
    if (context.mounted) {
      SharedWidgets.displayErrorDialog(context, "An unexpected error occurred. Please try again later.");
    }
  }
  return null;
}

Future<XFile?> selectCoverFromCamera(BuildContext context) async {
  try {
    XFile? inputCoverImage = await ImagePicker().pickImage(source: ImageSource.camera);
    return inputCoverImage;
  } on PlatformException catch (e) {
    if (!context.mounted) {
      return null;
    }
    if (e.code == "camera_access_denied") {
      SharedWidgets.displayErrorDialog(context, "Camera access denied. Please enable it in your device settings.");
    }
    else if (e.code != "already_active") {
      SharedWidgets.displayErrorDialog(context, "An unexpected error occurred. Please try again later.");
    }
  }
  catch (e) {
    if (context.mounted) {
      SharedWidgets.displayErrorDialog(context, "An unexpected error occurred. Please try again later.");
    }
  }
  return null;
}

Future<String?> uploadCoverToStorage(BuildContext context, XFile coverImage) async {
    try {
      File coverImageFile = File(coverImage.path);
      String coverImageFileName = const Uuid().v1();
      final Reference imageRef = FirebaseStorage.instance.ref().child('customBookCovers/$coverImageFileName');
      TaskSnapshot uploadTask = await imageRef.putFile(coverImageFile);
      if (uploadTask.state == TaskState.success) {
        String newCoverImageUrl = await uploadTask.ref.getDownloadURL();
        return newCoverImageUrl;
      }
      else {
        if (context.mounted) {
          SharedWidgets.displayErrorDialog(context, "Failed to set cover image");
        }
      }
    } on FirebaseException { // just in case better error handling should be added, im keeping this
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, "Failed to set cover image");
      }
    }
    catch (e) {
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, "Failed to set cover image");
      }
    }
    return null;
  }

  Future<void> deleteCoverFromStorage(String cloudCoverUrl) async {
    Reference storageRef = FirebaseStorage.instance.refFromURL(cloudCoverUrl);
    await storageRef.delete();
  }
