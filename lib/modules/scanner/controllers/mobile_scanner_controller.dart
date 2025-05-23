import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as scanner;
import 'package:permission_handler/permission_handler.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/data/services/scanner_service.dart';
import 'package:scanner_app/data/services/storage_service.dart';
import 'package:scanner_app/modules/scan_details/controllers/scan_details_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';


class CustomScannerController extends GetxController {
  final StorageService storageService = Get.find<StorageService>();
  final ScannerService scannerService = Get.find<ScannerService>();

  final cameraController = Rx<scanner.MobileScannerController?>(null);
  final hasPermission = false.obs;
  final isInitialized = false.obs;
  final torchState = scanner.TorchState.off.obs;
  final isProcessing = false.obs;

  DateTime? lastScanTime;

  // Track if the scanner is scanning
  bool isScanning = false;

  @override
  void onInit() {
    super.onInit();
    initializeScanner();
  }

  Future<void> initializeScanner() async {
    try {
      if (isInitialized.value) return; // Prevent re-initialization

      final status = await Permission.camera.request();
      hasPermission.value = status.isGranted;

      if (hasPermission.value) {
        cameraController.value = scanner.MobileScannerController(
          torchEnabled: false,
          returnImage: true,
          detectionSpeed: scanner.DetectionSpeed.noDuplicates, // Set detection speed
          detectionTimeoutMs: 1000, // Increase detection timeout to 1 second
        );

        // Start the scanner if it's not already scanning
        if (!isScanning) {
          await cameraController.value?.start();
          isScanning = true;
          print('Scanner initialized successfully');
        }

        isInitialized.value = true;
      } else {
        Get.snackbar(
          'Permission Denied',
          'Camera access is required for scanning. Please enable it in settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: openAppSettings,
            child: const Text('Settings'),
          ),
        );
      }
    } catch (e) {
      print('Error initializing scanner: $e');
      Get.snackbar('Error', 'Failed to initialize scanner', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void toggleTorch() {
    if (cameraController.value != null) {
      cameraController.value!.toggleTorch();
      torchState.value =
          torchState.value == scanner.TorchState.off
              ? scanner.TorchState.on
              : scanner.TorchState.off;
    }
  }
Future<void> processDetection(scanner.BarcodeCapture capture) async {
  final now = DateTime.now();
  if (lastScanTime != null &&
      now.difference(lastScanTime!).inMilliseconds < 1000) {
    return;
  }
  lastScanTime = now;

  if (isProcessing.value || capture.barcodes.isEmpty) {
    print('No barcodes detected or already processing.');
    return;
  }

  isProcessing.value = true;

  try {
    await Future.delayed(const Duration(milliseconds: 300));
    await cameraController.value?.stop();

    print('Detected barcodes: ${capture.barcodes.map((b) => b.rawValue)}');

    String? imagePath;
    final imageBytes = capture.image;

    if (imageBytes != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final barcodeDir = Directory('${appDir.path}/barcode_images');
      if (!await barcodeDir.exists()) {
        await barcodeDir.create(recursive: true);
      }

      final fileName = '${now.millisecondsSinceEpoch}.jpg';
      imagePath = path.join(barcodeDir.path, fileName);
      final file = File(imagePath);
      await file.writeAsBytes(imageBytes);

      if (!await file.exists()) {
        imagePath = null;
        Get.snackbar('Warning', 'Failed to save scan image');
      } else {
        // ✅ Save to gallery here
        final result = await ImageGallerySaverPlus.saveFile(imagePath);
        print("Saved to gallery: $result");

        if (result['isSuccess'] != true) {
          Get.snackbar('Warning', 'Failed to save image to gallery');
        }
      }
    } else {
      print('No image from scanner');
      Get.snackbar('Warning', 'Scanner did not capture an image');
    }

    final barcodes = capture.barcodes.map((barcode) {
      return BarcodeData(
        value: barcode.rawValue ?? 'Unknown',
        format: barcode.format.name,
        corners: null,
      );
    }).toList();

    final scanResult = ScanResult(
      id: const Uuid().v4(),
      timestamp: now,
      barcodes: barcodes,
      imagePath: imagePath,
      extractedText: barcodes.map((b) => b.value).join('\n'),
    );

    await storageService.saveScanResult(scanResult);
    print('Scan saved: ${scanResult.id}');

    Get.back(result: scanResult.id);
  } catch (e) {
    print('Error processing scan: $e');
    Get.snackbar('Error', 'Failed to process scan: $e',
        snackPosition: SnackPosition.BOTTOM);
  } finally {
    isProcessing.value = false;
    isScanning = false;
  }
}


// Future<void> processDetection(scanner.BarcodeCapture capture) async {
//   final now = DateTime.now();
//   if (lastScanTime != null &&
//       now.difference(lastScanTime!).inMilliseconds < 1000) {
//     return;
//   }
//   lastScanTime = now;

//   if (isProcessing.value || capture.barcodes.isEmpty) {
//     print('No barcodes detected or processing: ${capture.barcodes.length}');
//     return;
//   }

//   isProcessing.value = true;
//   try {
//     // Delay to ensure frame capture
//     await Future.delayed(const Duration(milliseconds: 300));

//     await cameraController.value?.stop();

//     // Log barcode details
//     print('Detected barcodes: ${capture.barcodes.length}');
//     print('Barcode values: ${capture.barcodes.map((b) => b.rawValue)}');

//     // Save the full captured image
//     String? imagePath;
//     final imageBytes = capture.image;
//     if (imageBytes != null) {
//       final appDir = await getApplicationDocumentsDirectory();
//       final barcodeDir = Directory('${appDir.path}/barcode_images');
//       if (!await barcodeDir.exists()) {
//         await barcodeDir.create(recursive: true);
//       }
//       final fileName = '${now.millisecondsSinceEpoch}.jpg';
//       imagePath = path.join(barcodeDir.path, fileName);
//       final file = File(imagePath);
//       await file.writeAsBytes(imageBytes);
//       print('Image saved to: $imagePath');
//       if (!await file.exists()) {
//         print('Warning: Saved image does not exist at: $imagePath');
//         imagePath = null;
//         Get.snackbar('Warning', 'Failed to save scan image');
//       }
//     } else {
//       print('No image captured from scanner');
//       Get.snackbar('Warning', 'Scanner did not capture an image');
//     }

//     // Create barcode data objects
//     final barcodes = capture.barcodes.map((barcode) {
//       return BarcodeData(
//         value: barcode.rawValue ?? 'Unknown',
//         format: barcode.format.name,
//         corners: null,
//       );
//     }).toList();

//     // Create a scan result
//     final scanResult = ScanResult(
//       id: const Uuid().v4(),
//       timestamp: now,
//       barcodes: barcodes,
//       imagePath: imagePath,
//       extractedText: barcodes.map((b) => b.value).join('\n'),
//     );

//     // Save the scan result
//     await storageService.saveScanResult(scanResult);
//     print('Scan saved: ${scanResult.id}');

//     // Return to the home screen with the scan ID
//     Get.back(result: scanResult.id); // Return the scan ID as the result
//   } catch (e) {
//     print('Error processing scan: $e');
//     Get.snackbar(
//       'Error',
//       'Failed to process scan: $e',
//       snackPosition: SnackPosition.BOTTOM,
//     );
//   } finally {
//     isProcessing.value = false;

//     // Do NOT restart the scanner here, as we've navigated away
//     // The scanner will restart when the screen is revisited
//     isScanning = false;
//     print('Scanner stopped, waiting for screen revisit to restart');
//   }
// }

  Future<void> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 600,
        maxWidth: 600,
      );

      if (photo != null) {
        isProcessing.value = true;
        try {
          final imageFile = File(photo.path);

          // Save the image to app storage
          final appDir = await getApplicationDocumentsDirectory();
          final barcodeDir = Directory('${appDir.path}/barcode_images');
          if (!await barcodeDir.exists()) {
            await barcodeDir.create(recursive: true);
          }
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          final imagePath = path.join(barcodeDir.path, fileName);
          await imageFile.copy(imagePath);
          print('Gallery image saved to: $imagePath');
          if (!await File(imagePath).exists()) {
            print('Warning: Saved gallery image does not exist at: $imagePath');
            Get.snackbar('Error', 'Failed to save gallery image');
            return;
          }

          // Process the image with scanner service
          final scanResult = await scannerService.processImage(imageFile);

          if (scanResult.barcodes.isEmpty) {
            Get.snackbar(
              'No Barcodes Found',
              'No barcodes were detected in this image.',
              snackPosition: SnackPosition.BOTTOM,
            );
          } else {
            // Update scan result with image path
            final updatedScanResult = ScanResult(
              id: scanResult.id,
              timestamp: scanResult.timestamp,
              barcodes: scanResult.barcodes,
              imagePath: imagePath,
              extractedText: scanResult.extractedText,
            );
            await storageService.saveScanResult(updatedScanResult);
            print('Gallery scan saved: ${updatedScanResult.id}');

            Get.delete<ScanDetailsController>();
            await Get.toNamed('/scan_details', arguments: updatedScanResult.id);
          }
        } catch (e) {
          print('Error processing gallery image: $e');
          Get.snackbar(
            'Error',
            'Failed to process gallery image: $e',
            snackPosition: SnackPosition.BOTTOM,
          );
        } finally {
          isProcessing.value = false;
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      isProcessing.value = false;
    }
  }

  @override
  void onClose() {
    cameraController.value?.dispose();
    super.onClose();
  }
}

