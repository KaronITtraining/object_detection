import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(home: ObjectDetectionApp(cameras: cameras)));
}

class ObjectDetectionApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  ObjectDetectionApp({required this.cameras});

  @override
  _ObjectDetectionAppState createState() => _ObjectDetectionAppState();
}

class _ObjectDetectionAppState extends State<ObjectDetectionApp> {
  late CameraController _cameraController;
  bool isCameraInitialized = false;
  String result = "";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() async {
    _cameraController = CameraController(widget.cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() => isCameraInitialized = true);
  }

  Future<void> _captureAndDetect() async {
    try {
      final XFile imageFile = await _cameraController.takePicture();
      final File image = File(imageFile.path);
      await _processImage(image);
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _processImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final ImageLabeler labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
    final List<ImageLabel> labels = await labeler.processImage(inputImage);

    String detectedObjects = "";
    for (ImageLabel label in labels) {
      final String text = label.label;
      final double confidence = label.confidence;
      detectedObjects += "$text (${(confidence * 100).toStringAsFixed(2)}%)\n";
      //break;
    }

    labeler.close();
    setState(() => result = detectedObjects);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Object Detection')),
      body: Column(
        children: [
          isCameraInitialized
              ? AspectRatio(
            aspectRatio: _cameraController.value.aspectRatio,
            child: CameraPreview(_cameraController),
          )
              : CircularProgressIndicator(),
          ElevatedButton(
            onPressed: _captureAndDetect,
            child: Text('Capture and Detect'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Text(result, style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
