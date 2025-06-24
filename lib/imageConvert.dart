import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  static img.Image? convertCameraImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        final int width = cameraImage.width;
        final int height = cameraImage.height;
        final int uvRowStride = cameraImage.planes[1].bytesPerRow;
        final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

        final yuvImage = img.Image(width: width, height: height);
        final yBuffer = cameraImage.planes[0].bytes;
        final uBuffer = cameraImage.planes[1].bytes;
        final vBuffer = cameraImage.planes[2].bytes;

        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final int uvIndex =
                uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
            final int index = y * width + x;

            final yp = yBuffer[index];
            final up = uBuffer[uvIndex];
            final vp = vBuffer[uvIndex];

            int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
            int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
                .round()
                .clamp(0, 255);
            int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

            yuvImage.setPixelRgb(x, y, r, g, b);
          }
        }
        return yuvImage;
      } else {
        print('Unsupported format: ${cameraImage.format.group}');
        return null;
      }
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }
}
