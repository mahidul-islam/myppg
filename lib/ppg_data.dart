import 'dart:convert';
import 'dart:typed_data';

String ppgDataToJson(PpgData data) => json.encode(data.toJson());

class PpgData {
  MetaData metaData;
  RecordingOptions recordingOptions;
  TimeSeries timeSeries;

  PpgData({
    required this.metaData,
    required this.recordingOptions,
    required this.timeSeries,
  });

  Map<String, dynamic> toJson() => {
        "meta_data": metaData.toJson(),
        "recording_options": recordingOptions.toJson(),
        "time_series": timeSeries.toJson(),
      };
}

class MetaData {
  String user;
  String timestamp;
  String duration;
  String frameCount;

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
