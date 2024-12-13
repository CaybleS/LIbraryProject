import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late CameraController cameraController;
  final BarcodeScanner barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.ean8, BarcodeFormat.ean13], // note that isbn10 is not supported by these formats. TODO Need to test isbn10 books and see if other formats support it
  );
  bool cameraIsInitialized = false; // to display progress indicator when initializing camera
  bool isScanning = false; // to prevent overlapping scans
  bool hasPopped = false; // prevents multiple pops which WILL happen because of how fast the scanner processes
  final Map<String, int> isbnFrequencies = {};

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    cameraController.stopImageStream();
    cameraController.dispose();
    barcodeScanner.close();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    List<CameraDescription> cameras = await availableCameras();
    cameraController = CameraController(
      cameras.first,
      // use either low or medium here, because higher scanning resolutions mean slower scans in general. I think low is best, but tweak this alongside the isbn frequenies
      // map to ensure the scanner accurately scans the barcode (fast scans + ensuring the first isbn to occur N times gets selected seems really solid)
      ResolutionPreset.low,
      enableAudio: false, // so it doesnt ask to record audio when opening camera
    );
    try {
      await cameraController.initialize();
    }
    catch(e) {
      if (mounted && !hasPopped) {
        hasPopped = true;
        // in this case I just return the error msg instead of an ISBN, and the scanner driver checks if the ISBN is this error message and prints an error if so
        Navigator.pop(context, "Camera setup failed. Please ensure permissions are setup correctly.");
      }
    }
    cameraIsInitialized = true;
    if (mounted) {
      setState(() {});
    }
    openCamera();
  }

  void processBarcodeValue(String? isbn) {
    if (isbn != null) {
      isbnFrequencies[isbn] = (isbnFrequencies[isbn] ?? 0) + 1; // new frequnecies will be initialized to 0 and then incremented here
      if (isbnFrequencies[isbn]! > 3 && mounted && !hasPopped) {
        hasPopped = true;
        Navigator.pop(context, isbn);
      }
    }
  }

  void openCamera() {
    cameraController.startImageStream((CameraImage image) async {
      if (isScanning) { // preventing overlapping scans
        return;
      }
      isScanning = true;

      // converting camera's image stream into a single buffer of bytes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // using this bytes buffer to create an image to be processed internally by google mlkit
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.values[cameraController.description.sensorOrientation ~/ 90],
        format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888, // nv21 format for android, bgra8888 format for ios
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
  
      final barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        processBarcodeValue(barcodes.first.rawValue);
      }
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        backgroundColor: Colors.blue,
      ),
      body: (cameraIsInitialized)
        ? Stack(
            children: [
              CameraPreview(cameraController),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 350,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          )
        : const Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.topCenter,
              child: CircularProgressIndicator(
                color: Colors.deepPurpleAccent,
                backgroundColor: Colors.grey,
                strokeWidth: 5.0,
              ),
            ),
          ],
        ),
    );
  }
}
