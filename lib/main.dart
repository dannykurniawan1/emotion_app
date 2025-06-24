import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'ui/splash_screen.dart';
import 'ui/home_page.dart';
import 'ui/photo_page.dart';
import 'ui/realtime_page.dart';

const String facialModel = 'mobilenet_v1_inbalance.tflite';
const List<String> facialLabel = ['Angry', 'Disgust', 'Fear', 'Happy', 'Neutral', 'Sad', 'Surprise'];
CameraDescription? camera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/photo': (context) => const PhotoPage(),
        '/realtime': (context) => const RealTimePage(),
      },
    );
  }
}