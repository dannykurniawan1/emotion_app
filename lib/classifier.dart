import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  Interpreter? _interpreter;
  List<int>? _inputShape;
  List<int>? _outputShape;

  Interpreter? get interpreter => _interpreter;
  List<int>? get inputShape => _inputShape;
  List<int>? get outputShape => _outputShape;

  Future<Interpreter?> loadModel(String path) async {
    try {
      if (_interpreter != null) return _interpreter;
      print('Loading model: $path');
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenet_v1_inbalance.tflite',
      );
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      print('Model loaded successfully');
      return _interpreter;
    } catch (e) {
      print('Failed to load model: $e');
      print('Attempting to load asset: $path');
      return null;
    }
  }

  List<double> run(List input) {
    var output = List.filled(
      _outputShape!.fold(1, (prev, e) => prev * e),
      0.0,
    ).reshape(_outputShape!);
    _interpreter!.run(input, output);
    return output[0]; // Mengembalikan array probabilitas
  }

  int getMaxIndex(List<double> probabilities) {
    if (probabilities.isEmpty) return -1;
    int maxIndex = 0;
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[maxIndex]) {
        maxIndex = i;
      }
    }
    return maxIndex;
  }
}
