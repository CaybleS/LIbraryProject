import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelfswap/storage/aws_s3.dart';
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

// Updated for S3
Future<String?> uploadCoverToStorage(BuildContext context, XFile coverImage) async {
    try {
      File coverImageFile = File(coverImage.path);
      String coverImageFileName = const Uuid().v1();

      String response = await uploadImage(context, coverImageFileName, coverImageFile);
      String s3Base = "https://shelfswap.s3.amazonaws.com";

      if (response == "good") {
        return "$s3Base/$coverImageFileName";
      } else {
        if (context.mounted) {
          SharedWidgets.displayErrorDialog(context, "Failed to set cover image");
        }
      }
    }
    catch (e) {
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, "Failed to set cover image");
      }
    }
    return null;
  }

// Updated to account for deleting from firebase and s3
  Future<void> deleteCoverFromStorage(String cloudCoverUrl) async {
    String s3Base = "https://shelfswap.s3.amazonaws.com";
    if (cloudCoverUrl.startsWith(s3Base)) {
        await deleteImage(cloudCoverUrl);
    } else {
      Reference storageRef = FirebaseStorage.instance.refFromURL(cloudCoverUrl);
      await storageRef.delete();
    }
  }
