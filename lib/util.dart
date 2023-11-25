import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;

class Helper {
  static const shift = (0xFF << 24);
  static Future<Image?> convertYUV420toImageColor(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;

      if (kDebugMode) {
        print("uvRowStride: $uvRowStride");
        print("uvPixelStride: $uvPixelStride");
      }
      imglib.Image img = imglib.Image(width: width, height: height);

      // Fill image buffer with plane[0] from YUV420_888
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex = (uvPixelStride ?? 0) * (x / 2).floor() +
              uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          // Calculate pixel color
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          // color: 0x FF  FF  FF  FF
          //           A   B   G   R
          if (img.isBoundsSafe(height - y, x)) {
            img.setPixelRgba(height - y, x, r, g, b, shift);
          }
        }
      }

      imglib.PngEncoder pngEncoder =
          imglib.PngEncoder(level: 0, filter: imglib.PngFilter.none);
      Uint8List png = pngEncoder.encode(img);
      return Image.memory(png);
    } catch (e) {
      if (kDebugMode) {
        print(">>>>>>>>>>>> ERROR:$e");
      }
    }
    return null;
  }
}
