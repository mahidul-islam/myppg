// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;

class Helper {
  /// By default, the CameraImage format for Android and iOS are different.
  /// Android: ImageFormatGroup.yuv420
  /// iOS: ImageFormatGroup.bgra8888
  /// We need to handle them respectively.

  static const shift = (0xFF << 24);

  static Future<Uint8List> getUint8ListFromCameraImage(
      CameraImage image) async {
    if (Platform.isAndroid) {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;

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
      return pngEncoder.encode(img);
    } else if (Platform.isIOS) {
      final plane = image.planes[0];
      imglib.Image img = imglib.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: plane.bytes.buffer,
        rowStride: plane.bytesPerRow,
        bytesOffset: IOS_BYTES_OFFSET,
        order: imglib.ChannelOrder.bgra,
      );
      imglib.PngEncoder pngEncoder =
          imglib.PngEncoder(level: 0, filter: imglib.PngFilter.none);
      return pngEncoder.encode(img);
    } else {
      return Uint8List.fromList([]);
    }
  }

  static Future<Image?> convertYUV420toImageColor(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;

      // if (kDebugMode) {
      //   print("uvRowStride: $uvRowStride");
      //   print("uvPixelStride: $uvPixelStride");
      // }
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

  static const IOS_BYTES_OFFSET = 28;

  static Future<Image?> convertBGRA8888ToImage(CameraImage cameraImage) async {
    final plane = cameraImage.planes[0];
    imglib.Image img = imglib.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: plane.bytes.buffer,
      rowStride: plane.bytesPerRow,
      bytesOffset: IOS_BYTES_OFFSET,
      order: imglib.ChannelOrder.bgra,
    );
    imglib.PngEncoder pngEncoder =
        imglib.PngEncoder(level: 0, filter: imglib.PngFilter.none);
    Uint8List png = pngEncoder.encode(img);
    return Image.memory(png);
  }

  static List<imglib.Image>? splitImage(Uint8List input) {
    const int split = 4;
    // convert image to image from image package
    imglib.Image? image = imglib.decodeImage(input);

    if (image == null) {
      return null;
    }

    int x = 0, y = 0;
    int width = (image.width / split).floor();
    int height = (image.height / split).floor();

    // split image to parts
    List<imglib.Image> parts = <imglib.Image>[];
    for (int i = 0; i < split; i++) {
      for (int j = 0; j < split; j++) {
        parts.add(
            imglib.copyCrop(image, x: x, y: y, width: width, height: height));
        x += width;
      }
      x = 0;
      y += height;
    }

    // // convert image from image package to Image Widget to display
    // List<Image> output = <Image>[];
    // for (var img in parts) {
    //   output.add(Image.memory(imglib.encodeJpg(img)));
    // }

    return parts;
  }

  Future<List<List<List<int>>>> getRGBOnArrays(String asset) async {
    final Uint8List inputImg =
        (await rootBundle.load(asset)).buffer.asUint8List();
    // Assuming Jpg image
    final imglib.JpegDecoder decoder = imglib.JpegDecoder();
    final imglib.Image? decodedImg = decoder.decode(inputImg);
    final Uint8List? decodedBytes =
        decodedImg?.getBytes(order: imglib.ChannelOrder.rgb);
    List<List<List<int>>> imgArr = [];
    for (int y = 0; y < (decodedImg?.height.toInt() ?? 0); y++) {
      imgArr.add([]);
      for (int x = 0; x < (decodedImg?.width.toInt() ?? 0); x++) {
        int red =
            decodedBytes?[y * (decodedImg?.width.toInt() ?? 0) * 3 + x * 3] ??
                0;
        int green = decodedBytes?[
                y * (decodedImg?.width.toInt() ?? 0) * 3 + x * 3 + 1] ??
            0;
        int blue = decodedBytes?[
                y * (decodedImg?.width.toInt() ?? 0) * 3 + x * 3 + 2] ??
            0;
        imgArr[y].add([red, green, blue]);
      }
    }
    return imgArr;
  }

  static List<double> getRGBOnArrayFromCameraImage(imglib.Image? image) {
    // final Uint8List inputImg = image.toUint8List();

    // // Assuming Png image
    // final imglib.PngDecoder decoder = imglib.PngDecoder();
    // final imglib.Image? decodedImg = decoder.decode(inputImg);
    final Uint8List? decodedBytes =
        image?.getBytes(order: imglib.ChannelOrder.rgb);
    List<List<List<int>>> imgArr = [];

    for (int y = 0; y < (image?.height.toInt() ?? 0); y++) {
      imgArr.add([]);
      for (int x = 0; x < (image?.width.toInt() ?? 0); x++) {
        int red =
            decodedBytes?[y * (image?.width.toInt() ?? 0) * 3 + x * 3] ?? 0;
        int green =
            decodedBytes?[y * (image?.width.toInt() ?? 0) * 3 + x * 3 + 1] ?? 0;
        int blue =
            decodedBytes?[y * (image?.width.toInt() ?? 0) * 3 + x * 3 + 2] ?? 0;
        imgArr[y].add([red, green, blue]);
      }
    }
    int totalGreen = 0;
    int totalRed = 0;
    int totalBlue = 0;
    int tp = imgArr.length * imgArr[0].length;
    for (int i = 0; i < imgArr.length; i++) {
      for (int j = 0; j < imgArr[i].length; j++) {
        totalRed += imgArr[i][j][0];
        totalGreen += imgArr[i][j][1];
        totalBlue += imgArr[i][j][2];
      }
    }
    return [totalRed / tp, totalGreen / tp, totalBlue / tp];
  }

  imglib.Image convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = imglib.Image(width: width, height: height);

    for (var w = 0; w < width; w++) {
      for (var h = 0; h < height; h++) {
        final uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        // final index = h * width + w;
        final yIndex = h * yRowStride + w;

        final y = cameraImage.planes[0].bytes[yIndex];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.data?.setPixel(w, h, yuv2rgb(y, u, v));
      }
    }
    return image;
  }

  static imglib.Color yuv2rgb(int y, int u, int v) {
    // Convert yuv pixel to rgb
    int r = (y + v * 1436 / 1024 - 179).round().clamp(0, 255);
    int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91)
        .round()
        .clamp(0, 255);
    int b = (y + u * 1814 / 1024 - 227).round().clamp(0, 255);

    return imglib.ColorRgb8(r, g, b);
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
