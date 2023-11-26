import 'dart:math';

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
          if (img.isBoundsSafe(height - 1 - y, x)) {
            img.setPixelRgba(height - 1 - y, x, r, g, b, shift);
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

  static Future<Image?> getRGBimage({int height = 4, int width = 4}) async {
    try {
      imglib.Image img = imglib.Image(width: width, height: height);
      // Fill image buffer with plane[0] from YUV420_888
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          int r, g, b;
          if (x == 0 && y == 0) {
            r = 255;
            g = 255;
            b = 255;
          } else if (x == width - 1 && y == 0) {
            r = 255;
            g = 0;
            b = 0;
          } else if (x == width - 1 && y == width - 1) {
            r = 0;
            g = 255;
            b = 0;
          } else if (x == 0 && y == width - 1) {
            r = 0;
            g = 0;
            b = 255;
          } else {
            // Calculate pixel color
            r = Random().nextInt(255);
            g = Random().nextInt(255);
            b = Random().nextInt(255);
          }
          // color: 0x FF  FF  FF  FF
          //           A   B   G   R
          if (img.isBoundsSafe(height - 1 - y, x)) {
            img.setPixelRgba(height - 1 - y, x, r, g, b, shift);
          }
        }
      }

      imglib.PngEncoder pngEncoder =
          imglib.PngEncoder(level: 0, filter: imglib.PngFilter.none);
      Uint8List png = pngEncoder.encode(img);
      return Image.memory(
        png,
        filterQuality: FilterQuality.none,
      );
    } catch (e) {
      if (kDebugMode) {
        print(">>>>>>>>>>>> ERROR:$e");
      }
    }
    return null;
  }
}
