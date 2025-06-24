import 'package:camera/camera.dart';
import '../main.dart';

class CameraControllerManager {
  static Future<CameraController> initializeCamera({
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    try {
      final controller = CameraController(camera!, resolution);
      await controller.initialize();
      return controller;
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }
}
