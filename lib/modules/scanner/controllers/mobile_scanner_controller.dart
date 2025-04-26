// modules/scanner/controllers/mobile_scanner_controller.dart
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

class CustomScannerController extends GetxController {
  final StorageService storageService = Get.find<StorageService>();
  final ScannerService scannerService = Get.find<ScannerService>();
  
  final cameraController = Rx<scanner.MobileScannerController?>(null);
  final hasPermission = false.obs;
  final isInitialized = false.obs;
  final torchState = scanner.TorchState.off.obs;
  final isProcessing = false.obs;
  
  DateTime? lastScanTime;

  @override
  void onInit() {
    super.onInit();
    initializeScanner();
  }

  Future<void> initializeScanner() async {
    try {
      final status = await Permission.camera.request();
      hasPermission.value = status.isGranted;

      if (hasPermission.value) {
        cameraController.value = scanner.MobileScannerController(
          torchEnabled: false,
        );
        isInitialized.value = true;
        print('Scanner initialized successfully');
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
      torchState.value = torchState.value == scanner.TorchState.off 
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
    
    if (isProcessing.value || capture.barcodes.isEmpty) return;
    
    isProcessing.value = true;
    try {
      await cameraController.value?.stop();
      
      // Save the captured image
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
        print('Image saved to: $imagePath');
        if (!await file.exists()) {
          print('Warning: Saved image does not exist at: $imagePath');
          imagePath = null;
        }
      } else {
        print('No image captured from scanner');
      }

      // Create barcode data objects
      final barcodes = capture.barcodes.map((barcode) {
        return BarcodeData(
          value: barcode.rawValue ?? 'Unknown',
          format: barcode.format.name,
          corners: null,
        );
      }).toList();
      
      // Create a scan result
      final scanResult = ScanResult(
        id: const Uuid().v4(),
        timestamp: now,
        barcodes: barcodes,
        imagePath: imagePath,
        extractedText: barcodes.map((b) => b.value).join('\n'),
      );
      
      // Save the scan result
      await storageService.saveScanResult(scanResult);
      print('Scan saved: ${scanResult.id}');
      
      // Navigate to scan details
      Get.delete<ScanDetailsController>();
      await Get.toNamed('/scan_details', arguments: scanResult.id);
    } catch (e) {
      print('Error processing scan: $e');
      Get.snackbar('Error', 'Failed to process scan', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProcessing.value = false;
      cameraController.value?.start();
    }
  }
  
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
        } finally {
          isProcessing.value = false;
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar('Error', 'Failed to pick image', snackPosition: SnackPosition.BOTTOM);
      isProcessing.value = false;
    }
  }

  @override
  void onClose() {
    cameraController.value?.dispose();
    super.onClose();
  }
}

// // modules/scanner/controllers/mobile_scanner_controller.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mobile_scanner/mobile_scanner.dart' as scanner;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:scanner_app/data/models/scan_result.dart';
// import 'package:scanner_app/data/services/scanner_service.dart';
// import 'package:scanner_app/data/services/storage_service.dart';
// import 'package:scanner_app/modules/scan_details/controllers/scan_details_controller.dart';
// import 'package:uuid/uuid.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import 'package:image_picker/image_picker.dart';

// class CustomScannerController extends GetxController {
//   final StorageService storageService = Get.find<StorageService>();
//   final ScannerService scannerService = Get.find<ScannerService>();
  
//   final cameraController = Rx<scanner.MobileScannerController?>(null);
//   final hasPermission = false.obs;
//   final isInitialized = false.obs;
//   final torchState = scanner.TorchState.off.obs;
//   final isProcessing = false.obs;
  
//   DateTime? lastScanTime;

//   @override
//   void onInit() {
//     super.onInit();
//     initializeScanner();
//   }

//   Future<void> initializeScanner() async {
//     try {
//       final status = await Permission.camera.request();
//       hasPermission.value = status.isGranted;

//       if (hasPermission.value) {
//         cameraController.value = scanner.MobileScannerController(
//           torchEnabled: false,
//         );
//         isInitialized.value = true;
//       } else {
//         Get.snackbar(
//           'Permission Denied',
//           'Camera access is required for scanning. Please enable it in settings.',
//           snackPosition: SnackPosition.BOTTOM,
//           duration: const Duration(seconds: 5),
//           mainButton: TextButton(
//             onPressed: openAppSettings,
//             child: const Text('Settings'),
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error initializing scanner: $e');
//       Get.snackbar('Error', 'Failed to initialize scanner', snackPosition: SnackPosition.BOTTOM);
//     }
//   }

//   void toggleTorch() {
//     if (cameraController.value != null) {
//       cameraController.value!.toggleTorch();
//       torchState.value = torchState.value == scanner.TorchState.off 
//           ? scanner.TorchState.on 
//           : scanner.TorchState.off;
//     }
//   }
  
//   Future<void> processDetection(scanner.BarcodeCapture capture) async {
//     final now = DateTime.now();
//     if (lastScanTime != null && 
//         now.difference(lastScanTime!).inMilliseconds < 1000) {
//       return;
//     }
//     lastScanTime = now;
    
//     if (isProcessing.value || capture.barcodes.isEmpty) return;
    
//     isProcessing.value = true;
//     try {
//       await cameraController.value?.stop();
      
//       // Save the captured image
//       String? imagePath;
//       final imageBytes = capture.image;
//       if (imageBytes != null) {
//         final appDir = await getApplicationDocumentsDirectory();
//         final barcodeDir = Directory('${appDir.path}/barcode_images');
//         if (!await barcodeDir.exists()) {
//           await barcodeDir.create(recursive: true);
//         }
//         final fileName = '${now.millisecondsSinceEpoch}.jpg';
//         imagePath = path.join(barcodeDir.path, fileName);
//         final file = File(imagePath);
//         await file.writeAsBytes(imageBytes);
//         print('Image saved to: $imagePath');
//       } else {
//         print('No image captured from scanner');
//       }

//       // Create barcode data objects
//       final barcodes = capture.barcodes.map((barcode) {
//         return BarcodeData(
//           value: barcode.rawValue ?? 'Unknown',
//           format: barcode.format.name,
//           corners: null,
//         );
//       }).toList();
      
//       // Create a scan result
//       final scanResult = ScanResult(
//         id: const Uuid().v4(),
//         timestamp: now,
//         barcodes: barcodes,
//         imagePath: imagePath,
//         extractedText: barcodes.map((b) => b.value).join('\n'),
//       );
      
//       // Save the scan result
//       await storageService.saveScanResult(scanResult);
//       print('Scan saved: ${scanResult.id}');
      
//       // Navigate to scan details
//       Get.delete<ScanDetailsController>();
//       await Get.toNamed('/scan_details', arguments: scanResult.id);
//     } catch (e) {
//       print('Error processing scan: $e');
//       Get.snackbar('Error', 'Failed to process scan', snackPosition: SnackPosition.BOTTOM);
//     } finally {
//       isProcessing.value = false;
//       cameraController.value?.start();
//     }
//   }
  
//   Future<void> pickImageFromGallery() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? photo = await picker.pickImage(
//         source: ImageSource.gallery,
//         maxHeight: 600,
//         maxWidth: 600,
//       );

//       if (photo != null) {
//         isProcessing.value = true;
//         try {
//           final imageFile = File(photo.path);
          
//           // Save the image to app storage
//           final appDir = await getApplicationDocumentsDirectory();
//           final barcodeDir = Directory('${appDir.path}/barcode_images');
//           if (!await barcodeDir.exists()) {
//             await barcodeDir.create(recursive: true);
//           }
//           final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
//           final imagePath = path.join(barcodeDir.path, fileName);
//           await imageFile.copy(imagePath);
//           print('Gallery image saved to: $imagePath');

//           // Process the image with scanner service
//           final scanResult = await scannerService.processImage(imageFile);
          
//           if (scanResult.barcodes.isEmpty) {
//             Get.snackbar(
//               'No Barcodes Found',
//               'No barcodes were detected in this image.',
//               snackPosition: SnackPosition.BOTTOM,
//             );
//           } else {
//             // Update scan result with image path
//             final updatedScanResult = ScanResult(
//               id: scanResult.id,
//               timestamp: scanResult.timestamp,
//               barcodes: scanResult.barcodes,
//               imagePath: imagePath,
//               extractedText: scanResult.extractedText,
//             );
//             await storageService.saveScanResult(updatedScanResult);
//             print('Gallery scan saved: ${updatedScanResult.id}');
            
//             Get.delete<ScanDetailsController>();
//             await Get.toNamed('/scan_details', arguments: updatedScanResult.id);
//           }
//         } finally {
//           isProcessing.value = false;
//         }
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//       Get.snackbar('Error', 'Failed to pick image', snackPosition: SnackPosition.BOTTOM);
//       isProcessing.value = false;
//     }
//   }

//   @override
//   void onClose() {
//     cameraController.value?.dispose();
//     super.onClose();
//   }
// }
