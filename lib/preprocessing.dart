import 'package:image/image.dart' as img;

class ImagePrehandle {
  static List<List<List<double>>> uint32ListToRGB3D(img.Image src) {
    final rgb = <List<List<double>>>[];
    for (int i = 0; i < src.height; i++) {
      final row = <List<double>>[];
      for (int j = 0; j < src.width; j++) {
        final pixel = src.getPixel(j, i);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;
        row.add([r, g, b]);
      }
      rgb.add(row);
    }
    return rgb;
  }
}
