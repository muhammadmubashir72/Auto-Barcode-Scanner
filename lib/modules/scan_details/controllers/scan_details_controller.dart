import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/data/services/storage_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanDetailsController extends GetxController {
  final storageService = Get.find<StorageService>();
  final scanResult = Rxn<ScanResult>();
  final isLoading = true.obs;
  final isProcessing = false.obs;
  final isSavingToGallery = false.obs;

  @override
  void onInit() {
    super.onInit();
    final scanId = Get.arguments as String?;
    if (scanId != null) {
      loadScanDetails(scanId);
    } else {
      isLoading.value = false;
      Get.snackbar('Error', 'No scan ID provided');
    }
  }

  Future<void> loadScanDetails(String id) async {
    isLoading.value = true;
    try {
      final result = await storageService.getScanById(id);
      scanResult.value = result;
      if (result == null) {
        Get.snackbar('Error', 'Scan not found');
      }
    } catch (e) {
      Get.log('Error loading scan details: $e', isError: true);
      Get.snackbar('Error', 'Failed to load scan details');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveImageToGallery(String imagePath) async {
    try {
      isSavingToGallery.value = true;

      final file = File(imagePath);

      // Check if the file exists
      if (!await file.exists()) {
        Get.snackbar('Error', 'Image file not found');
        return;
      }

      // Request permissions for storage and photos
      if (Platform.isAndroid || Platform.isIOS) {
        final storagePermission = await Permission.storage.request();
        final photosPermission = await Permission.photos.request();

        // If permission is not granted, show a snackbar and return
        if (!storagePermission.isGranted || !photosPermission.isGranted) {
          Get.snackbar('Error', 'Permission denied');
          return;
        }
      }

      // Try to save the image
      final result = await ImageGallerySaverPlus.saveFile(imagePath);

      // Check if saving was successful
      if (result['isSuccess'] == true) {
        Get.snackbar('Success', 'Image saved to gallery');
      } else {
        // If saving failed, show an error message
        Get.snackbar('Error', 'Failed to save image');
      }
    } catch (e) {
      // Log and show any error that occurs during saving the image
      Get.log('Error saving image: $e', isError: true);
      Get.snackbar('Error', 'Failed to save image');
    } finally {
      // Set saving flag to false after the operation is completed
      isSavingToGallery.value = false;
    }
  }

  // Future<void> saveImageToGallery(String imagePath) async {
  //   try {
  //     isSavingToGallery.value = true;
  //     final file = File(imagePath);
  //     if (!await file.exists()) {
  //       Get.snackbar('Error', 'Image file not found');
  //       return;
  //     }

  //     if (Platform.isAndroid || Platform.isIOS) {
  //       final storagePermission = await Permission.storage.request();
  //       final photosPermission = await Permission.photos.request();

  //       if (!storagePermission.isGranted || !photosPermission.isGranted) {
  //         Get.snackbar('Error', 'Permission denied');
  //         return;
  //       }
  //     }

  //     final result = await ImageGallerySaverPlus.saveFile(imagePath);
  //     if (result['isSuccess'] == true) {
  //       Get.snackbar('Success', 'Image saved to gallery');
  //     } else {
  //       Get.snackbar('Error', 'Failed to save image');
  //     }
  //   } catch (e) {
  //     Get.log('Error saving image: $e', isError: true);
  //     Get.snackbar('Error', 'Failed to save image');
  //   } finally {
  //     isSavingToGallery.value = false;
  //   }
  // }

  Future<void> deleteScan() async {
    if (scanResult.value == null) return;

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this scan?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      isProcessing.value = true;
      await storageService.deleteScan(scanResult.value!.id);
      Get.back(result: true);
    } catch (e) {
      Get.log('Error deleting scan: $e', isError: true);
      Get.snackbar('Error', 'Failed to delete scan');
    } finally {
      isProcessing.value = false;
    }
  }

  void shareScan() async {
    if (scanResult.value == null) return;

    isProcessing.value = true;
    try {
      final scan = scanResult.value!;
      String shareText = 'Barcode Scan (${scan.timestamp}):\n\n';
      for (final barcode in scan.barcodes) {
        shareText += '${barcode.value} (${barcode.format})\n';
      }

      if (scan.imagePath != null && File(scan.imagePath!).existsSync()) {
        await Share.shareXFiles([XFile(scan.imagePath!)], text: shareText);
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      Get.log('Error sharing scan: $e', isError: true);
      Get.snackbar('Error', 'Failed to share scan');
    } finally {
      isProcessing.value = false;
    }
  }

  void copyToClipboard() {
    if (scanResult.value == null) return;

    final scan = scanResult.value!;
    final text = scan.barcodes.map((b) => b.value).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Copied', 'Barcode data copied to clipboard');
  }

  Future<void> openUrl(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    try {
      final uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch URL';
      }
    } catch (e) {
      Get.log('Error opening URL: $e', isError: true);
      Get.snackbar('Error', 'Failed to open: $formattedUrl');
    }
  }

  Future<void> dialPhone(String phone) async {
    String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final phoneUrl = 'tel:$cleanedPhone';

    try {
      final uri = Uri.parse(phoneUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Cannot launch dialer';
      }
    } catch (e) {
      Get.log('Error dialing phone: $e', isError: true);
      Get.snackbar('Error', 'Failed to dial: $cleanedPhone');
    }
  }

  /// --- Parsers Section ---

  Map<String, String> parseWifiQR(String data) {
    final result = <String, String>{};
    try {
      if (data.startsWith('WIFI:')) {
        data = data.substring(5); // Strip 'WIFI:' prefix
        final matches = RegExp(r'(\w+):([^;]*)').allMatches(data);
        for (final match in matches) {
          final key = match.group(1)?.toLowerCase();
          final value = match.group(2);
          if (key != null && value != null) {
            result[key] = value;
          }
        }
      }
    } catch (e) {
      Get.log('Error parsing WiFi QR: $e', isError: true);
    }
    return result;
  }

  Map<String, String> parseVCard(String data) {
    final result = <String, String>{};
    try {
      if (data.startsWith('BEGIN:VCARD')) {
        final lines = data.split(RegExp(r'\r\n|\n'));
        for (var line in lines) {
          if (line.startsWith('TEL:')) {
            result['phone'] = line.substring(4);
          } else if (line.startsWith('URL:')) {
            result['url'] = line.substring(4);
          } else if (line.startsWith('EMAIL;') || line.startsWith('EMAIL:')) {
            result['email'] = line.split(':').last;
          } else if (line.startsWith('FN:')) {
            result['name'] = line.substring(3);
          } else if (line.startsWith('ORG:')) {
            result['organization'] = line.substring(4);
          } else if (line.startsWith('TITLE:')) {
            result['title'] = line.substring(6);
          } else if (line.startsWith('ADR:')) {
            result['address'] = line.substring(4).replaceAll(';', ' ');
          }
        }
      }
    } catch (e) {
      Get.log('Error parsing vCard: $e', isError: true);
    }
    return result;
  }

  /// --- Validators Section ---
  bool isUrl(String text) {
    return RegExp(
      r'^(https?:\/\/)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}(\/[^\s]*)?$',
    ).hasMatch(text);
  }

  bool isPhoneNumber(String text) {
    return RegExp(r'^\+?[0-9]+[-\s.]?[0-9]+$').hasMatch(text);
  }

  bool isWifi(String text) {
    return text.startsWith('WIFI:');
  }

  bool isVCard(String text) {
    return text.startsWith('BEGIN:VCARD');
  }

  IconData getBarcodeIcon(String value, String format) {
    if (format.contains('qr') || isVCard(value)) {
      return Icons.qr_code;
    } else if (isUrl(value)) {
      return Icons.link;
    } else if (isPhoneNumber(value)) {
      return Icons.phone;
    } else if (isWifi(value)) {
      return Icons.wifi;
    } else if (value.startsWith('mailto:')) {
      return Icons.email;
    } else if (value.startsWith('geo:')) {
      return Icons.location_on;
    } else {
      return Icons.qr_code_scanner;
    }
  }
}

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:scanner_app/data/models/scan_result.dart';
// import 'package:scanner_app/data/services/storage_service.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
// import 'package:permission_handler/permission_handler.dart';

// class ScanDetailsController extends GetxController {
//   final StorageService storageService = Get.find<StorageService>();
//   final scanResult = Rx<ScanResult?>(null);
//   final isLoading = true.obs;
//   final isSavingToGallery = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     final scanId = Get.arguments as String?;
//     if (scanId != null) {
//       loadScanDetails(scanId);
//     } else {
//       isLoading.value = false;
//       Get.snackbar('Error', 'No scan ID provided');
//     }
//   }

//   Future<void> loadScanDetails(String id) async {
//     isLoading.value = true;
//     try {
//       final result = await storageService.getScanById(id);
//       scanResult.value = result;
//       if (result == null) {
//         Get.snackbar('Error', 'Scan not found');
//       } else {
//         print('Scan loaded, imagePath: ${result.imagePath}');
//         if (result.imagePath != null && File(result.imagePath!).existsSync()) {
//           print('Image found: ${result.imagePath}');
//         } else {
//           print('Image path is null or file does not exist: ${result.imagePath}');
//         }
//       }
//     } catch (e) {
//       print('Error loading scan details: $e');
//       Get.snackbar('Error', 'Failed to load scan details');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> saveImageToGallery(String imagePath) async {
//     try {
//       isSavingToGallery.value = true;
//       if (Platform.isAndroid) {
//         final status = await [
//           Permission.storage,
//           Permission.photos,
//         ].request().then((result) => result.values.any((status) => status.isGranted));
//         if (!status) {
//           Get.snackbar('Error', 'Storage or photos permission denied');
//           return;
//         }
//       }
//       final file = File(imagePath);
//       if (await file.exists()) {
//         final result = await ImageGallerySaverPlus.saveFile(imagePath);
//         if (result['isSuccess'] == true) {
//           Get.snackbar('Success', 'Image saved to gallery');
//         } else {
//           print('Save error: ${result['errorMessage']}');
//           Get.snackbar('Error', 'Failed to save image to gallery');
//         }
//       } else {
//         print('Image file does not exist: $imagePath');
//         Get.snackbar('Error', 'Image file not found');
//       }
//     } catch (e) {
//       print('Error saving to gallery: $e');
//       Get.snackbar('Error', 'Failed to save image: $e');
//     } finally {
//       isSavingToGallery.value = false;
//     }
//   }

//   Future<void> deleteScan() async {
//     if (scanResult.value == null) return;
//     try {
//       await storageService.deleteScan(scanResult.value!.id);
//       Get.back(result: true);
//     } catch (e) {
//       print('Error deleting scan: $e');
//       Get.snackbar('Error', 'Failed to delete scan');
//     }
//   }

//   void shareScan() {
//     if (scanResult.value == null) return;
//     final scan = scanResult.value!;
//     String shareText = 'Barcode Scan (${scan.timestamp}):\n\n';
//     for (int i = 0; i < scan.barcodes.length; i++) {
//       final barcode = scan.barcodes[i];
//       shareText += '${barcode.value} (${barcode.format})\n';
//     }
//     if (scan.imagePath != null && File(scan.imagePath!).existsSync()) {
//       Share.shareXFiles([XFile(scan.imagePath!)], text: shareText);
//     } else {
//       Share.share(shareText);
//     }
//   }

//   void copyToClipboard() {
//     if (scanResult.value == null) return;
//     final scan = scanResult.value!;
//     String text = '';
//     for (int i = 0; i < scan.barcodes.length; i++) {
//       final barcode = scan.barcodes[i];
//       text += '${barcode.value}\n';
//     }
//     Clipboard.setData(ClipboardData(text: text));
//     Get.snackbar('Copied', 'Barcode data copied to clipboard');
//   }

//   Future<void> openUrl(String url) async {
//     String formattedUrl = url.trim();
//     if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
//       formattedUrl = 'https://$formattedUrl';
//     }
//     try {
//       final uri = Uri.parse(formattedUrl);
//       print('Attempting to launch URL: $formattedUrl');
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//       print('URL launched successfully: $formattedUrl');
//     } catch (e) {
//       print('Error opening URL: $e');
//       Get.snackbar('Error', 'Failed to open URL: $url');
//     }
//   }

//   Future<void> dialPhone(String phone) async {
//     String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
//     if (cleanedPhone.startsWith('tel:')) {
//       cleanedPhone = cleanedPhone.replaceFirst('tel:', '');
//     }
//     final phoneUrl = 'tel:$cleanedPhone';
//     try {
//       final uri = Uri.parse(phoneUrl);
//       print('Attempting to dial: $phoneUrl');
//       await launchUrl(uri);
//       print('Dialer launched successfully: $phoneUrl');
//     } catch (e) {
//       print('Error dialing phone: $e');
//       Get.snackbar('Error', 'Failed to dial number: $phone');
//     }
//   }

//   Map<String, String> parseWifiQR(String data) {
//     final result = <String, String>{};
//     try {
//       if (data.startsWith('WIFI:')) {
//         data = data.substring(5);
//         final ssidMatch = RegExp(r'S:(.*?);').firstMatch(data);
//         if (ssidMatch != null && ssidMatch.groupCount >= 1) {
//           result['ssid'] = ssidMatch.group(1) ?? '';
//         }
//         final typeMatch = RegExp(r'T:(.*?);').firstMatch(data);
//         if (typeMatch != null && typeMatch.groupCount >= 1) {
//           result['type'] = typeMatch.group(1) ?? '';
//         }
//         final passMatch = RegExp(r'P:(.*?);').firstMatch(data);
//         if (passMatch != null && passMatch.groupCount >= 1) {
//           result['password'] = passMatch.group(1) ?? '';
//         }
//       }
//     } catch (e) {
//       print('Error parsing WiFi QR: $e');
//     }
//     return result;
//   }

//   Map<String, String> parseVCard(String data) {
//     final result = <String, String>{};
//     try {
//       if (data.startsWith('BEGIN:VCARD')) {
//         final lines = data.split('\r\n');
//         for (var line in lines) {
//           if (line.startsWith('TEL:')) {
//             result['phone'] = line.substring(4);
//           } else if (line.startsWith('URL:')) {
//             result['url'] = line.substring(4);
//           } else if (line.startsWith('EMAIL;')) {
//             result['email'] = line.split(':').last;
//           } else if (line.startsWith('FN:')) {
//             result['name'] = line.substring(3);
//           } else if (line.startsWith('ORG:')) {
//             result['organization'] = line.substring(4);
//           } else if (line.startsWith('TITLE:')) {
//             result['title'] = line.substring(6);
//           } else if (line.startsWith('ADR:')) {
//             result['address'] = line.substring(4).replaceAll(';', ' ');
//           }
//         }
//       }
//     } catch (e) {
//       print('Error parsing vCard: $e');
//     }
//     return result;
//   }

//   bool isUrl(String text) {
//     return text.startsWith('http://') ||
//         text.startsWith('https://') ||
//         RegExp(r'^(www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$').hasMatch(text);
//   }

//   bool isPhoneNumber(String text) {
//     return text.startsWith('tel:') ||
//         RegExp(r'^[+]?[(]?[0-9]{1,4}[)]?[-\s./0-9]*$').hasMatch(text);
//   }

//   bool isWifi(String text) {
//     return text.startsWith('WIFI:');
//   }

//   bool isVCard(String text) {
//     return text.startsWith('BEGIN:VCARD');
//   }

//   IconData getBarcodeIcon(String value, String format) {
//     if (format.contains('qr') || isVCard(value)) {
//       return Icons.qr_code;
//     } else if (isUrl(value)) {
//       return Icons.link;
//     } else if (isPhoneNumber(value)) {
//       return Icons.phone;
//     } else if (isWifi(value)) {
//       return Icons.wifi;
//     } else if (value.startsWith('mailto:')) {
//       return Icons.email;
//     } else if (value.startsWith('geo:')) {
//       return Icons.location_on;
//     } else {
//       return Icons.qr_code_scanner;
//     }
//   }
// }

// // modules/scan_details/controllers/scan_details_controller.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:scanner_app/data/models/scan_result.dart';
// import 'package:scanner_app/data/services/storage_service.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
// import 'package:permission_handler/permission_handler.dart';

// class ScanDetailsController extends GetxController {
//   final StorageService storageService = Get.find<StorageService>();
//   final scanResult = Rx<ScanResult?>(null);
//   final isLoading = true.obs;
//   final isSavingToGallery = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     final scanId = Get.arguments as String?;
//     if (scanId != null) {
//       loadScanDetails(scanId);
//     } else {
//       isLoading.value = false;
//       Get.snackbar('Error', 'No scan ID provided');
//     }
//   }

//   Future<void> loadScanDetails(String id) async {
//     isLoading.value = true;
//     try {
//       final result = await storageService.getScanById(id);
//       scanResult.value = result;
//       if (result == null) {
//         Get.snackbar('Error', 'Scan not found');
//       } else {
//         print('Scan loaded, imagePath: ${result.imagePath}');
//         if (result.imagePath != null && File(result.imagePath!).existsSync()) {
//           print('Image found: ${result.imagePath}');
//         } else {
//           print('Image path is null or file does not exist: ${result.imagePath}');
//         }
//       }
//     } catch (e) {
//       print('Error loading scan details: $e');
//       Get.snackbar('Error', 'Failed to load scan details');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> saveImageToGallery(String imagePath) async {
//     try {
//       isSavingToGallery.value = true;
//       if (Platform.isAndroid) {
//         final status = await [
//           Permission.storage,
//           Permission.photos,
//         ].request().then((result) => result.values.any((status) => status.isGranted));
//         if (!status) {
//           Get.snackbar('Error', 'Storage or photos permission denied');
//           return;
//         }
//       }
//       final file = File(imagePath);
//       if (await file.exists()) {
//         final result = await ImageGallerySaverPlus.saveFile(
//           imagePath,
//         );
//         if (result['isSuccess'] == true) {
//           Get.snackbar('Success', 'Image saved to gallery');
//         } else {
//           print('Save error: ${result['errorMessage']}');
//           Get.snackbar('Error', 'Failed to save image to gallery');
//         }
//       } else {
//         print('Image file does not exist: $imagePath');
//         Get.snackbar('Error', 'Image file not found');
//       }
//     } catch (e) {
//       print('Error saving to gallery: $e');
//       Get.snackbar('Error', 'Failed to save image: $e');
//     } finally {
//       isSavingToGallery.value = false;
//     }
//   }

//   Future<void> deleteScan() async {
//     if (scanResult.value == null) return;
//     try {
//       await storageService.deleteScan(scanResult.value!.id);
//       Get.back(result: true);
//     } catch (e) {
//       print('Error deleting scan: $e');
//       Get.snackbar('Error', 'Failed to delete scan');
//     }
//   }

//   void shareScan() {
//     if (scanResult.value == null) return;
//     final scan = scanResult.value!;
//     String shareText = 'Barcode Scan (${scan.timestamp}):\n\n';
//     for (int i = 0; i < scan.barcodes.length; i++) {
//       final barcode = scan.barcodes[i];
//       shareText += '${barcode.value} (${barcode.format})\n';
//     }
//     if (scan.imagePath != null && File(scan.imagePath!).existsSync()) {
//       Share.shareXFiles([XFile(scan.imagePath!)], text: shareText);
//     } else {
//       Share.share(shareText);
//     }
//   }

//   void copyToClipboard() {
//     if (scanResult.value == null) return;
//     final scan = scanResult.value!;
//     String text = '';
//     for (int i = 0; i < scan.barcodes.length; i++) {
//       final barcode = scan.barcodes[i];
//       text += '${barcode.value}\n';
//     }
//     Clipboard.setData(ClipboardData(text: text));
//     Get.snackbar('Copied', 'Barcode data copied to clipboard');
//   }

//   Future<void> openUrl(String url) async {
//     String formattedUrl = url.trim();
//     if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
//       formattedUrl = 'https://$formattedUrl';
//     }
//     try {
//       final uri = Uri.parse(formattedUrl);
//       print('Attempting to launch URL: $formattedUrl');
//       await launchUrl(
//         uri,
//         mode: LaunchMode.externalApplication,
//       );
//       print('URL launched successfully: $formattedUrl');
//     } catch (e) {
//       print('Error opening URL: $e');
//       Get.snackbar('Error', 'Failed to open URL: $url');
//     }
//   }

//   Future<void> dialPhone(String phone) async {
//     String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
//     if (cleanedPhone.startsWith('tel:')) {
//       cleanedPhone = cleanedPhone.replaceFirst('tel:', '');
//     }
//     final phoneUrl = 'tel:$cleanedPhone';
//     try {
//       final uri = Uri.parse(phoneUrl);
//       print('Attempting to dial: $phoneUrl');
//       await launchUrl(uri);
//       print('Dialer launched successfully: $phoneUrl');
//     } catch (e) {
//       print('Error dialing phone: $e');
//       Get.snackbar('Error', 'Failed to dial number: $phone');
//     }
//   }

//   Map<String, String> parseWifiQR(String data) {
//     final result = <String, String>{};
//     try {
//       if (data.startsWith('WIFI:')) {
//         data = data.substring(5);
//         final ssidMatch = RegExp(r'S:(.*?);').firstMatch(data);
//         if (ssidMatch != null && ssidMatch.groupCount >= 1) {
//           result['ssid'] = ssidMatch.group(1) ?? '';
//         }
//         final typeMatch = RegExp(r'T:(.*?);').firstMatch(data);
//         if (typeMatch != null && typeMatch.groupCount >= 1) {
//           result['type'] = typeMatch.group(1) ?? '';
//         }
//         final passMatch = RegExp(r'P:(.*?);').firstMatch(data);
//         if (passMatch != null && passMatch.groupCount >= 1) {
//           result['password'] = passMatch.group(1) ?? '';
//         }
//       }
//     } catch (e) {
//       print('Error parsing WiFi QR: $e');
//     }
//     return result;
//   }

//   Map<String, String> parseVCard(String data) {
//     final result = <String, String>{};
//     try {
//       if (data.startsWith('BEGIN:VCARD')) {
//         final lines = data.split('\r\n');
//         for (var line in lines) {
//           if (line.startsWith('TEL:')) {
//             result['phone'] = line.substring(4);
//           } else if (line.startsWith('URL:')) {
//             result['url'] = line.substring(4);
//           } else if (line.startsWith('EMAIL;')) {
//             result['email'] = line.split(':').last;
//           } else if (line.startsWith('FN:')) {
//             result['name'] = line.substring(3);
//           } else if (line.startsWith('ORG:')) {
//             result['organization'] = line.substring(4);
//           } else if (line.startsWith('TITLE:')) {
//             result['title'] = line.substring(6);
//           } else if (line.startsWith('ADR:')) {
//             result['address'] = line.substring(4).replaceAll(';', ' ');
//           }
//         }
//       }
//     } catch (e) {
//       print('Error parsing vCard: $e');
//     }
//     return result;
//   }

//   bool isUrl(String text) {
//     return text.startsWith('http://') ||
//         text.startsWith('https://') ||
//         RegExp(r'^(www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$').hasMatch(text);
//   }

//   bool isPhoneNumber(String text) {
//     return text.startsWith('tel:') ||
//         RegExp(r'^[+]?[(]?[0-9]{1,4}[)]?[-\s./0-9]*$').hasMatch(text);
//   }

//   bool isWifi(String text) {
//     return text.startsWith('WIFI:');
//   }

//   bool isVCard(String text) {
//     return text.startsWith('BEGIN:VCARD');
//   }

//   IconData getBarcodeIcon(String value, String format) {
//     if (format.contains('qr') || isVCard(value)) {
//       return Icons.qr_code;
//     } else if (isUrl(value)) {
//       return Icons.link;
//     } else if (isPhoneNumber(value)) {
//       return Icons.phone;
//     } else if (isWifi(value)) {
//       return Icons.wifi;
//     } else if (value.startsWith('mailto:')) {
//       return Icons.email;
//     } else if (value.startsWith('geo:')) {
//       return Icons.location_on;
//     } else {
//       return Icons.qr_code_scanner;
//     }
//   }
// }
