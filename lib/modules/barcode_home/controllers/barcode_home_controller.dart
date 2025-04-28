import 'package:get/get.dart';
import 'package:scanner_app/data/models/scan_result.dart';
import 'package:scanner_app/data/services/storage_service.dart';
import 'package:scanner_app/utils/scan_utils.dart';

class BarcodeHomeController extends GetxController {
  final StorageService storageService = Get.find<StorageService>();

  final recentScans = <ScanResult>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecentScans();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh scans when the view is fully loaded or revisited
    loadRecentScans();
  }

Future<void> saveScanAndUpdate(ScanResult newScan) async {
  try {
    // Save the scan result to the database
    await storageService.saveScanResult(newScan);
    print('Scan saved with ID: ${newScan.id}');
    
    // Add a small delay to allow the scan to be saved
    await Future.delayed(Duration(milliseconds: 300));

    // Immediately refresh the recent scans list after saving
    recentScans.insert(0, newScan); // Insert the new scan at the top of the list
    update(); // Notify the UI to refresh
    
  } catch (e) {
    print('Error saving scan: $e');
    ScanUtils.showErrorSnackbar('Error', 'Failed to save the scan');
  }
}

Future<void> loadRecentScans() async {
  isLoading.value = true;
  try {
    final allScans = await storageService.getAllScans();
    recentScans.value = allScans
        .where((scan) => scan != null) // Filter out null scans (optional)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by timestamp

    print('Loaded ${recentScans.length} recent scans: ${recentScans.map((s) => s.id).toList()}');
  } catch (e) {
    print('Error loading recent scans: $e');
    ScanUtils.showErrorSnackbar('Error', 'Failed to load recent scans');
  } finally {
    isLoading.value = false;
  }
}


  Future<void> _navigateAndRefresh(String routeName, {dynamic arguments}) async {
    final result = await Get.toNamed(routeName, arguments: arguments);
    // Always refresh scans after any scan attempt or navigation
    print('$routeName returned result: $result');
    if (result == true) {
      loadRecentScans();
    }
  }

  void goToScan() async {
    await _navigateAndRefresh('/scanner');
  }

  void goToHistory() {
    Get.toNamed('/history');
  }

  void goToScanDetails(String id) async {
    await _navigateAndRefresh('/scan_details', arguments: id);
  }
}


// import 'package:get/get.dart';
// import 'package:scanner_app/data/models/scan_result.dart';
// import 'package:scanner_app/data/services/storage_service.dart';

// class BarcodeHomeController extends GetxController {
//   final StorageService storageService = Get.find<StorageService>();

//   final recentScans = <ScanResult>[].obs;
//   final isLoading = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     loadRecentScans();
//   }

//   @override
//   void onReady() {
//     super.onReady();
//     // Refresh scans when the view is fully loaded or revisited
//     loadRecentScans();
//   }

//   Future<void> loadRecentScans() async {
//     isLoading.value = true;
//     try {
//       final allScans = await storageService.getAllScans();
//       recentScans.value = allScans
//           .where((scan) => scan != null) // Filter out null scans
//           .toList()
//         ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
//       print('Loaded ${recentScans.length} recent scans: ${recentScans.map((s) => s.id).toList()}');
//     } catch (e) {
//       print('Error loading recent scans: $e');
//       Get.snackbar('Error', 'Failed to load recent scans');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void goToScan() async {
//     final result = await Get.toNamed('/scanner');
//     // Always refresh scans after a scan attempt
//     print('Scanner returned result: $result');
//     loadRecentScans();
//   }

//   void goToHistory() {
//     Get.toNamed('/history');
//   }

//   void goToScanDetails(String id) async {
//     final result = await Get.toNamed('/scan_details', arguments: id);
//     // Refresh scans after deletion or navigation back
//     print('Scan details returned result: $result');
//     if (result == true) {
//       loadRecentScans();
//     }
//   }
// }

// // modules/barcode_home/controllers/barcode_home_controller.dart
// import 'package:get/get.dart';
// import 'package:scanner_app/data/models/scan_result.dart';
// import 'package:scanner_app/data/services/storage_service.dart';

// class BarcodeHomeController extends GetxController {
//   final StorageService storageService = Get.find<StorageService>();

//   final recentScans = <ScanResult>[].obs;
//   final isLoading = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     loadRecentScans();
//   }

//   Future<void> loadRecentScans() async {
//     isLoading.value = true;
//     try {
//       final allScans = await storageService.getAllScans();
//       recentScans.value = allScans.take(5).toList();
//       print('Loaded ${recentScans.length} recent scans');
//     } catch (e) {
//       print('Error loading recent scans: $e');
//       Get.snackbar('Error', 'Failed to load recent scans');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void goToScan() {
//     Get.toNamed('/scanner');
//   }

//   void goToHistory() {
//     Get.toNamed('/history');
//   }

//   void goToScanDetails(String id) {
//     Get.toNamed('/scan_details', arguments: id);
//   }
// }
