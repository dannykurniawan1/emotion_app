import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
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
      print(
        'Creating InputImage: width=${cameraImg.width}, height=${cameraImg.height}, format=${cameraImg.format.group}',
      );

      final yPlane = cameraImg.planes[0].bytes;
      final uPlane = cameraImg.planes[1].bytes;
      final vPlane = cameraImg.planes[2].bytes;

      print(
        'Y plane length: ${yPlane.length}, U plane length: ${uPlane.length}, V plane length: ${vPlane.length}',
      );

      // Gabungkan data byte dari semua plane
      final expectedUVLength = (cameraImg.width * cameraImg.height) ~/ 4;
      if (uPlane.length != expectedUVLength ||
          vPlane.length != expectedUVLength) {
        print('Adjusting U and V plane lengths to $expectedUVLength');
        final adjustedU = Uint8List(expectedUVLength)
          ..setRange(0, uPlane.length, uPlane);
        final adjustedV = Uint8List(expectedUVLength)
          ..setRange(0, vPlane.length, vPlane);
        final bytes = Uint8List.fromList(yPlane + adjustedU + adjustedV);
        print('Adjusted bytes length: ${bytes.length}');

        final rotation = _getRotation(sensorOrientation);
        final metadata = InputImageMetadata(
          size: Size(cameraImg.width.toDouble(), cameraImg.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.yuv420,
          bytesPerRow: cameraImg.planes[0].bytesPerRow,
        );

        print(
          'InputImage metadata: size=${metadata.size}, rotation=${metadata.rotation}, format=${metadata.format}, bytesPerRow=${metadata.bytesPerRow}',
        );

        return InputImage.fromBytes(bytes: bytes, metadata: metadata);
      } else {
        final bytes = Uint8List.fromList(yPlane + uPlane + vPlane);
        final rotation = _getRotation(sensorOrientation);
         final format = _getInputImageFormat(cameraImg.format.group);
        final metadata = InputImageMetadata(
          size: Size(cameraImg.width.toDouble(), cameraImg.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: cameraImg.planes[0].bytesPerRow,
        );

        print(
          'InputImage metadata: size=${metadata.size}, rotation=${metadata.rotation}, format=${metadata.format}, bytesPerRow=${metadata.bytesPerRow}',
        );

        return InputImage.fromBytes(bytes: bytes, metadata: metadata);
      }
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

  static InputImageFormat _getInputImageFormat(ImageFormatGroup format) {
    switch (format) {
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      default:
        throw Exception('Unsupported image format: $format');
    }
  }
}
