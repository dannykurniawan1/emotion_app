import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../camera/camera_service.dart';
import '../logic/emotion_detector.dart';
import '../main.dart';

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key});

  @override
  _PhotoPageState createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  CameraController? _controller;
  bool _isBusy = false;
  File? _imageFile;
  List<double>? _probabilities;
  String? _error;
  String? _dominantEmotion;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = await CameraService.initializeCamera();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _error = 'Failed to initialize camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_isBusy || _controller == null) return;
    setState(() => _isBusy = true);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Processing emotion...')));

    try {
      final savedImg = await CameraService.takePhoto(_controller!);
      final cameraImg = img.decodeJpg(await savedImg.readAsBytes())!;
      final result = await EmotionDetector.detectFaces(savedImg.path);

      if (result.isEmpty) {
        setState(() {
          _error = 'No face detected';
          _isBusy = false;
        });
        return;
      }

      final face = result.first;
      final croppedImg = EmotionDetector.cropFace(cameraImg, face);
      final probabilities = await EmotionDetector.predictEmotion(croppedImg);
      final maxIndex = EmotionDetector.getMaxIndex(probabilities);
      setState(() {
        _imageFile = File(savedImg.path);
        _probabilities = probabilities;
        _dominantEmotion = facialLabel[maxIndex];
        _isBusy = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Take Photo')),
      body:
          _imageFile == null
              ? Stack(
                children: [
                  CameraPreview(_controller!),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: FloatingActionButton(
                        onPressed: _isBusy ? null : _takePhoto,
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ),
                ],
              )
              : Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_dominantEmotion != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                'Detected Emotion: $_dominantEmotion',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (_imageFile != null)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    _imageFile!,
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (_probabilities != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  facialLabel.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final label = entry.value;
                                    final prob = _probabilities![index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: prob,
                                              backgroundColor: Colors.grey[300],
                                              color: Colors.blue,
                                              minHeight: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${(prob * 100).toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          const SizedBox(
                            height: 80,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _imageFile = null;
                            _probabilities = null;
                            _error = null;
                            _dominantEmotion = null;
                          });
                        },
                        child: const Text('Take Another Photo'),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
