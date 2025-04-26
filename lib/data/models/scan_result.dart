import 'dart:convert';

class ScanResult {
  final String id;
  final DateTime timestamp;
  final List<BarcodeData> barcodes;
  final String? imagePath;
  final String? extractedText;

  ScanResult({
    required this.id,
    required this.timestamp,
    required this.barcodes,
    this.imagePath,
    this.extractedText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'barcodes': barcodes.map((x) => x.toMap()).toList(),
      'imagePath': imagePath,
      'extractedText': extractedText,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      barcodes: List<BarcodeData>.from(
          map['barcodes']?.map((x) => BarcodeData.fromMap(x))),
      imagePath: map['imagePath'],
      extractedText: map['extractedText'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ScanResult.fromJson(String source) {
    try {
      return ScanResult.fromMap(json.decode(source));
    } catch (e) {
      print('Error parsing ScanResult from JSON: $e');
      print('Source: $source');
      rethrow;
    }
  }
}

class BarcodeData {
  final String value;
  final String format;
  final List<Point>? corners;

  BarcodeData({
    required this.value,
    required this.format,
    this.corners,
  });

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'format': format,
      'corners': corners?.map((x) => x.toMap()).toList(),
    };
  }

  factory BarcodeData.fromMap(Map<String, dynamic> map) {
    return BarcodeData(
      value: map['value'],
      format: map['format'],
      corners: map['corners'] != null
          ? List<Point>.from(map['corners'].map((x) => Point.fromMap(x)))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BarcodeData.fromJson(String source) =>
      BarcodeData.fromMap(json.decode(source));
}

class Point {
  final double x;
  final double y;

  Point({
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory Point.fromMap(Map<String, dynamic> map) {
    return Point(
      x: map['x']?.toDouble() ?? 0.0,
      y: map['y']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Point.fromJson(String source) => Point.fromMap(json.decode(source));
}