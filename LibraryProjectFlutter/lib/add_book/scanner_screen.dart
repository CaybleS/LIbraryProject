// this is the actual page which will, when opened, just shows the camera, and when the barcode is found it pops out of here

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool hasPopped = false;

  void _handleBarcode(BarcodeCapture barcodes) {
    Barcode? barcode = barcodes.barcodes.firstOrNull;
    // When would the barcode be null? I have no clue! But if so, it sets the ISBN to "no barcode found", and the search with this
    // will return nothing.
    // TODO is there error handling logic if the ISBN search returns nothing? I have no idea!
    String returnBarcodeText = barcode?.displayValue ?? "no barcode found";
    if (!hasPopped) {
      hasPopped = true;
      Navigator.pop(context, returnBarcodeText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.red, // TODO change from red eventually, i just have it this way so i can tell whats happening
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
        ],
      ),
    );
  }
}
