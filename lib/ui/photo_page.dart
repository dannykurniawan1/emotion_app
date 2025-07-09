import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  final Map<String, IconData> _emotionIcons = {
    'Angry': FontAwesomeIcons.faceAngry,
    'Disgust': FontAwesomeIcons.faceDizzy,
    'Fear': FontAwesomeIcons.faceGrimace,
    'Happy': FontAwesomeIcons.faceLaugh,
    'Neutral': FontAwesomeIcons.faceMeh,
    'Sad': FontAwesomeIcons.faceSadTear,
    'Surprise': FontAwesomeIcons.faceSurprise,
  };

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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Menganalisis emosi...')));

    try {
      final savedImg = await CameraService.takePhoto(_controller!);
      final cameraImg = img.decodeJpg(await savedImg.readAsBytes())!;
      final result = await EmotionDetector.detectFaces(savedImg.path);

      if (result.isEmpty) {
        setState(() {
          _error = 'Tidak ada wajah yang terdeteksi.';
          _isBusy = false;
          _imageFile = File(savedImg.path);
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
        _error = null;
        _isBusy = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isBusy = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _imageFile = null;
      _probabilities = null;
      _error = null;
      _dominantEmotion = null;
      _isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambil Foto Emosi'),
        backgroundColor: Colors.black.withOpacity(
          0.3,
        ),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset('assets/Background.png', fit: BoxFit.cover),
          ),
          _imageFile == null ? _buildCameraPreview() : _buildResultContent(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(child: CameraPreview(_controller!)),
        if (_isBusy) const Center(child: CircularProgressIndicator()),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: FloatingActionButton(
              onPressed: _isBusy ? null : _takePhoto,
              backgroundColor: Colors.white,
              child: const Icon(Icons.camera_alt, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultContent() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Card(
            elevation: 8.0,
            color: Colors.black.withOpacity(0.65),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildResultImage(),
                  const SizedBox(height: 24),
                  if (_dominantEmotion != null) _buildDominantEmotionDisplay(),
                  if (_error != null) _buildErrorDisplay(),
                  const SizedBox(height: 16),
                  if (_probabilities != null) _buildEmotionProbabilityList(),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_enhance_rounded),
                    label: const Text('Ambil Foto Lagi'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _reset,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Image.file(_imageFile!, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _buildDominantEmotionDisplay() {
    final icon = _emotionIcons[_dominantEmotion!] ?? FontAwesomeIcons.question;
    return Column(
      children: [
        Text(
          'EMOSI TERDETEKSI',
          style: TextStyle(
            color: Colors.grey[300],
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        FaIcon(icon, size: 64, color: Colors.blueAccent),
        const SizedBox(height: 8),
        Text(
          _dominantEmotion!,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Divider(height: 32, color: Colors.white38),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        _error!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmotionProbabilityList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          facialLabel.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final probability = _probabilities![index];
            final isDominant = label == _dominantEmotion;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            isDominant ? FontWeight.bold : FontWeight.normal,
                        color: isDominant ? Colors.blueAccent : Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: LinearProgressIndicator(
                        value: probability,
                        minHeight: 12,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDominant ? Colors.blueAccent : Colors.grey[400]!,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${(probability * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight:
                            isDominant ? FontWeight.bold : FontWeight.normal,
                        color: isDominant ? Colors.blueAccent : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
