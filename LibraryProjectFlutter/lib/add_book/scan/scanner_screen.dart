import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'; // using over mobile_scanner cuz its better! better user experience with this one! 3.5MB more tho
import 'package:image_picker/image_picker.dart';
import 'package:library_project/ui/colors.dart';
import 'package:library_project/ui/shared_widgets.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late CameraController _cameraController;
  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.ean8, BarcodeFormat.ean13],
  );
  bool _cameraIsInitialized = false; // to display progress indicator when initializing camera
  bool _isScanning = false; // to prevent overlapping scans
  bool _hasPopped = false; // prevents multiple pops which WILL happen because of how fast the scanner processes
  final Map<String, int> _isbnFrequencies = {};

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController.stopImageStream();
    _cameraController.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    List<CameraDescription> cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      // use either low or medium here, because higher scanning resolutions mean slower scans in general. I think low is best, but tweak this alongside the isbn frequencies
      // map to ensure the scanner accurately scans the barcode (fast scans + ensuring the first isbn to occur N times gets selected seems really solid)
      ResolutionPreset.low,
      enableAudio: false, // so it doesnt ask to record audio when opening camera
    );
    try {
      await _cameraController.initialize();
    }
    on CameraException catch (e) {
      if (e.code == "CameraAccessDenied" && mounted && !_hasPopped) {
        _hasPopped = true;
        // in this case I just return the error msg instead of an ISBN, and the scanner driver checks if the ISBN is this error message and prints an error if so
        Navigator.pop(context, "Camera access denied. Please enable it in your device settings.");
      }
      else if (mounted && !_hasPopped) {
        _hasPopped = true;
        Navigator.pop(context, "An unexpected error occurred. Please try again later.");
      }
    }
    catch (e) {
      if (mounted && !_hasPopped) {
        _hasPopped = true;
        Navigator.pop(context, "An unexpected error occurred. Please try again later.");
      }
    }
    _cameraIsInitialized = true;
    if (mounted) {
      setState(() {});
    }
    _openCamera();
  }

  void _processBarcodeValue(String? isbn) {
    if (isbn != null) {
      _isbnFrequencies[isbn] = (_isbnFrequencies[isbn] ?? 0) + 1; // new frequencies will be initialized to 0 and then incremented here
      if (_isbnFrequencies[isbn]! > 3 && mounted && !_hasPopped) { // cant guarantee with certainty that 3 is optimal, but its close to optimal at least
        _hasPopped = true;
        Navigator.pop(context, isbn);
      }
    }
  }

  void _openCamera() {
    _cameraController.startImageStream((CameraImage image) async {
      if (_isScanning) { // preventing overlapping scans
        return;
      }
      _isScanning = true;

      // converting camera's image stream into a single buffer of bytes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // using this bytes buffer to create an image to be processed internally by google mlkit
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.values[_cameraController.description.sensorOrientation ~/ 90],
        format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888, // nv21 format for android, bgra8888 format for ios
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
  
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        _processBarcodeValue(barcodes.first.rawValue);
      }
      _isScanning = false;
    });
  }

  Future<void> _analyzeImageFromFile() async {
    late XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.gallery);
    } on PlatformException catch (e) {
      if (e.code != "already_active" && mounted && !_hasPopped) {
        _hasPopped = true;
        Navigator.pop(context, "An unexpected error occurred. Please try again later.");
      }
    }
    catch (e) {
      if (mounted && !_hasPopped) {
        _hasPopped = true;
        Navigator.pop(context, "An unexpected error occurred. Please try again later.");
      }
    }
    if (!mounted || file == null) {
      return;
    }
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty && barcodes.first.rawValue != null && !_hasPopped && mounted) {
        _hasPopped = true;
        Navigator.pop(context, barcodes.first.rawValue);
      }
      else { // generally this just triggers when barcodes.isNotEmpty is false meaning the barcode is empty (no barcode found)
        if (mounted) {
          Navigator.pop(context, "No barcode found on image."); // signaling to scanner_driver that no barcode was found on the image
        }
      }
    } catch (e) { // dont know when this would trigger, might need another error for it idk
      if (mounted) {
        Navigator.pop(context, "No barcode found on image.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Barcode"),
        centerTitle: true,
        backgroundColor: AppColor.appbarColor,
      ),
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          _analyzeImageFromFile();
        },
        backgroundColor: AppColor.skyBlue,
        label: const Text(
          "Get Barcode From Photos",
          style: TextStyle(fontSize: 16),
        ),
        icon: const Icon(
          Icons.photo,
          size: 30,
        ),
        splashColor: Colors.blue,
      ),
      body: (_cameraIsInitialized)
        ? Stack(
            alignment: AlignmentDirectional.center,
            children: [
              CameraPreview(_cameraController),
              Container(
                width: 250,
                height: 150,
                decoration: BoxDecoration(border: Border.all(color: Colors.red, width: 2)),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.topCenter,
              child: SharedWidgets.displayCircularProgressIndicator(),
            ),
          ),
    );
  }
}
