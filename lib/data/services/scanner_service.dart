import 'dart:io';
import 'package:get/get.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/data/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ScannerService extends GetxService {
  final StorageService storageService = Get.find<StorageService>();
  final barcodeScanner = BarcodeScanner(formats: [
    BarcodeFormat.qrCode,
    BarcodeFormat.code128,
    BarcodeFormat.upca,
    BarcodeFormat.upce,
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.itf,
    BarcodeFormat.pdf417,
    BarcodeFormat.aztec,
    BarcodeFormat.codabar,
    BarcodeFormat.all,
  ]);

  Future<ScanResult> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final barcodes = await barcodeScanner.processImage(inputImage);

      final scanResult = ScanResult(
        id: const Uuid().v4(),
        imagePath: imageFile.path,
        barcodes: barcodes.map((barcode) => BarcodeData(
          format: barcode.format.toString(),
          value: barcode.rawValue ?? '',
          corners: null,
        )).toList(),
        extractedText: barcodes.map((barcode) => barcode.rawValue ?? '').join('\n'),
        timestamp: DateTime.now(),
      );

      await storageService.saveScanResult(scanResult);
      print('Scan result saved: ID=${scanResult.id}, Barcodes=${scanResult.barcodes.length}');
      return scanResult;
    } catch (e) {
      print('Error processing image: $e');
      return ScanResult(
        id: const Uuid().v4(),
        imagePath: imageFile.path,
        barcodes: [],
        extractedText: '',
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  void onClose() {
    barcodeScanner.close();
    super.onClose();
  }
}