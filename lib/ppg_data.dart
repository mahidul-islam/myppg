import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:myppg/util.dart';

import 'package:image/image.dart' as imglib;

String ppgDataToJson(PpgData data) => json.encode(data.toJson());

class PpgData {
  MetaData? metaData;
  RecordingOptions? recordingOptions;
  TimeSeries? timeSeries;

  PpgData({
    required this.metaData,
    required this.recordingOptions,
    required this.timeSeries,
  });

  factory PpgData.init() {
    PpgData ppg =
        PpgData(metaData: null, recordingOptions: null, timeSeries: null);
    ppg.addInitMetaData();
    return ppg;
  }

  Map<String, dynamic> toJson() => {
        "meta_data": metaData?.toJson(),
        "recording_options": recordingOptions?.toJson(),
        "time_series": timeSeries?.toJson(),
      };

  Future<void> addData(CameraImage? cameraImage, bool breathing) async {
    if (cameraImage == null) {
      return;
    }
    timeSeries ??= TimeSeries(
      breathingStream: [],
      pixelAverage: PixelAverage(
        r: [],
        g: [],
        b: [],
      ),
    );
    List<imglib.Image>? images = Helper.splitImageIn4x4(
        await Helper.getUint8ListFromCameraImage(cameraImage));
    if (images == null || images.isEmpty) {
      return;
    }
    List<double> pixel = Helper.getReducedRGBFromImagelibImage(images.first);

    timeSeries?.pixelAverage.r.add(pixel[0]);
    timeSeries?.pixelAverage.g.add(pixel[1]);
    timeSeries?.pixelAverage.b.add(pixel[2]);
    timeSeries?.breathingStream.add(breathing ? 1 : 0);
  }

  void addInitMetaData() async {
    String deviceName = '';
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.utsname.machine;
    }
    metaData = MetaData(
      user: deviceName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      duration: null,
      frameCount: null,
    );
  }

  void addFinalMetaData(int duration, int frameCount) {
    metaData?.duration = duration;
    metaData?.frameCount = frameCount;
  }
}

class MetaData {
  String user;
  int timestamp;
  int? duration;
  int? frameCount;

  MetaData({
    required this.user,
    required this.timestamp,
    required this.duration,
    required this.frameCount,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) => MetaData(
        user: json["user"],
        timestamp: json["timestamp"],
        duration: json["duration"],
        frameCount: json["frame_count"],
      );

  Map<String, dynamic> toJson() => {
        "user": user,
        "timestamp": timestamp,
        "duration": duration,
        "frame_count": frameCount,
      };
}

class RecordingOptions {
  String frameRate;

  RecordingOptions({
    required this.frameRate,
  });

  factory RecordingOptions.fromJson(Map<String, dynamic> json) =>
      RecordingOptions(
        frameRate: json["frame_rate"],
      );

  Map<String, dynamic> toJson() => {
        "frame_rate": frameRate,
      };
}

class TimeSeries {
  List<int> breathingStream;
  PixelAverage pixelAverage;

  TimeSeries({
    required this.breathingStream,
    required this.pixelAverage,
  });

  Map<String, dynamic> toJson() => {
        "breathing_stream": base64
            .encode(Int8List.fromList(breathingStream).buffer.asUint8List()),
        "pixel_average": pixelAverage.toJson(),
      };
}

class PixelAverage {
  List<double> r;
  List<double> g;
  List<double> b;

  PixelAverage({
    required this.r,
    required this.g,
    required this.b,
  });

  Map<String, dynamic> toJson() => {
        "r": base64.encode(Float32List.fromList(r).buffer.asUint8List()),
        "g": base64.encode(Float32List.fromList(g).buffer.asUint8List()),
        "b": base64.encode(Float32List.fromList(b).buffer.asUint8List()),
      };
}
