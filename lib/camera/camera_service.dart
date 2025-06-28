import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'camera_controller.dart';

class CameraService {
  static Future<CameraController> initializeCamera({
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    return await CameraControllerManager.initializeCamera(
      resolution: resolution,
    );
  }

  static Future<XFile> takePhoto(CameraController controller) async {
    try {
      await controller.setFlashMode(FlashMode.off);
      return await controller.takePicture();
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  static Future<void> startStreaming(
    CameraController controller,
    void Function(CameraImage) callback,
  ) async {
    try {
      await controller.startImageStream(callback);
    } catch (e) {
      throw Exception('Failed to start streaming: $e');
    }
  }

  static Future<void> stopStreaming(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (e) {
      throw Exception('Failed to stop streaming: $e');
    }
  }

  static InputImage createInputImage(
    CameraImage cameraImg,
    int sensorOrientation,
  ) {
    try {
      // Di Android, format dari plugin `camera` hampir selalu YUV_420_888.
      // Plugin ML Kit paling andal bekerja dengan format NV21 di Android.
      if (defaultTargetPlatform != TargetPlatform.android) {
        // Jika Anda berencana mendukung iOS, perlu penanganan khusus di sini.
        throw Exception(
          'Real-time detection is only supported on Android for now.',
        );
      }

      // Gabungkan semua bytes dari semua plane menjadi satu buffer.
      // Sisi native dari plugin akan menggunakan metadata untuk mem-parsing buffer ini.
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in cameraImg.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageSize = Size(
        cameraImg.width.toDouble(),
        cameraImg.height.toDouble(),
      );

      final imageRotation = _getRotation(sensorOrientation);

      // **KUNCI PERBAIKAN**: Tentukan format sebagai NV21.
      final inputImageFormat = InputImageFormat.nv21;

      final bytesPerRow = cameraImg.planes[0].bytesPerRow;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: bytesPerRow,
      );

      print(
        'InputImage metadata: size=${inputImageData.size}, rotation=${inputImageData.rotation}, format=${inputImageData.format}, bytesPerRow=${inputImageData.bytesPerRow}',
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    } catch (e) {
      throw Exception('Failed to create InputImage: $e');
    }
  }

  static InputImageRotation _getRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        print(
          'Unknown sensor orientation: $sensorOrientation, defaulting to 0deg',
        );
        return InputImageRotation.rotation0deg;
    }
  }

  // Fungsi _getInputImageFormat tidak lagi diperlukan karena kita langsung menentukan NV21.
  // static InputImageFormat? _getInputImageFormat(ImageFormatGroup format) { ... }
}
