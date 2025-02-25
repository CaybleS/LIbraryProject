import 'package:flutter/material.dart';
import 'package:library_project/Social/friends/friend_scanner_screen.dart';
import 'package:library_project/core/global_variables.dart';
import 'package:library_project/ui/shared_widgets.dart';

// This is just a simplified version of the isbn scanner

class FriendScannerDriver {
  bool _otherSearchError = false;
  bool _noBooksFoundError = false; // this only occurs if no results occur from the successful (200) search query, implying that the scanned ISBN is wrong (likely due to bad barcode)
  bool _cameraSetupError = false;
  bool _noResponseError = false; // this detects lack of internet connection (or api being down maybe)
  bool _invalidIDError = false;
  bool _invalidQRcodePhotoError = false;
  bool _unknownScannerScreenError = false; // no idea what would trigger this, its a mystery to me (unknown)

  FriendScannerDriver();

  Future<String?> runScanner(BuildContext context) async {
    _resetLastScanValues();
    String? scannedID = await _openBarcodeScanner(context);
    if (scannedID == "Camera access denied. Please enable it in your device settings.") {
      scannedID = null;
      _cameraSetupError = true;
    }
    if (scannedID == "No QR code found on image.") {
      scannedID = null;
      _invalidQRcodePhotoError = true;
    }
    if (scannedID == "An unexpected error occurred. Please try again later.") {
      scannedID = null;
      _unknownScannerScreenError = true;
    }
    // uids can be 1-128 chars long
    if (scannedID != null && scannedID.length > 128) {
      _invalidIDError = true;
    }
    if (_cameraSetupError || _invalidIDError || _invalidQRcodePhotoError || _unknownScannerScreenError) {
      String errorMessage = _getScanFailMessage();
      if (context.mounted) {
        SharedWidgets.displayErrorDialog(context, errorMessage);
      }
      return null;
    }
    if (scannedID == null) {
      return null;
    }
    return scannedID;
  }

  void _resetLastScanValues() {
    _otherSearchError = false;
    _noBooksFoundError = false;
    _cameraSetupError = false;
    _noResponseError = false;
    _invalidIDError = false;
    _invalidQRcodePhotoError = false;
    _unknownScannerScreenError = false;
  }

  Future<String?> _openBarcodeScanner(BuildContext context) async {
    // isbn can be null if user goes back from camera viewfinder without scanning
    showBottombar = false;
    refreshBottombar.value = true;
    final String? id = await Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendScannerScreen()));
    showBottombar = true;
    refreshBottombar.value = true;
    return id;
  }

  String _getScanFailMessage() {
    if (_cameraSetupError) {
      return "Camera access denied. Please enable it in your device settings.";
    }
    if (_noBooksFoundError) {
      return "The scanner couldn't identify the book. Likely due to poor lighting, an unclear camera angle, or a damaged QR code.";
    }
    if (_invalidIDError) {
      return "The ISBN is invalid. You may be scanning an incorrect type of QR code.";
    }
    if (_noResponseError) {
      return "No response received. This may be due to internet connection issues or the service being temporarily unavailable.";
    }
    if (_invalidQRcodePhotoError) {
      return "There was no QR code found on this image. It may be too small for the scanner to detect.";
    }
    if (_unknownScannerScreenError) {
      return "An unexpected error occurred. Please try again later.";
    }
    if (_otherSearchError) { // IMPORTANT: in general otherSearchError should be the last explicit error (the lowest priority scan-fail to show to the user)
      return "An unexpected error occurred while scanning the QR code. Please try again later.";
    }
    return "";
  }
}
