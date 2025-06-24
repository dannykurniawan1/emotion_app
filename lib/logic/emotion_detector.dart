import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../classifier.dart';
import '../preprocessing.dart';

class EmotionDetector {
  static EmotionDetector? _instance;
  static EmotionDetector get instance => _instance ??= EmotionDetector._();

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );
  final FaceDetector _fastDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );
  final Classifier _classifier = Classifier();

  EmotionDetector._();

  static Future<List<Face>> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return await instance._detector.processImage(inputImage);
  }

  static Future<List<Face>> detectFacesFromBytes(InputImage inputImage) async {
    return await instance._fastDetector.processImage(inputImage);
  }

  static img.Image cropFace(img.Image image, Face face) {
    final boundingBox = face.boundingBox;
    final faceRange = boundingBox.bottom - boundingBox.top;
    return img.copyCrop(
      image,
      x: boundingBox.left.toInt(),
      y: boundingBox.top.toInt(),
      width: faceRange.toInt(),
      height: faceRange.toInt(),
    );
  }

  static Future<List<double>> predictEmotion(img.Image image) async {
    await instance._classifier.loadModel(
      'assets/mobilenet_v1_inbalance.tflite',
    );
    if (instance._classifier.interpreter == null) {
      throw Exception('Failed to load model');
    }
    final resizedImg = img.copyResize(image, width: 224, height: 224);
    final input = ImagePrehandle.uint32ListToRGB3D(resizedImg);
    return instance._classifier.run([input]);
  }

  static int getMaxIndex(List<double> probabilities) {
    return instance._classifier.getMaxIndex(probabilities);
  }

  static void close() {
    instance._detector.close();
    instance._fastDetector.close();
  }
}
