import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../camera/camera_service.dart';
import '../logic/emotion_detector.dart';
import '../widget/box.dart';
import '../imageConvert.dart';
import '../main.dart';
import 'package:image/image.dart' as img;

class RealTimePage extends StatefulWidget {
  const RealTimePage({super.key});

  @override
  _RealTimePageState createState() => _RealTimePageState();
}

class _RealTimePageState extends State<RealTimePage> {
  CameraController? _controller;
  bool _isBusy = false;
  bool _isStreaming = false;
  List<Widget> _overlayWidgets = [];
  int _frameCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = await CameraService.initializeCamera(
        resolution: ResolutionPreset.low,
      );
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize camera: $e')),
      );
    }
  }

  @override
  void dispose() {
    _stopStreaming();
    _controller?.dispose();
    EmotionDetector.close();
    super.dispose();
  }

  Future<void> _toggleStreaming() async {
    if (_isBusy || _controller == null || !_controller!.value.isInitialized)
      return;
    setState(() => _isBusy = true);

    if (_isStreaming) {
      await _stopStreaming();
      setState(() {
        _isStreaming = false;
        _isBusy = false;
        _overlayWidgets = [];
      });
    } else {
      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mulai mendeteksi')));
        await CameraService.startStreaming(_controller!, _processImage);
        setState(() {
          _isStreaming = true;
          _isBusy = false;
        });
      } catch (e) {
        print('Error starting stream: $e');
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start streaming: $e')),
        );
      }
    }
  }

  Future<void> _stopStreaming() async {
    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await CameraService.stopStreaming(_controller!);
      }
    } catch (e) {
      print('Error stopping stream: $e');
    }
  }

  Future<void> _processImage(CameraImage cameraImg) async {
    _frameCounter++;
    if (_isBusy || _frameCounter % 3 != 0) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      print(
        'Processing frame: ${cameraImg.width}x${cameraImg.height}, format: ${cameraImg.format.group}',
      );
      final inputImage = CameraService.createInputImage(
        cameraImg,
        _controller!.description.sensorOrientation,
      );
      final faces = await EmotionDetector.detectFacesFromBytes(inputImage);

      final convertedImg = ImageUtils.convertCameraImage(cameraImg);
      if (convertedImg == null) {
        print('Failed to convert camera image');
        setState(() => _isBusy = false);
        return;
      }
      final rotationImg = img.copyRotate(
        convertedImg,
        angle: _controller!.description.sensorOrientation.toDouble(),
      );

      _overlayWidgets = [];
      if (faces.isNotEmpty) {
        final face = faces.first;
        final croppedImage = EmotionDetector.cropFace(rotationImg, face);
        final probabilities = await EmotionDetector.predictEmotion(
          croppedImage,
        );
        final maxIndex = EmotionDetector.getMaxIndex(probabilities);
        final label = facialLabel[maxIndex];

        _overlayWidgets.add(
          Box.square(
            x: face.boundingBox.left,
            y: face.boundingBox.top,
            side: face.boundingBox.bottom - face.boundingBox.top,
            ratio: MediaQuery.of(context).size.width / cameraImg.height,
            child: Positioned(
              top: -25,
              left: 0,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  backgroundColor: Colors.blue,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error processing image: $e');
      if (e.toString().contains('InputImageConverterError')) {
        print('Skipping frame due to unsupported image format');
      }
    }

    if (mounted) setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Detection')),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          ..._overlayWidgets,
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FloatingActionButton(
                onPressed: _isBusy ? null : _toggleStreaming,
                backgroundColor: Colors.white,
                child: Icon(_isStreaming ? Icons.stop : Icons.play_arrow, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
